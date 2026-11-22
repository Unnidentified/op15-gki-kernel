# Changelog

Updates made across the OnePlus 15 ColorOS 17 (`OP15-COS17`) kernel tree and CI workflows.

## Latest Updates (`v2.3.0-r3`)

- **Compositing, Memory, BORE Sub-Tick & Oryon Compiler Optimisations**:
  - Added `opt-dmabuf-bypass-sysfs-stats-6.12.patch` to eliminate per-buffer `/sys/kernel/dmabuf/buffers/<ino>` kobject allocations, workqueue schedules, and `kernfs_mutex` contention in the hot graphics/camera buffer path while keeping `__tracepoint_android_rvh_dma_buf_stats_teardown` KMI-exported.
  - Added `opt-sched-bore-subtick-base-slice-6.12.patch` so BORE honours its 2 ms `CONFIG_MIN_BASE_SLICE_NS` directly instead of rounding up to the 4 ms 250 Hz tick.
  - Added `opt-mm-mglru-default-min-ttl-6.12.patch` (`lru_gen_min_ttl = HZ` / 1000 ms working-set protection) and `opt-mm-disable-watermark-boost-6.12.patch` (`watermark_boost_factor = 0`).
  - Added `-mno-outline` alongside `-mcpu=oryon-1` for Snapdragon 8 Elite (`wild/sm8850`) to prevent synthetic outliner call hops in hot kernel paths.

## Previous Release (`v2.3.0-r2`)

- **Dual Root Variant Support (SukiSU-Ultra & KernelSU-Next)**:
  - Refactored `build-kernel-release.yml`, `build-kernel/action.yml`, and `scripts/build-info.py` so both `SukiSU-Ultra` (`SUKISU` -> `_SukiSU.zip`) and `KernelSU-Next` (`KSUN` -> `_KSUN.zip`) build in a single matrix run and publish distinct flashable zips and `*_build-info.json` files to the same release.
  - Added local SUSFS `v2.3.0` compatibility patches (`ksun-susfs-v2.3.0-fix-selinux_hide.patch` and `ksun-susfs-v2.3.0-fix-rules.patch`) so `KernelSU-Next` (`dev`) builds cleanly with inline SUSFS hooks on `android16-6.12.69`.
- **NTSync, Droidspaces & Curated `opt` Patches**:
  - Enabled `"ntsync": true`, `"ds": true`, and `"opt": true` in `configs/a16/OP15-COS17.json`.
  - Replaced the upstream `WildKernels` `opt` patch bundle with 3 local patches generated cleanly against `242e1a07f8782987c579929a20a74c0b26e88608` (`opt-alarmtimer-minimize-wakeup-time-6.12.patch`, `opt-pm-wakeup-avoid-extra-s2idle-6.12.patch`, `opt-pci-pme-timeout-4000-6.12.patch`), dropping obsolete/counterproductive upstream patches.
  - Extended `scripts/check-patches.sh` to sparse-checkout and dry-run the local `opt` patches plus `OP_DS` and `OP_NTSYNC` patches, and added `CONFIG_NTSYNC=y`, `CONFIG_SYSVIPC=y`, `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, and `CONFIG_POSIX_MQUEUE=y` assertions to the resolved `.config` audit.
- **KMI Symbol Audit & AutoFDO Override**:
  - Updated non-debug builds in `build-kernel/action.yml` to build `Image modules` so `out/Module.symvers` is always produced and `scripts/kmi-check.py` runs against `gki/aarch64/abi.stg`.
  - Added optional `autofdo_profile_url` and `autofdo_profile_sha256` inputs (and config properties) to override the default pinned AOSP AutoFDO profile.

## Earlier Baseline (`v2.3.0-r1`)

- **Hardware-Verified Baseline**: Recorded verified ColorOS 17 (`CPH2747`) boot on `android16-6.12.69` with SukiSU-Ultra `34692` builtin, SUSFS `v2.3.0`, BORE, ADIOS, DAMON, BBRv3, and `KASAN_HW_TAGS` vendor KMI symbol parity.
- **Calm Release Naming & Provenance v2**: Restored `v<susfs>-r<n>` tags, concise release notes, and `build-info.json` provenance metadata (`SCHEMA_VERSION = 2`).
