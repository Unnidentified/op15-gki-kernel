# OnePlus 15 (ColorOS 17) GKI Kernel

Custom `android16-6.12.69` kernel for the OnePlus 15 (`SM8850`) running ColorOS 17, built with in-tree [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra), pinned [SUSFS](https://gitlab.com/simonpunk/susfs4ksu), BORE CPU scheduling, ADIOS I/O, DAMON memory monitoring, and BBRv3. Every release zip ships a matching `_build-info.json` provenance manifest and SHA-256 checksums.

## Verified Status

| Profile | Hardware | Kernel | Verified State |
|---|---|---|---|
| [`OP15-COS17`](configs/a16/OP15-COS17.json) | OnePlus 15 (`CPH2747`) | `6.12.69-android16-6-g242e1a07f878` | Booted on ColorOS 17: SukiSU-Ultra `34692` builtin (`uid=0`, `u:r:ksu:s0`), SUSFS `v2.3.0`, BORE (`sched_bore=1`), `[adios]`, DAMON sysfs, `reno bbr bbr3 cubic`, 668 loaded vendor modules |

## Included Stack

- **Root**: [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) compiled in-tree (`builtin`, `CONFIG_KSU_SUSFS=y`). LKM packaging remains available via workflow input (`ksu_mode: lkm`).
- **Root hiding**: [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) pinned at `c6788e2a21dc717beb7dd3a36b729b58bc909927` (`v2.3.0`).
- **Schedulers & memory**: [BORE](https://github.com/firelzrd/bore-scheduler) CPU scheduler, ADIOS block I/O scheduler, and DAMON reclaim/monitoring.
- **Compiler & PGO**: AOSP/CLO Clang with `-O2`, thin/none LTO (profile sets `lto: none` so AutoFDO runs on 6.12), AutoFDO profile-guided optimization, and MLGO.
- **Networking & FS**: BBRv3 (`CONFIG_TCP_CONG_BBR3`), `TTL`/`HL` target, `IP_SET` + IPv6 NAT, and case-insensitive Unicode fixes.
- **Security**: `CONFIG_LIST_HARDENED=y` plus five 6.12 backports (`CVE-2026-99103`, `CVE-2026-99136`, `CVE-2026-99138`, `CVE-2026-99139`, `CVE-2026-99167`).
- **Bootloader spoof**: Baseband Guard stays off (`bbg: false`), so [EFISP/bootloader-spoof](https://xdaforums.com/t/efisp-root-gbl-chainload-efisp-chainloader-for-oneplus-15.4786301/) chains work.

## Release & Filename Naming Decoder

Releases and ZIP archives encode the exact build configuration directly in the filename:

```text
Tag:  v6.12.69-OP15-COS17-SUSFS2.3.0-KSUB-r1
ZIP:  OP15-COS17_SM8850_6.12.69-A16_KSU34692B-SUSFS230_BORE-ADIOS-DAMON-KASANhw_CL20-O2-LTOn-AFDO-MLGO_BBR3-TTL-IPSET-UNI-NoBBG_r1.zip
Info: OP15-COS17_SM8850_6.12.69-A16_KSU34692B-SUSFS230_BORE-ADIOS-DAMON-KASANhw_CL20-O2-LTOn-AFDO-MLGO_BBR3-TTL-IPSET-UNI-NoBBG_r1_build-info.json
```

| Segment | Example Token | Meaning |
|---|---|---|
| Target & SoC | `OP15-COS17_SM8850` | Device profile (`OP15-COS17`) and Qualcomm SoC (`SM8850`) |
| Kernel & OS | `6.12.69-A16` | Full GKI kernel version and Android target (`A16`) |
| KSU & Mode | `KSU34692B` / `KSU34692L` | SukiSU-Ultra revision + integration mode (`B` = builtin, `L` = LKM) |
| SUSFS | `SUSFS230` | Compiled SUSFS version (`v2.3.0` -> `230`) |
| Subsystems | `BORE-ADIOS-DAMON-KASANhw` | Active schedulers/MM (`KASANhw` = `KASAN_HW_TAGS` ABI parity, `NoKASAN` = disabled) |
| Toolchain | `CL20-O2-LTOn-AFDO-MLGO` | Clang major (`CL20`), opt level (`O2`/`O3`), LTO (`LTOn`/`LTOt`/`LTOf`), AutoFDO, MLGO |
| Net & Guard | `BBR3-TTL-IPSET-UNI-NoBBG` | TCP congestion control (`BBR3`/`BBR`), netfilter extras, Unicode fix, BBG state (`NoBBG` / `BBG`) |
| Revision | `_r1` / `_b123` | Release revision (`-r1` tag) or CI run fallback (`_b<run_number>`) |

## Key Engineering Fixes for OnePlus 15 ColorOS 17

Two GKI 6.12 constraints broke earlier ColorOS 17 boots on `SM8850`:

1. **Vendor Module `KASAN_HW_TAGS` ABI Parity (`kasan: true`)**: ColorOS 17 stock vendor kernel modules (`vendor_boot` / `vendor_dlkm`) reference `kasan_flag_enabled`. Disabling `CONFIG_KASAN_HW_TAGS` drops that symbol, causing early init module loading to fail and trigger an immediate splash bootloop. Keeping `CONFIG_KASAN_HW_TAGS=y` restores symbol parity while the bootloader keeps `kasan=off` at runtime.
2. **Builtin LSM Hook Registration (`MAX_LSM_COUNT`)**: GKI `android16-6.12` ships `CONFIG_SECURITY` with stock hooks already filling the default 4 static LSM slots (`capability`, `landlock`, `safesetid`, `selinux`, `bpf`). Building SukiSU-Ultra in-tree requires expanding `CONFIG_MAX_LSM_COUNT` so `ksu` registers cleanly into `/sys/kernel/security/lsm`.

## Flashing

> [!IMPORTANT]
> Back up stock `boot` and `init_boot` before flashing. If you are moving from an LKM-patched `init_boot` to this **Builtin** kernel, restore stock `init_boot` (or uninstall LKM in SukiSU Manager) so LKM and builtin hooks do not fight over `boot`.

1. Verify your downloaded ZIP against its published SHA-256 (`sha256sum <file>.zip`).
2. Flash via Kernel Flasher / Horizon Kernel Flasher (or unpack `Image` from the ZIP and repack/flash your `boot` slot for your ColorOS 17 build).
3. Install the [SukiSU-Ultra Manager](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases).

## Repository Layout

| Path | Role |
|---|---|
| [`configs/a16/OP15-COS17.json`](configs/a16/OP15-COS17.json) | Device profile & feature toggles validated against [`configs/schema.json`](configs/schema.json) |
| [`manifests/a16/oneplus_15_6.12.69_gki_w.xml`](manifests/a16/oneplus_15_6.12.69_gki_w.xml) | Pinned GKI `6.12.69` + `SM8850` source/toolchain manifest |
| [`.github/actions/build-kernel/`](.github/actions/build-kernel/action.yml) | Modular kernel build, binary ABI verification, and AnyKernel3 packaging action |
| [`.github/workflows/build-kernel-release.yml`](.github/workflows/build-kernel-release.yml) | Manual dispatch build & GitHub Release workflow |
| [`.github/workflows/ci-checks.yml`](.github/workflows/ci-checks.yml) | PR/push static validation, patch dry-runs, and `checkpatch.pl` |
| [`docs/`](docs/README.md) | Kernel improvement plan, roadmap, and changelog |

## Local Verification

```sh
python3 scripts/validate-configs.py
./scripts/check-patches.sh configs/a16/OP15-COS17.json
python3 -m py_compile scripts/*.py
shellcheck -s bash scripts/*.sh
```
