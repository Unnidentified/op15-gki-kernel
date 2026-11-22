#!/usr/bin/env bash
# Dry-run the kernel patch sequence for one build profile against its pinned base.
#
# This is the check that catches upstream drift before a 40-minute build does.
# It reproduces, in order, what .github/actions/build-kernel/action.yml applies:
#
#   susfs 50_add_susfs_in_<branch>.patch  ->  task_mmu SUS_MAP fix (only if the
#   main patch rejected)  ->  BORE  ->  ADIOS
#
# and fails if any .rej file is left behind.
#
# Usage: scripts/check-patches.sh configs/a16/OP15-COS17.json
# Env:   WORKDIR (default: mktemp -d), KEEP=1 to keep the work tree.

set -euo pipefail

config="${1:?usage: check-patches.sh <config.json>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$(cd "$(dirname "$config")" && pwd)/$(basename "$config")"

workdir="${WORKDIR:-$(mktemp -d)}"
keep="${KEEP:-0}"
cleanup() { [ "$keep" = "1" ] || rm -rf "$workdir"; }
trap cleanup EXIT

log() { printf '  %s\n' "$*"; }
fail() { printf '::error::%s\n' "$*" >&2; exit 1; }

j() { jq -r "$1" "$config"; }

model=$(j .model)
branch=$(j '.branch // empty')
android=$(j .android_version)
kernel=$(j .kernel_version)
manifest=$(j .manifest)
susfs=$(j '.susfs // false')
bore=$(j '.bore // false')
adios=$(j '.adios // false')
opt=$(j '.opt // false')
ds=$(j '.ds // false')
ntsync=$(j '.ntsync // false')
susfs_pin=$(j '.susfs_hash // empty')
blocked=$(j '.blocked // empty')

echo "== $model ($android-$kernel) =="
[ -n "$blocked" ] && echo "   marked blocked: $blocked"

manifest_path="$repo_root/manifests/$(basename "$(dirname "$config")")/$manifest"
[ -f "$manifest_path" ] || fail "manifest not found: $manifest_path"

read -r kernel_url kernel_ref < <(python3 - "$manifest_path" <<'PY'
import sys, xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
remotes = {r.get("name"): r.get("fetch") for r in root.findall("remote")}

def is_kernel(project):
    name = project.get("name") or ""
    path = project.get("path") or ""
    if path == "kernel_platform/common":
        return True
    if name.startswith("android_kernel_modules"):
        return False
    if name.startswith("android_kernel_"):
        return True
    # fallback: a linkfile that materialises kernel_platform/common
    return any(lf.get("dest") == "kernel_platform/common"
               for lf in project.findall("linkfile"))

for project in root.findall("project"):
    if is_kernel(project):
        fetch = (remotes.get(project.get("remote")) or "").rstrip("/")
        print(fetch + "/" + project.get("name"), project.get("revision"))
        break
PY
)
[ -n "${kernel_url:-}" ] || fail "no kernel source project in $manifest_path"
log "kernel source: $kernel_url @ $kernel_ref"

# A pinned SHA has to exist in the repository it names. This dry-run only
# fetches the kernel source project, so a bad pin on any other project is
# invisible here and surfaces as a 404 in the build's repo sync instead. That
# is exactly how a1608e09 - valid in android_kernel_common_oneplus_sm8850 but
# not in android_kernel_modules_and_devicetree_oneplus_sm8850 - got through CI
# and failed the build.
check_pinned_revisions() {
  python3 - "$manifest_path" <<'PY'
import sys, xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
remotes = {r.get("name"): r.get("fetch") for r in root.findall("remote")}
for p in root.findall("project"):
    rev = p.get("revision") or ""
    if len(rev) != 40 or any(c not in "0123456789abcdef" for c in rev):
        continue
    fetch = (remotes.get(p.get("remote")) or "").rstrip("/")
    # Only GitHub serves /archive/<sha>.tar.gz predictably; other remotes are
    # left to the build.
    if "github.com" not in fetch:
        continue
    print(f"{fetch}/{p.get('name')}/archive/{rev}.tar.gz")
PY
}

while read -r url; do
  [ -n "$url" ] || continue
  # HEAD, not GET. The archive is a few hundred MB, so a GET hits --max-time,
  # and curl then prints the 200 it already received while exiting non-zero.
  # That made every pin look broken.
  code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 30 --head "$url" 2>/dev/null)
  rc=$?
  [ "$rc" -eq 0 ] || code=000
  if [ "$code" != "200" ]; then
    # One retry: a transient 5xx should not fail the gate.
    sleep 2
    code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 30 --head "$url" 2>/dev/null)
    rc=$?
    [ "$rc" -eq 0 ] || code=000
  fi
  [ "$code" = "200" ] || fail "pinned revision does not resolve (HTTP $code): $url"
  log "pinned revision ok: $(basename "$(dirname "$(dirname "$url")")") @ $(basename "$url" .tar.gz)"
