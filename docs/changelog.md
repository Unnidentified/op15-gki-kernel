# Changelog

Dated history of the kernel releases. Each entry names the kernel bases it
covers; per-build detail, zips and checksums live on the matching
[release page](https://github.com/Unnidentified/oplus-sukisu_kernel/releases).

Versions follow the SUSFS version the build carries, with a release revision
suffix: `v<SUSFS>-r<N>`. The revision increments per release of the same SUSFS
version, so two builds of the same kernel base stay distinguishable.

## v2.3.0-r3 - 2026-11-09

Kernel bases: `6.12.69-android16-6` (ColorOS 17) and OnePlus
`sm8850_b_16.0.0_oneplus_15`, 6.12.23 (OxygenOS 16).

- BORE, ADIOS and AutoFDO are now enabled on the OxygenOS 16 profile as well.
  This is the first 6.12.23 build carrying all three.
- AutoFDO wired to Google's `android16-6.12` profile. `gki_defconfig` already
  set `CONFIG_AUTOFDO_CLANG=y`, but without `CLANG_AUTOFDO_PROFILE` it only
  emitted debug info and no profile-guided optimisation.
- DAMON enabled on both profiles.
- Baseline hardening: `LIST_HARDENED` and `RANDOM_KMALLOC_CACHES` on every 6.6+
  profile, with no per-device toggle.
- LTO settled at `none`, matching what GKI ships from android14-6.1 up. The
  `lto_override` path that broke every build is fixed.
- `CC_OPTIMIZE_FOR_PERFORMANCE_O3` is no longer written on kernels that do not
  have it; the symbol was removed in Linux 6.0.
- Matrix generation no longer picks up `configs/schema.json`, which had been
  failing every run within ten seconds.
- `SUS_MAP` scope fix on `fs/proc/task_mmu.c` now covers both the top of the
  do-loop and the contended path.
- 72 profiles are marked `blocked` with the reason recorded. The build matrix
  drops them and lists them in the run summary instead of failing the run.

## v2.3.0-r2 - 2026-11-08

Kernel base: `6.12.69-android16-6` (ColorOS 17).

- MLGO register allocation added to the ColorOS 17 profile.
- BORE and ADIOS added to the ColorOS 17 profile.
- Zips are named with the release revision. `v2.3.0-r1` shipped as
  `..._v2.3.0.zip` because the revision resolved to an empty string on
  non-release builds.

## v2.3.0-r1 - 2026-11-07

Kernel base: `6.12.69-android16-6` (ColorOS 17).

- First ColorOS 17 profile, built from the AOSP GKI base rather than a OnePlus
  tree. KMI `android16-6` generation matches ColorOS 17's stock kernel.
- SukiSU-Ultra 34680 compiled in-tree (`builtin`), with SUSFS v2.3.0.
- BBR, BBR3, TTL, IP set and the Unicode bypass included.

## v2.2.0 - 2026-08-07

Kernel base: OnePlus `sm8850_b_16.0.0_oneplus_15`, 6.12.23 (OxygenOS 16).

- SukiSU-Ultra with SUSFS v2.2.0.
- Droidspaces for portable Linux containers.
- Baseband Guard kept disabled by default, because it breaks EFISP bootloader
  spoofing.
- BBR, TTL and IP set included; NTSync for Windows emulation.
- Fixes for inactive SUSFS mounts.

This is the only release with a recorded hardware test: flashed and booted on
OxygenOS 16, then used as a daily driver. See the
[README](../README.md#tested-on-hardware).

## Upstream sync - 2026-11-04

Forked from [sakfi/OP_KSUN_FS](https://github.com/sakfi/OP_KSUN_FS) and switched
the root solution from KernelSU-Next to SukiSU-Ultra, which carries SUSFS
in-kernel rather than as a userspace extension shim. The upstream hybrid LKM
mode, AnyKernel3.1 packaging and OSS kernel sources were kept.
