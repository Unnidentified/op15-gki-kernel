# Roadmap

Next improvements after verifying the `OP15-COS17` (`android16-6.12.69`) SukiSU-Ultra + SUSFS `v2.3.0` build on hardware.

## Verified Baseline

- [x] Export `kasan_flag_enabled` (`CONFIG_KASAN_HW_TAGS=y`) to match stock ColorOS 17 vendor modules.
- [x] Expand `MAX_LSM_COUNT` in GKI 6.12 so in-tree `ksu` registers cleanly (`capability,landlock,safesetid,selinux,bpf,ksu`).
- [x] Pin `OP15-COS17.json` SUSFS commit (`c6788e2a21dc717beb7dd3a36b729b58bc909927`), SukiSU-Ultra builtin mode, AutoFDO, MLGO, BORE, ADIOS, DAMON, BBRv3, and `bbg: false`.
- [x] Add binary `Image` checks in CI for `kasan_flag_enabled`, builtin LSM hooks, and SUSFS init strings before packaging AnyKernel3 zips.
- [x] Enforce `OP15-COS17` policy invariants, patch hygiene, and `build-info.py` v2 checks in `ci-checks.yml`.

## Near-Term Next Steps

- [ ] Collect a device-specific AutoFDO profile on ColorOS 17 `6.12.69` to measure gains vs. the bundled AOSP profile.
- [ ] Evaluate enabling `kmi_check_strict: true` once `Module.symvers` vs. `abi.stg` baseline noise is baselined on a clean `6.12.69` run.
- [ ] Run periodic workflow cleanup tests via `cache-warmer.yml` and `mirror-toolchains.yml` after SUSFS bumps.

## Evaluated & Rejected

- `kasan: false`: breaks `kasan_flag_enabled` resolution required by stock ColorOS 17 `vendor_boot` / `vendor_dlkm` modules.
- `bbg: true`: breaks EFISP bootloader-spoof chainloading on OnePlus 15.
- ThinLTO with AutoFDO on GKI 6.12: `lto: none` remains in `OP15-COS17.json` because enabling LTO conflicts with the current AutoFDO setup on this tree.
- `RANDOM_KMALLOC_CACHES` (`slab_caches`): deferred to avoid destabilizing vendor module expectations without dedicated stress testing.