done < <(check_pinned_revisions)

patches_dir="$repo_root/.github/actions/build-kernel/patches"
susfs_branch="gki-${android}-${kernel}"

# Collect every path the patches touch so the sparse checkout stays small.
paths_file="$workdir/paths.txt"
: > "$paths_file"
add_patch_paths() {
  [ -f "$1" ] || return 0
  grep '^diff --git' "$1" | awk '{print $3}' | sed 's|^a/||' >> "$paths_file"
}

susfs_patch=""
if [ "$susfs" = "true" ]; then
  # Mirrors the androidXX_susfs_branch_or_commit input defaults in
  # build-kernel-release.yml. Keep the two in sync.
  case "${android}-${kernel}" in
    android16-6.12) default_susfs_ref="c6788e2a21dc717beb7dd3a36b729b58bc909927" ;;
    *)              default_susfs_ref="" ;;
  esac
  susfs_ref="${susfs_pin:-${default_susfs_ref:-$susfs_branch}}"
  log "susfs @ $susfs_ref"
  git init -q "$workdir/susfs"
  git -C "$workdir/susfs" remote add origin https://gitlab.com/simonpunk/susfs4ksu.git
  git -C "$workdir/susfs" fetch -q --depth 1 origin "$susfs_ref" \
    || fail "cannot fetch susfs ref $susfs_ref"
  git -C "$workdir/susfs" checkout -q FETCH_HEAD
  susfs_patch="$workdir/susfs/kernel_patches/50_add_susfs_in_${susfs_branch}.patch"
  [ -f "$susfs_patch" ] || fail "susfs patch missing: 50_add_susfs_in_${susfs_branch}.patch"
  add_patch_paths "$susfs_patch"
fi

[ "$bore" = "true" ] && add_patch_paths "$patches_dir/bore_6.12.patch"
[ "$adios" = "true" ] && add_patch_paths "$patches_dir/adios_ioscheduler_6.12.patch"
if [ "$opt" = "true" ] && [ "$kernel" = "6.12" ]; then
  for p in \
    "$patches_dir/opt-alarmtimer-minimize-wakeup-time-6.12.patch" \
    "$patches_dir/opt-pm-wakeup-avoid-extra-s2idle-6.12.patch" \
    "$patches_dir/opt-pci-pme-timeout-4000-6.12.patch" \
    "$patches_dir/opt-dmabuf-bypass-sysfs-stats-6.12.patch" \
    "$patches_dir/opt-mm-mglru-default-min-ttl-6.12.patch" \
    "$patches_dir/opt-mm-disable-watermark-boost-6.12.patch" \
    "$patches_dir/opt-sched-disable-boot-schedstats-6.12.patch" \
    "$patches_dir/opt-sched-bore-subtick-base-slice-6.12.patch"; do
    add_patch_paths "$p"
  done
fi
add_patch_paths "$patches_dir/susfs-fix-task_mmu-sus-map-gki-6.12.patch"
if [ "$kernel" = "6.12" ]; then
  add_patch_paths "$patches_dir/sukisu-lsm-count-6.12.patch"
fi

# The CVE backports are applied on every 6.12 profile, so their paths are
# always needed when the base is 6.12.
if [ "$kernel" = "6.12" ]; then
  for p in "$patches_dir"/cve-*-6.12.patch; do
    add_patch_paths "$p"
  done
fi

wild_patches_dir="$workdir/kernel_patches"
if [ "$ds" = "true" ] || [ "$ntsync" = "true" ]; then
  log "WildKernels/kernel_patches (sparse: common/droidspaces, common/ntsync)"
  git init -q "$wild_patches_dir"
  git -C "$wild_patches_dir" remote add origin https://github.com/WildKernels/kernel_patches.git
  git -C "$wild_patches_dir" config core.sparseCheckout true
  git -C "$wild_patches_dir" sparse-checkout init --no-cone
  printf '%s\n' 'common/droidspaces/*' 'common/ntsync/*' \
    | git -C "$wild_patches_dir" sparse-checkout set --stdin
  git -C "$wild_patches_dir" fetch -q --depth 1 --filter=blob:none origin main \
    || fail "cannot fetch WildKernels/kernel_patches"
  git -C "$wild_patches_dir" checkout -q FETCH_HEAD
