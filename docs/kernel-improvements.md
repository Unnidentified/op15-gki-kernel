# Kernel Improvements (`OP15-COS17` · `android16-6.12.69`)

Every toggle listed here is driven from [`configs/a16/OP15-COS17.json`](../configs/a16/OP15-COS17.json) and applied inside [`.github/actions/build-kernel/action.yml`](../.github/actions/build-kernel/action.yml).

## Compiler & Optimization

| Toggle | Setting | Purpose |
|---|---|---|
| `autofdo` | `true` | Applies AOSP AutoFDO profile (`CONFIG_AUTOFDO_CLANG=y`) for kernel hot-path optimization |
| `mlgo` | `true` | Enables Clang ML-guided inlining/register allocation flags |
| `lto` | `none` | Kept at `none` so AutoFDO builds cleanly on `android16-6.12` |
| `optimize_level` | `O2` (default) | `-O2` (supports `-O3` via workflow input) |

## CPU Scheduler, I/O & Memory

| Toggle | Setting | Purpose |
|---|---|---|
| `bore` | `true` | Burst-Oriented Response Enhancer (`sched_bore=1`) for interactive foreground latency |
| `adios` | `true` | Adaptive Deadline I/O Scheduler (`[adios]` default) |
| `damon` | `true` | Kernel Data Access Monitor (`CONFIG_DAMON*`) for proactive memory reclamation |
| `kasan` | `true` | Keeps `CONFIG_KASAN_HW_TAGS=y` so `kasan_flag_enabled` resolves for stock vendor modules while bootloader sets `kasan=off` |

## Networking, Filesystem & Security

| Toggle | Setting | Purpose |
|---|---|---|
| `bbr` / `bbr3` | `true` / `true` | Enables TCP BBR + BBRv3 congestion control (`CONFIG_TCP_CONG_BBR3`) |
| `ttl` | `true` | Netfilter `TTL` / `HL` mangling targets |
| `ip_set` | `true` | `IP_SET` + IPv6 NAT netfilter support |
| `unicode` | `true` | Upstream case-insensitive / Unicode path handling fixes |
| `bbg` | `false` | Keeps Baseband Guard disabled so EFISP chainloading works |
| Built-in hardening | always on | `CONFIG_LIST_HARDENED=y` plus `CVE-2026-99103`, `99136`, `99138`, `99139`, `99167` backports |

## Verification Gate on Built `Image`

Before creating the AnyKernel3 package, `build-kernel/action.yml` checks the compiled `Image` binary for:

1. Exported symbol string `kasan_flag_enabled` (when `kasan: true`).
2. Builtin KernelSU `LSM hooks initialized.` string (when `ksu_mode: builtin`).
3. `susfs is initialized!` string (when `susfs: true`).
