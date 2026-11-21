# OnePlus 15 ColorOS 17 Kernel

Automated GKI kernel builder for the OnePlus 15 (`CPH2747` / `PLK110`) running stock ColorOS 17, built with SukiSU-Ultra and SUSFS.

## Target profile

| Field | Value |
|---|---|
| Profile | [`configs/a16/OP15-COS17.json`](configs/a16/OP15-COS17.json) |
| Manifest | [`manifests/a16/oneplus_15_6.12.69_gki_w.xml`](manifests/a16/oneplus_15_6.12.69_gki_w.xml) |
| Kernel base | AOSP GKI `6.12.69-android16-6` (`242e1a07f878`) |
| Uname suffix | `6-g242e1a07f878-ab15865446-4k` |
| Root | SukiSU-Ultra (`builtin` in-tree) |
| SUSFS | `c6788e2a21dc717beb7dd3a36b729b58bc909927` (v2.3.0) |

## Included features

- **SukiSU-Ultra (`builtin`)**: Compiled in-tree with full SUSFS kernel hooks.
- **SUSFS**: Magic mount, `SUS_PATH`, `SUS_MOUNT`, `SUS_KSTAT`, `SUS_MAP`, uname and cmdline spoofing, and open redirect. On `6.12.69` (`show_smaps_rollup` refactor), two `fs/proc/task_mmu.c` hunks are applied via [`susfs-fix-task_mmu-sus-map-gki-6.12.patch`](.github/actions/build-kernel/patches/susfs-fix-task_mmu-sus-map-gki-6.12.patch).
- **Schedulers & I/O**: BORE (`SCHED_BORE`), ADIOS (`MQ_IOSCHED_ADIOS`), and DAMON (`DAMON_RECLAIM`, `DAMON_LRU_SORT`).
- **Compiler optimizations**: Clang AutoFDO (`android16-6.12` profile verified by SHA256) and MLGO register allocation (`+mlgo`), with LTO `none` matching stock GKI.
- **Security & hardening**: Five Linux 6.12 CVE backports (CVE-2026-99103, CVE-2026-99136, CVE-2026-99138, CVE-2026-99139, CVE-2026-99167), plus `LIST_HARDENED` and KASAN (`KASAN_HW_TAGS`) ABI parity with stock.
- **Network & filesystem**: BBR/BBRv3, TTL target, IP set with `/proc/config.gz` hiding, Unicode bypass fix, and zstd EROFS support.
- **Baseband Guard**: Kept off so EFISP bootloader spoofing continues to work.

## Building

1. Open **Actions -> Build and Release OnePlus 15 (ColorOS 17) Kernel**.
2. Trigger **Run workflow** with `op_model: OP15-COS17`.
3. Download the flashable AnyKernel3 zip and `build-info.json` from the workflow artifacts or release.

### Known-unbuildable profiles

None. Every profile in `configs/` applies cleanly against its pinned base.

## Local checks

```sh
python3 scripts/validate-configs.py
./scripts/check-patches.sh configs/a16/OP15-COS17.json
```

See [`docs/README.md`](docs/README.md) for the changelog, roadmap, and ported improvements.
