# Documentation

Notes behind the `OP15-COS17` (`android16-6.12.69`) kernel build, CI gates, and hardware verification.

- [Kernel improvements](kernel-improvements.md): Upstream patches and compiler options applied at build time, plus rejected/skipped options and their reasons.
- [Roadmap](roadmap.md): Remaining build, CI, and hardware testing milestones.
- [Changelog](changelog.md): Summary of repository updates by area.

## Repo Layout

- [`configs/a16/OP15-COS17.json`](../configs/a16/OP15-COS17.json): Active device profile validated against [`configs/schema.json`](../configs/schema.json).
- [`manifests/a16/`](../manifests/a16/oneplus_15_6.12.69_gki_w.xml): Pinned GKI 6.12.69 and SM8850 kernel manifest.
- [`scripts/`](../scripts/): Local/CI validation (`validate-configs.py`, `check-patches.sh`, `sweep-patches.sh`, `build-info.py`, `kmi-check.py`).
- [`.github/workflows/`](../.github/workflows/): `build-kernel-release.yml`, `ci-checks.yml`, `cache-warmer.yml`, and `mirror-toolchains.yml`.
