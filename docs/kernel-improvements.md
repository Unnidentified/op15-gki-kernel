# Kernel Improvements (`OP15-COS17` · `android16-6.12.69`)

Every toggle listed here is driven from [`configs/a16/OP15-COS17.json`](../configs/a16/OP15-COS17.json) and applied inside [`.github/actions/build-kernel/action.yml`](../.github/actions/build-kernel/action.yml).

## Root Variants & SUSFS

| Variant / Feature | Setting | Purpose |
|---|---|---|
| `SUKISU` (`_SukiSU.zip`) | `builtin` (`SukiSU-Ultra/SukiSU-Ultra`) | In-tree SukiSU-Ultra with LSM hook registration (`sukisu-lsm-count-6.12.patch`, `sukisu-builtin-lsm-id.patch`) |
| `KSUN` (`_KSUN.zip`) | `dev` (`KernelSU-Next/KernelSU-Next`) | In-tree KernelSU-Next with inline SUSFS hooks (`Inline (SuSFS)`) |
| `susfs` | `true` (`c6788e2a21dc717beb7dd3a36b729b58bc909927`) | SUSFS `v2.3.0` (`SUS_PATH`, `SUS_MOUNT`, `SUS_KSTAT`, `SUS_MAP`, uname/cmdline spoof, open redirect) |

## Compiler & Optimization

| Toggle | Setting | Purpose |
|---|---|---|
| `autofdo` | `true` | Applies AOSP AutoFDO profile (`CONFIG_AUTOFDO_CLANG=y`), with optional `autofdo_profile_url` / `autofdo_profile_sha256` override |
| `mlgo` | `true` | Enables Clang ML-guided register allocation (`-mllvm -regalloc-enable-advisor=release`) |
| `lto` | `none` | Kept at `none` so AutoFDO builds cleanly on `android16-6.12` |
| `optimize_level` | `O2` (default) | `-O2` with `-mcpu=oryon-1 -mno-outline` (supports `-O3` via workflow input) |

## CPU Scheduler, I/O, Memory, Compositing & Power (`opt`)

| Toggle | Setting | Purpose |
|---|---|---|
| `bore` | `true` | Burst-Oriented Response Enhancer (`sched_bore=1`) with sub-tick 2 ms `base_slice_ns` for 120 Hz compositor latency |
| `adios` | `true` | Adaptive Deadline I/O Scheduler (`[adios]` default) |
| `damon` | `true` | Kernel Data Access Monitor (`CONFIG_DAMON*`) for proactive memory reclamation |
| `opt` | `true` | Curated local 6.12.69 patches: `dma-buf` per-buffer sysfs stats bypass (KMI-safe), BORE 2 ms sub-tick base slice, MGLRU 1000 ms default `min_ttl_ms`, `watermark_boost_factor=0`, `alarmtimer` min wakeup timeout, `pm_system_wakeup()` single `s2idle_wake()` transition, PCI `PME_TIMEOUT=4000`, and non-ABI debugfs trim (`PM_ADVANCED_DEBUG=n`, `KUNIT_DEBUGFS=n`) |
| `kasan` | `true` | Keeps `CONFIG_KASAN_HW_TAGS=y` so `kasan_flag_enabled` resolves for stock vendor modules while bootloader sets `kasan=off` |

## Containers, Gaming, Networking, Filesystem & Security

| Toggle | Setting | Purpose |
|---|---|---|
| `ntsync` | `true` | Windows NT synchronization primitive driver (`CONFIG_NTSYNC=y`, `/dev/ntsync`) for Wine/Proton |
| `ds` | `true` | Droidspaces container support (`CONFIG_SYSVIPC=y` kABI-safe union in `task_struct`, `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_POSIX_MQUEUE=y`, and `oplus_bsp_midas` ghost-task guard) |
| `bbr` / `bbr3` | `true` / `true` | Enables TCP BBR + BBRv3 (`CONFIG_TCP_CONG_BBR3=y`) and sets boot defaults to `bbr3` (`CONFIG_DEFAULT_BBR3=y`) + `fq` pacing (`CONFIG_DEFAULT_FQ=y`) |
| `ttl` | `true` | Netfilter `TTL` / `HL` mangling targets |
| `ip_set` | `true` | `IP_SET` + IPv6 NAT netfilter support |
| `unicode` | `true` | Upstream case-insensitive / Unicode path handling fixes |
| `bbg` | `false` | Keeps Baseband Guard disabled so EFISP chainloading works |
| Built-in hardening | always on | `CONFIG_LIST_HARDENED=y` plus `CVE-2026-99103`, `99136`, `99138`, `99139`, `99167` backports |

## Verification Gates (`Image`, `.config`, and KMI / ABI)

1. **Resolved `.config` audit**: Verifies `CONFIG_SCHED_BORE=y`, `CONFIG_MQ_IOSCHED_ADIOS=y`, `CONFIG_DAMON=y`, `CONFIG_AUTOFDO_CLANG=y`, `CONFIG_NTSYNC=y`, `CONFIG_SYSVIPC=y`, `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_POSIX_MQUEUE=y`, `CONFIG_LIST_HARDENED=y`, and `CONFIG_KASAN_HW_TAGS=y` after `olddefconfig`.
2. **Binary `Image` verification**: Asserts `kasan_flag_enabled`, variant-specific builtin root hooks (`LSM hooks initialized.` for SukiSU-Ultra; `welcome to KernelSU version` + `Inline (SuSFS)` for KernelSU-Next), and `susfs is initialized!`.
3. **KMI / ABI check**: Builds `Image modules` so `out/Module.symvers` is always generated and audited against `gki/aarch64/abi.stg` via `scripts/kmi-check.py` (`10,198` ABI symbols, `0` missing, `0` `task_struct` CRC changes with `ds: true` kABI union, and `8` expected `tcp_*` CRC changes from the BBRv3 backport).
