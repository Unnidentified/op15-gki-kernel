#!/usr/bin/env bash
# Re-apply the SUSFS hunks that reject on the OnePlus trees for context reasons.
#
# Called from the "Apply SUSFS Patches" step in action.yml. It lives in its own
# file because that step's run block is close to GitHub's 21,000-character
# expression limit: a run block containing ${{ }} is compiled as a single
# expression, and going over the limit fails the whole action with
# "The template is not valid ... Exceeded max expression length 21000".
#
# Env:
#   COMMON_KERNEL_FOLDER  kernel tree root
#   GITHUB_ACTION_PATH    action directory, for the patch files
#   KERNEL_VER            kernel version of the profile (5.15, 6.1, 6.12, ...)
#
# Each fixup runs only when the corresponding hunk actually rejected, so this
# is a no-op on a base where upstream applies cleanly.

set -euo pipefail

# GKI android16-6.12 (6.12.30+) refactored show_smaps_rollup(), so the two
# SUS_MAP hunks for fs/proc/task_mmu.c reject on those bases. Apply the
# adapted fix only when the original hunks actually rejected.
# The replacement carries BOTH checks: one at the top of the do-loop
# (normal path) and one after vma_next() inside the mmap_lock_is_contended
# block (lock was dropped and re-acquired). Dropping either one leaves
# SUS_MAP mappings visible in /proc/<pid>/smaps_rollup.
if find "$COMMON_KERNEL_FOLDER" -name 'task_mmu.c.rej' -print | grep -q .; then
  if [ "${KERNEL_VER}" = "5.15" ]; then
    # The OnePlus 5.15 trees already carry both SUS_MAP checks in
    # show_smaps_rollup, so the hunks reject as already applied.
    if grep -qF 'SUSFS_IS_INODE_SUS_MAP' "$COMMON_KERNEL_FOLDER/fs/proc/task_mmu.c"; then
      echo "fs/proc/task_mmu.c already carries the SUS_MAP checks, dropping reject"
      rm -f "$COMMON_KERNEL_FOLDER/fs/proc/task_mmu.c.rej"
    else
      echo "::error::fs/proc/task_mmu.c rejected and the SUS_MAP checks are absent"
      exit 1
    fi
  else
    task_mmu_fix="${GITHUB_ACTION_PATH}/patches/susfs-fix-task_mmu-sus-map-gki-6.12.patch"
    if [ -f "$task_mmu_fix" ]; then
      echo "Applying adapted SUSFS fix for fs/proc/task_mmu.c (refactored show_smaps_rollup)"
      patch -p1 --forward -d "$COMMON_KERNEL_FOLDER" < "$task_mmu_fix"
      rm -f "$COMMON_KERNEL_FOLDER/fs/proc/task_mmu.c.rej"
    fi
  fi
fi

# The fs/namespace.c hunk carries #include <trace/hooks/blk.h> as a
# context line. The OnePlus 6.1 trees ship include/trace/hooks/fs.h
# instead and the 5.15 trees have no include/trace/hooks/ at all, so the
# hunk rejects on both even though the change it makes is unrelated to
# that include. Re-apply it against the vendor context, only when the
# original hunk actually rejected.
if find "$COMMON_KERNEL_FOLDER" -name 'namespace.c.rej' -print | grep -q .; then
  case "${KERNEL_VER}" in
    5.15) namespace_fix="${GITHUB_ACTION_PATH}/patches/susfs-fix-namespace-headers-gki-5.15.patch" ;;
    6.1)  namespace_fix="${GITHUB_ACTION_PATH}/patches/susfs-fix-namespace-headers-gki-6.1.patch" ;;
    *)    namespace_fix="" ;;
  esac
  if [ -n "$namespace_fix" ] && [ -f "$namespace_fix" ]; then
    echo "Applying adapted SUSFS fix for fs/namespace.c (missing trace/hooks/blk.h)"
    patch -p1 --forward -d "$COMMON_KERNEL_FOLDER" < "$namespace_fix"
    rm -f "$COMMON_KERNEL_FOLDER/fs/namespace.c.rej"
  else
    echo "::error::fs/namespace.c rejected and no adapted fix exists for ${KERNEL_VER}"
    exit 1
  fi
fi
