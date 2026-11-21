# Changelog

Updates made across the OnePlus 15 ColorOS 17 (`OP15-COS17`) kernel tree and CI workflows.

## Latest Release Overhaul

- **Hardware-Verified Baseline**: Recorded verified ColorOS 17 (`CPH2747`) boot on `android16-6.12.69` with SukiSU-Ultra `34692` builtin, SUSFS `v2.3.0`, BORE, ADIOS, DAMON, BBRv3, and `KASAN_HW_TAGS` vendor KMI symbol parity.
- **Feature-Encoded Naming & Provenance**: Updated ZIP, tag, and `build-info.json` naming (`SCHEMA_VERSION = 2`) to encode SoC, kernel, KSU mode/revision, SUSFS version, scheduler/MM flags, compiler flags, network stack, and BBG state directly in the artifact name and release notes.
- **Workflow Cleanup & Hardening**:
  - Removed unused Telegram notification, SUSFS check, patch-sweep duplicate, and legacy multi-device cleanup workflows.
  - Hardened `build-kernel/action.yml` with binary `Image` assertions for `kasan_flag_enabled`, builtin LSM hooks, and SUSFS init strings.
  - Hardened `ci-checks.yml` with `build-info.py` v2 verification, patch header/non-empty checks, `kmi-check.py` syntax checks, and `OP15-COS17.json` policy guards (`kasan=true`, `bbg=false`, pinned `susfs_hash`).
  - Added direct-URL toolchain download fallback in `kernel-source-sync/action.yml` when `toolchain-cache` assets are absent, plus `actions/download-artifact@v8` and matching SUSFS pins across `cache-warmer.yml` and `build-kernel-release.yml`.
- **Documentation**: Rewrote root `README.md`, updated `docs/*`, updated `.github/ISSUE_TEMPLATE/bug_report.yml`, and closed stale issue `#51`.
