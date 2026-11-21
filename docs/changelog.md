# Changelog

Release history for the OnePlus 15 ColorOS 17 kernel builds (`6.12.69-android16-6`). Per-build zips, checksums, and `build-info.json` provenance files live on the [Releases page](https://github.com/Unnidentified/oplus-sukisu_kernel/releases).

## v2.3.0-r3 - 2026-11-09

- Wired AutoFDO to Google's `android16-6.12` profile (`CLANG_AUTOFDO_PROFILE`).
- Enabled DAMON (`DAMON`, `DAMON_VADDR`, `DAMON_PADDR`, `DAMON_RECLAIM`, `DAMON_LRU_SORT`, `DAMON_SYSFS`).
- Added unconditional `LIST_HARDENED` and `RANDOM_KMALLOC_CACHES`.
- Settled LTO on `none` to match stock GKI (`LTO_NONE`), and fixed `lto_override` handling.
- Updated `susfs-fix-task_mmu-sus-map-gki-6.12.patch` to cover both the top of the `show_smaps_rollup()` loop and the lock-contention retry path.
- Added the five Linux 6.12 CVE backports (`CVE-2026-99103`, `99136`, `99138`, `99139`, `99167`).

## v2.3.0-r2 - 2026-11-08

- Enabled MLGO register allocation (`-mllvm -regalloc-enable-advisor=release`).
- Enabled BORE scheduler and ADIOS I/O scheduler on `OP15-COS17`.
- Fixed zip filenames to always include the release revision suffix.

## v2.3.0-r1 - 2026-11-07

- Initial `OP15-COS17` profile targeting `6.12.69-android16-6` (`kernel/common` at `242e1a07f878`).
- In-tree SukiSU-Ultra (`builtin`) with SUSFS v2.3.0, BBR/BBR3, TTL, IP set, and Unicode bypass.
