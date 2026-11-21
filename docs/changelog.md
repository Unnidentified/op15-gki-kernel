# Changelog

Updates made across the OnePlus 15 ColorOS 17 (`OP15-COS17`) kernel tree and CI workflows.

## Latest Updates

- **Hardware-Verified Baseline**: Recorded verified ColorOS 17 (`CPH2747`) boot on `android16-6.12.69` with SukiSU-Ultra `34692` builtin, SUSFS `v2.3.0`, BORE, ADIOS, DAMON, BBRv3, and `KASAN_HW_TAGS` vendor KMI symbol parity.
- **Calm Release Naming & Provenance v2**: Kept the clean `v<susfs>-r<n>` tags, `OP15-COS17_android16-6.12.69-SuSFS_<ver>-r<n>.zip` archives, and `OP15-COS17_A16_build-info.json` provenance metadata (`SCHEMA_VERSION = 2`).
- **Workflow Cleanup & Hardening**:
  - Removed unused Telegram, SUSFS update monitor, duplicate patch-sweep, and legacy multi-device cleanup workflows.
  - Added binary `Image` assertions in `build-kernel/action.yml` for `kasan_flag_enabled`, builtin LSM hooks, and SUSFS init strings.
  - Hardened `ci-checks.yml` with `build-info.py` v2 verification, patch header/non-empty checks, `kmi-check.py` syntax checks, and `OP15-COS17.json` policy guards (`kasan=true`, `bbg=false`, pinned `susfs_hash`).
  - Added direct-URL toolchain fallback in `kernel-source-sync/action.yml` when `toolchain-cache` assets are absent, and aligned SUSFS pins across `cache-warmer.yml` and `build-kernel-release.yml`.
- **Documentation**: Rewrote root `README.md`, updated `docs/*`, updated `.github/ISSUE_TEMPLATE/bug_report.yml`, and closed stale issue `#51`.
