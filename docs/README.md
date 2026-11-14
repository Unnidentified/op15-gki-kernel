# Repository documentation

Project-owned documentation for the OnePlus GKI kernel builds: build profiles,
compatibility notes, release history, and the reasoning behind the decisions
that shaped them.

## Documentation map

| Path | Purpose |
| --- | --- |
| [`roadmap.md`](roadmap.md) | What shipped, what was investigated and rejected, and what is blocked upstream. |
| [`compatibility.md`](compatibility.md) | Which devices the zips are expected to work on, and the KMI matching rules. |
| [`changelog.md`](changelog.md) | Dated release history, with the kernel bases each release covers. |

## Where the rest lives

| What | Where | Notes |
| --- | --- | --- |
| Build profiles | [`configs/`](../configs) | One JSON file per device, validated against [`configs/schema.json`](../configs/schema.json). |
| Kernel source manifests | [`manifests/`](../manifests) | Repo manifests pinning the OnePlus or AOSP tree each profile builds from. |
| Verification scripts | [`scripts/`](../scripts) | Config validation, patch dry-run, KMI check, build provenance. |
| Build pipeline | [`.github/`](../.github) | Workflows, composite actions, and the patches the build applies. |
| Per-build notes and zips | [Releases](https://github.com/Unnidentified/oplus-sukisu_kernel/releases) | Release notes, `build-info.json`, and sha256 sums for every zip. |

## Conventions

Documentation that belongs to the kernel source tree is not copied here. Files
under paths such as `kernel_platform/common/Documentation/` are part of the
upstream layout and are referenced by kernel tooling and maintainers. This
directory holds documentation owned by this repository and its build process.

A change that alters behaviour should update the document that explains it in
the same pull request. The roadmap entry for a rejected idea is the record of
why it was rejected, so it is worth keeping current rather than letting it
drift.