fi

ds_sysvipc_patch=""
ds_ghost_patch=""
if [ "$ds" = "true" ]; then
  case "$branch" in
    wild/sm8850|wild/sm8845)
      ds_sysvipc_patch="$wild_patches_dir/common/droidspaces/fix_sysvipc_kabi_a16-6.12.patch"
      ;;
    wild/sm8550|wild/sm7550)
      ds_sysvipc_patch="$wild_patches_dir/common/droidspaces/fix_sysvipc_kabi_1_2_3.patch"
      ;;
    *)
      ds_sysvipc_patch="$wild_patches_dir/common/droidspaces/fix_sysvipc_kabi_6_7_8.patch"
      ;;
  esac
  ds_ghost_patch="$wild_patches_dir/common/droidspaces/0001-Return-ghost-task-if-task-is-null-and-is-requested-b.patch"
  add_patch_paths "$ds_sysvipc_patch"
  add_patch_paths "$ds_ghost_patch"
fi

ntsync_compat_patch=""
ntsync_base_patch=""
if [ "$ntsync" = "true" ]; then
  gki_key="${android}-${kernel}"
  ntsync_compat_patch="$wild_patches_dir/common/ntsync/ntsync_compat_${gki_key}.patch"
  ntsync_base_patch="$wild_patches_dir/common/ntsync/ntsync_base.patch"
  add_patch_paths "$ntsync_compat_patch"
  add_patch_paths "$ntsync_base_patch"
  printf '%s\n' 'include/uapi/linux/ntsync.h' 'drivers/misc/ntsync.c' >> "$paths_file"
fi

sort -u "$paths_file" -o "$paths_file"

# Sparse clone of the pinned base. blob:none keeps it to a few MB.
kernel_dir="$workdir/kernel"
git init -q "$kernel_dir"
git -C "$kernel_dir" remote add origin "$kernel_url"
git -C "$kernel_dir" config core.sparseCheckout true
git -C "$kernel_dir" sparse-checkout init --no-cone
git -C "$kernel_dir" sparse-checkout set --stdin < "$paths_file"
git -C "$kernel_dir" fetch -q --depth 1 --filter=blob:none origin "$kernel_ref" \
  || fail "cannot fetch $kernel_url @ $kernel_ref"
git -C "$kernel_dir" checkout -q FETCH_HEAD
log "checked out $(wc -l < "$paths_file") path(s)"

apply() {
  # apply <label> <patch> [extra patch args...]
  local label="$1" patch_file="$2"
  shift 2
  [ -f "$patch_file" ] || fail "$label: patch file missing: $patch_file"
  local rc=0
  ( cd "$kernel_dir" && patch -p1 --forward "$@" < "$patch_file" ) || rc=$?
  if [ "$rc" -gt 1 ]; then
    fail "$label: patch failed seriously (rc=$rc)"
  fi
  local rejects
  rejects=$(find "$kernel_dir" -name '*.rej' | sort)
  if [ -n "$rejects" ]; then
    # Relative to the work tree: the absolute mktemp path is noise in a log
    # and makes two runs of the same profile look different.
    printf '%s\n' "$rejects" | sed "s|^$kernel_dir/||; s|^|     REJECT: |" >&2
    fail "$label: left rejects"
  fi
  log "$label: clean"
}

if [ "$susfs" = "true" ]; then
  # The main patch rejects two hunks on 6.12.30+ (show_smaps_rollup refactor);
  # rc=1 is tolerated so the adapted fix below can run, matching the build.
  rc=0
  ( cd "$kernel_dir" && patch -p1 --forward < "$susfs_patch" ) || rc=$?
  [ "$rc" -le 1 ] || fail "susfs: patch failed seriously (rc=$rc)"

  if find "$kernel_dir" -name 'task_mmu.c.rej' | grep -q .; then
    log "susfs: task_mmu rejected, applying adapted fix"
    rm -f "$kernel_dir/fs/proc/task_mmu.c.rej"
    apply "susfs task_mmu fix" "$patches_dir/susfs-fix-task_mmu-sus-map-gki-6.12.patch"
  else
    log "susfs: task_mmu applied from the main patch, fix not needed"
  fi

  rejects=$(find "$kernel_dir" -name '*.rej' | sort)
  if [ -n "$rejects" ]; then
    # Relative to the work tree: the absolute mktemp path is noise in a log
    # and makes two runs of the same profile look different.
    printf '%s\n' "$rejects" | sed "s|^$kernel_dir/||; s|^|     REJECT: |" >&2
    fail "susfs: left rejects"
  fi
