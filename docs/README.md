# Repository documentation

Project documentation for the OnePlus 15 (ColorOS 17) GKI kernel builds.

## Documentation map

| Path | Purpose |
| --- | --- |
| [`roadmap.md`](roadmap.md) | Decisions taken, rejected kernel candidates, and open items. |
| [`kernel-improvements.md`](kernel-improvements.md) | CVE backports and defconfig symbols carried from the reference tree. |
| [`changelog.md`](changelog.md) | Release history for ColorOS 17 builds. |

## Repository layout

| What | Where | Notes |
| --- | --- | --- |
| Build profile | [`configs/a16/OP15-COS17.json`](../configs/a16/OP15-COS17.json) | Validated against [`configs/schema.json`](../configs/schema.json). |
| Kernel manifest | [`manifests/a16/oneplus_15_6.12.69_gki_w.xml`](../manifests/a16/oneplus_15_6.12.69_gki_w.xml) | Pins AOSP `kernel/common` at `242e1a07f878` plus prebuilts. |
| Verification scripts | [`scripts/`](../scripts) | Config validation, patch dry-run, KMI check, build provenance. |
| Build pipeline | [`.github/`](../.github) | Workflows, composite build actions, and repo-local patches. |
