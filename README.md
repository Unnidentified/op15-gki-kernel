# OnePlus 15 (ColorOS 17) Kernel

Custom `android16-6.12.69` kernel for the OnePlus 15 (`SM8850`) running ColorOS 17, built with SukiSU-Ultra and KernelSU-Next variants, SUSFS `v2.3.0`, BORE, ADIOS, DAMON, NTSync, Droidspaces, and BBRv3.

## Included

- [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) (`_SukiSU.zip`) and [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) (`_KSUN.zip`) compiled in-tree (`builtin`, with `lkm` available via workflow dispatch)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) (`v2.3.0`, pinned at `c6788e2a21dc717beb7dd3a36b729b58bc909927`)
- BORE CPU scheduler (2 ms sub-tick base slice), ADIOS I/O scheduler, MGLRU (1000 ms working-set `min_ttl_ms`), and DAMON memory reclaim
- Curated power, memory, and compositing patches (`opt`: `dma-buf` sysfs stats kobject bypass, `watermark_boost_factor=0`, `alarmtimer` min wakeup timeout, `s2idle` redundant wake suppression, PCI `PME_TIMEOUT=4000`)
- NTSync (`CONFIG_NTSYNC=y`) and Droidspaces (`CONFIG_SYSVIPC=y` kABI-safe union, `CONFIG_PID_NS=y`, `CONFIG_USER_NS=y`, `CONFIG_POSIX_MQUEUE=y`, `oplus_bsp_midas` ghost-task guard)
- Clang `-O2 -mcpu=oryon-1 -mno-outline` with AutoFDO (supports custom `kernel.afdo` URL/SHA-256 override) and MLGO (`lto: none`)
- BBRv3, TTL/HL target, `IP_SET`, IPv6 NAT, and Unicode filename fixes
- `CONFIG_LIST_HARDENED=y` and 6.12 security backports
- Baseband Guard kept off (`bbg: false`) for EFISP compatibility

Built and booted on ColorOS 17 (`OP15-COS17`). See [docs](docs/README.md) for configuration notes and the patch list.

## Releases

Each release is tagged by SUSFS version and revision (for example `v2.3.0-r2`) and ships both root variants alongside their provenance records:

- `OP15-COS17_android16-6.12.69-SuSFS_v2.3.0-r2_SukiSU.zip` + `OP15-COS17_A16_SukiSU_build-info.json`
- `OP15-COS17_android16-6.12.69-SuSFS_v2.3.0-r2_KSUN.zip` + `OP15-COS17_A16_KSUN_build-info.json`

## Flashing

Back up stock `boot` and `init_boot` before flashing. If you are moving from an LKM-patched `init_boot` to a `builtin` build, restore stock `init_boot` first so LKM and in-tree hooks do not conflict.

1. Check the zip against the published SHA-256 (`sha256sum <file>.zip`).
2. Flash either the `_SukiSU.zip` or `_KSUN.zip` build with Kernel Flasher or Horizon Kernel Flasher.
3. Install the matching manager APK: [SukiSU-Ultra Manager](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases) or [KernelSU-Next Manager](https://github.com/KernelSU-Next/KernelSU-Next/releases).

## Repository

- [`configs/a16/OP15-COS17.json`](configs/a16/OP15-COS17.json): device profile and feature toggles
- [`manifests/a16/oneplus_15_6.12.69_gki_w.xml`](manifests/a16/oneplus_15_6.12.69_gki_w.xml): pinned GKI 6.12.69 manifest
- [`.github/workflows/`](.github/workflows/build-kernel-release.yml): build, release, cache, and CI check workflows
- [`docs/`](docs/README.md): improvement notes, changelog, and roadmap

Local checks:

```sh
python3 scripts/validate-configs.py
./scripts/check-patches.sh configs/a16/OP15-COS17.json
python3 -m py_compile scripts/*.py
```