fi

if [ "$bore" = "true" ]; then
  case "$kernel" in
    6.12)
      # Mirrors the build: normalise any vendor 750000ULL base_slice and 0.75 msec
      # comment to GKI canon before applying with -F0.
      sed -i.bak 's/750000ULL/700000ULL/g; s/0[.]75 msec/0.70 msec/g' \
        "$kernel_dir/kernel/sched/fair.c" 2>/dev/null || true
      rm -f "$kernel_dir/kernel/sched/fair.c.bak"
      apply "BORE" "$patches_dir/bore_6.12.patch" --ignore-whitespace -F0
      # Post-conditions, same as the build.
      for needle in \
        'static const unsigned int nsecs_per_tick' \
        'unsigned int sysctl_sched_min_base_slice' \
        'void sched_update_min_base_slice(void)' \
        'se_bore(curr)->burst_time += delta_exec'; do
        grep -qF "$needle" "$kernel_dir/kernel/sched/fair.c" \
          || fail "BORE: missing '$needle'"
      done
      guard_ctx=$(grep -A2 'sched_burst_parity_threshold < cfs_rq->nr_running' "$kernel_dir/kernel/sched/fair.c" || true)
      case "$guard_ctx" in
        *'return curr;'*) ;;
        *) fail "BORE: parity guard is not in front of return curr" ;;
      esac
      grep -q 'CONFIG_SCHED_BORE' "$kernel_dir/kernel/sched/sched.h" \
        || fail "BORE: kernel/sched/sched.h was not patched"
      ;;
    *) log "BORE: no patch for $kernel, skipped" ;;
  esac
fi

if [ "$adios" = "true" ]; then
  case "$kernel" in
    6.12) apply "ADIOS" "$patches_dir/adios_ioscheduler_6.12.patch" --ignore-whitespace -F3 ;;
    *) log "ADIOS: no patch for $kernel, skipped" ;;
  esac
fi

# Applied unconditionally on 6.12, matching the build. These are security
# fixes, not profile features, so there is no flag to turn them off.
if [ "$kernel" = "6.12" ]; then
  apply "SukiSU LSM slot count" "$patches_dir/sukisu-lsm-count-6.12.patch"
  for p in "$patches_dir"/cve-*-6.12.patch; do
    apply "CVE backport $(basename "$p" .patch)" "$p"
  done
else
  log "CVE backports: no patch for $kernel, skipped"
fi

if [ "$opt" = "true" ]; then
  case "$kernel" in
    6.12)
      for p in \
        "$patches_dir/opt-alarmtimer-minimize-wakeup-time-6.12.patch" \
        "$patches_dir/opt-pm-wakeup-avoid-extra-s2idle-6.12.patch" \
        "$patches_dir/opt-pci-pme-timeout-4000-6.12.patch" \
        "$patches_dir/opt-dmabuf-bypass-sysfs-stats-6.12.patch" \
        "$patches_dir/opt-mm-mglru-default-min-ttl-6.12.patch" \
        "$patches_dir/opt-mm-disable-watermark-boost-6.12.patch" \
        "$patches_dir/opt-sched-disable-boot-schedstats-6.12.patch"; do
        apply "opt $(basename "$p" .patch)" "$p"
      done
      if [ "$bore" = "true" ]; then
        apply "opt opt-sched-bore-subtick-base-slice-6.12" \
          "$patches_dir/opt-sched-bore-subtick-base-slice-6.12.patch"
      fi
      ;;
    *) log "opt: no local patches for $kernel, skipped" ;;
  esac
fi

if [ "$ntsync" = "true" ]; then
  if [ "$android" = "android16" ] && [ "$kernel" = "6.12" ]; then
    rm -f "$kernel_dir/include/uapi/linux/ntsync.h" "$kernel_dir/drivers/misc/ntsync.c"
  fi
  apply "NTSync compat" "$ntsync_compat_patch"
  apply "NTSync base" "$ntsync_base_patch"
fi

if [ "$ds" = "true" ]; then
  apply "Droidspaces SYSVIPC kABI" "$ds_sysvipc_patch"
  apply "Droidspaces ghost task" "$ds_ghost_patch"
fi

# A blocked profile that now applies cleanly means the blocker is gone and the
# field is stale. Say so instead of leaving a working profile switched off.
if [ -n "$blocked" ]; then
  printf '::warning::%s is marked blocked but its patch sequence now applies. Remove the "blocked" field from %s.\n' \
    "$model" "${config#"$repo_root"/}"
fi

echo "== $model: patch sequence applies cleanly =="
