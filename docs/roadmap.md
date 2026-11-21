# Roadmap

What shipped for OnePlus 15 ColorOS 17 (`OP15-COS17`), what was investigated and rejected, and what remains open.

This kernel targets a **daily-driver phone** rather than synthetic benchmarks, so changes that trade correctness, debuggability, or battery life for benchmark numbers stay out.

---

## Shipped

| Area | What |
|---|---|
| Base profile | `OP15-COS17` pinned to AOSP `kernel/common` `6.12.69` (`242e1a07f878`) matching ColorOS 17 stock KMI |
| Correctness | `SUS_MAP` `task_mmu.c` scope fix (loop head and lock-retry path), KASAN off by default |
| Features | SukiSU-Ultra (`builtin`), SUSFS v2.3.0, BORE, ADIOS, DAMON, AutoFDO, MLGO, BBR/BBRv3 |
| Security | Five 6.12 CVE backports, `LIST_HARDENED`, `RANDOM_KMALLOC_CACHES` |
| Gates & provenance | Config schema validation, `check-patches.sh` dry-run, KMI/ABI check, `build-info.json`, actionlint + shellcheck |

---

## Decided against

| Candidate | Why not |
|---|---|
| **LTO `thin` / `full` on 6.12** | Google's Kleaf defaults disable LTO on android14-6.1+ (`LTO_NONE`). `lto_override` exists for explicit one-off tests |
| **`-O3` default** | `CC_OPTIMIZE_FOR_PERFORMANCE_O3` was removed in Linux 6.0; blind `-O3` grows text and hurts i-cache while AutoFDO already guides inlining |
| **`CONFIG_INIT_ON_FREE_DEFAULT_ON`** | `INIT_ON_ALLOC_DEFAULT_ON` covers the main info-leak path; zeroing again on free doubles the cost |
| **`CONFIG_ARM64_MTE`** | Requires compatible userspace; enabling it unconditionally causes crashes |
| **16 KB page size** | Breaks existing binaries compiled for 4 KB pages |
| **`CONFIG_SCHEDSTATS=n`** | Disables `sched_stat_*` tracepoints needed by Perfetto |
| **`ZSWAP`** | No swap device configured |
| **`NO_HZ_FULL` / `CPU_ISOLATION`** | Unused without `isolcpus` on Android |
| **`DEFERRED_STRUCT_PAGE_INIT`** | Extra init pass aimed at servers with large memory |
| **`PAGE_REPORTING`** | Hypervisor guest feature |
| **`THP_ALWAYS`** | `THP_MADVISE` + `THP_SWAP` avoids memory and latency overhead |
| **`HZ_300`** | Stock GKI uses `HZ=250` |
| **`PREEMPT_DYNAMIC`** | Adds static-call overhead on every preempt point |
| **`SCHED_THERMAL_PRESSURE`** | Removed in Linux 6.12 |

---

## Open items

### `CONFIG_SCHED_CLUSTER`

Asymmetric cluster balancing fixes landed upstream in later Linux kernels, after 6.12. Enabling `CONFIG_SCHED_CLUSTER` without that six-patch series leaves equal-capacity clusters unbalanced. Revisit only if moving to a base that carries the series.

### `scx_lavd` and active DAMON policies

- `scx_lavd` requires a userspace daemon (`scx_loader` / `scx_lavd`) and replaces BORE.
- DAMON mechanisms are compiled in and dormant (`kdamond` stays stopped unless userspace configures a policy). Needs device-specific tuning before enabling a boot policy.
