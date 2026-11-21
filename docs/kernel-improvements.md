# Kernel improvements carried over from the reference tree

Notes on the security backports and kernel config symbols ported from [travismills82/oneplus15-sm8850-oos-kernel](https://github.com/travismills82/oneplus15-sm8850-oos-kernel) onto the pinned AOSP `6.12.69` base (`242e1a07f878`).

## Carried over: five CVE backports

Applied unconditionally during every build:

| CVE | Upstream commit | Subject |
|---|---|---|
| CVE-2026-99103 | `cf9c8aaea0d47410df8708bec195889f3a85cd3c` | workqueue: fix unbound pool lifetime for pending pwqs |
| CVE-2026-99136 | `148845aa1921d95ef5dc851c76e6a284f6657df6` | dm-crypt: fix a tiny race condition in crypt_dec_pending |
| CVE-2026-99138 | `385e474086c2e7e29e2dded690be40dc273e20ee` | tcp: fix use-after-free in do_tcp_getsockopt(TCP_CC_INFO) |
| CVE-2026-99139 | `5271b79b7ad68dcb222e893773f92bdabf7750f3` | tcp: fix use-after-free in do_tcp_getsockopt(TCP_CONGESTION) |
| CVE-2026-99167 | `7b16eb911091aae237a8673da94e4dfb9cd21d54` | net/sched: fix use-after-free in __tcf_action_put() |

Four apply unmodified to `6.12.69`. The workqueue patch keeps the existing `WQ_UNBOUND` check already present in `6.12.69` rather than pulling in `is_percpu_pool()` from later stable kernels, while preserving the exact lifetime fix.

## Carried over: config symbols

Appended to `gki_defconfig` alongside KSU, SUSFS, DAMON, and ADIOS:

| Symbol | Why |
|---|---|
| `CONFIG_EROFS_FS_ZIP_ZSTD=y` | Mount zstd-compressed EROFS system partitions. |
| `CONFIG_PSTORE_BLK=m` | Persist panic and oops logs to block storage across reboots. |
| `CONFIG_CRYPTO_AES_ARM64_NEON_BLK=m` | NEON-accelerated AES block modes for dm-crypt and fscrypt. |
| `CONFIG_HARDLOCKUP_DETECTOR=y` | Detect CPUs that stop taking interrupts. |
| `CONFIG_HARDLOCKUP_DETECTOR_PREFER_BUDDY=y` | Use the buddy hardlockup detector without requiring a PMU counter. |
| `CONFIG_NINTENDO_FF=y` | Switch controller rumble support. |
| `CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y` | Match OnePlus power-efficient workqueue default. |

## Verifying

```sh
./scripts/check-patches.sh configs/a16/OP15-COS17.json
```
