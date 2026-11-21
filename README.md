# OnePlus 15 (ColorOS 17) Kernel

Custom `android16-6.12.69` kernel for the OnePlus 15 (`SM8850`) running ColorOS 17, built with SukiSU-Ultra, SUSFS, BORE, ADIOS, DAMON, and BBRv3.

## Included

- [SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra) compiled in-tree (`builtin`, with `lkm` available via workflow dispatch)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) (`v2.3.0`, pinned)
- BORE CPU scheduler, ADIOS I/O scheduler, and DAMON memory reclaim
- Clang `-O2` with AutoFDO and MLGO (`lto: none`)
- BBRv3, TTL/HL target, `IP_SET`, IPv6 NAT, and Unicode filename fixes
- `CONFIG_LIST_HARDENED=y` and 6.12 security backports
- Baseband Guard kept off (`bbg: false`) for EFISP compatibility

Built and booted on ColorOS 17 (`OP15-COS17`). See [docs](docs/README.md) for configuration notes and the patch list.

## Archive Naming

Release archives encode the build options directly in the filename:

```text
OP15-COS17_SM8850_6.12.69-A16_KSU34692B-SUSFS230_BORE-ADIOS-DAMON-KASANhw_CL20-O2-LTOn-AFDO-MLGO_BBR3-TTL-IPSET-UNI-NoBBG_r1.zip
```

- `OP15-COS17_SM8850_6.12.69-A16`: profile, SoC, kernel version, OS target
- `KSU<ver>B|L-SUSFS<ver>`: SukiSU-Ultra version/mode (`B` builtin, `L` LKM) and SUSFS version
- `BORE-ADIOS-DAMON-KASANhw`: active schedulers and vendor KMI ABI parity (`NoKASAN` if off)
- `CL<ver>-O2|O3-LTOn|LTOt|LTOf-AFDO-MLGO`: toolchain, optimization, LTO, AutoFDO, MLGO
- `BBR3|BBR-TTL-IPSET-UNI-NoBBG|BBG`: networking toggles and Baseband Guard state
- `_r<n>`: release revision matching the tag (`_b<run>` on manual artifact-only builds)

Each release zip ships alongside a matching `_build-info.json` and SHA-256 checksums.

## Flashing

Back up stock `boot` and `init_boot` before flashing. If you are moving from an LKM-patched `init_boot` to a `builtin` build, restore stock `init_boot` first so LKM and in-tree hooks do not conflict.

1. Check the zip against the published SHA-256 (`sha256sum <file>.zip`).
2. Flash the zip with Kernel Flasher or Horizon Kernel Flasher.
3. Install the [SukiSU-Ultra Manager](https://github.com/SukiSU-Ultra/SukiSU-Ultra/releases).

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
