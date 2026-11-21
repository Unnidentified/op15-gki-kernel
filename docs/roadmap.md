# Roadmap

Completed baseline and next improvements for the `OP15-COS17` (`android16-6.12.69`) SukiSU-Ultra & KernelSU-Next + SUSFS `v2.3.0` builds.

## Verified Baseline

- [x] Export `kasan_flag_enabled` (`CONFIG_KASAN_HW_TAGS=y`) to match stock ColorOS 17 vendor modules.
- [x] Expand `MAX_LSM_COUNT` in GKI 6.12 so in-tree `ksu` registers cleanly (`capability,landlock,safesetid,selinux,bpf,ksu`).
- [x] Pin `OP15-COS17.json` SUSFS commit (`c6788e2a21dc717beb7dd3a36b729b58bc909927`), AutoFDO, MLGO, BORE, ADIOS, DAMON, BBRv3, `opt: true`, `ds: true`, `ntsync: true`, and `bbg: false`.
- [x] Add first-class dual variant build & release support for **SukiSU-Ultra** (`_SukiSU.zip`) and **KernelSU-Next** (`_KSUN.zip`) with per-variant `build-info.json` and KMI reports.
- [x] Replace the upstream `WildKernels` `opt` patch bundle with 3 curated, `android16-6.12.69`-verified local power/wakeup patches (`alarmtimer`, `pm_system_wakeup`, PCI `PME_TIMEOUT`).
- [x] Enable NTSync (`CONFIG_NTSYNC=y`) and Droidspaces (`CONFIG_SYSVIPC=y`, `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_POSIX_MQUEUE=y`) with resolved `.config` audits and CI dry-run coverage in `scripts/check-patches.sh`.
- [x] Build `Image modules` on normal builds so `modpost` always emits `out/Module.symvers` and `scripts/kmi-check.py` compares every build against `gki/aarch64/abi.stg`.
- [x] Support optional custom AutoFDO profile (`autofdo_profile_url` / `autofdo_profile_sha256` and config-level `autofdo_url` / `autofdo_sha256`) while defaulting to the pinned AOSP profile.

## Near-Term Next Steps

- [ ] Collect a device-specific ETM AutoFDO profile on ColorOS 17 `6.12.69` and pass it via `autofdo_profile_url` / `autofdo_profile_sha256` to measure gains against the bundled AOSP profile.
- [x] Baselined `out/Module.symvers` vs. `gki/aarch64/abi.stg` on `6.12.69` (`10,198` ABI symbols, `0` missing, `0` `task_struct` changes with `ds: true`, and `8` intentional `tcp_*` CRC shifts from `bbr3: true`: `tcp_done`, `tcp_poll`, `tcp_read_done`, `tcp_read_sock`, `tcp_recv_skb`, `tcp_sendmsg_locked`, `tcp_sock_set_cork`, `tcp_sock_set_nodelay`). Keep `kmi_check_strict: false` by default while `bbr3: true` is active.

## Evaluated & Rejected

- `kasan: false`: breaks `kasan_flag_enabled` resolution required by stock ColorOS 17 `vendor_boot` / `vendor_dlkm` modules.
- `bbg: true`: breaks EFISP bootloader-spoof chainloading on OnePlus 15.
- ThinLTO with AutoFDO on GKI 6.12: `lto: none` remains in `OP15-COS17.json` because enabling LTO conflicts with the current AutoFDO setup on this tree.
- Upstream `opt` filler patches (`increase_sk_mem_packets`, `mem_opt_prefetch`, `reduce_cache_pressure`, `reduce_gc_thread_sleep_time`, `f2fs_reduce_congestion`, `f2fs_enlarge_min_fsync_blocks`, `adjust_cpu_scan_order`): dropped due to 6.12.69 removal of `SK_WMEM_DEFAULT`, Oryon hardware prefetcher conflicts, or userspace sysctl duplication.
