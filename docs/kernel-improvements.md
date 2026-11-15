# Kernel improvements carried over from the reference tree

Comparison of the kernel changes in
[travismills82/oneplus15-sm8850-oos-kernel](https://github.com/travismills82/oneplus15-sm8850-oos-kernel)
against what this repository builds, and a record of what was carried over.

The two repositories are built differently, which limits what can move between
them. The reference vendors a complete kernel tree and edits it in place. This
repository holds no kernel source: it pins upstream trees in `manifests/`,
applies patches from `.github/actions/build-kernel/patches/`, and appends to
`gki_defconfig`. So only changes that can be expressed as a patch or a config
symbol are portable.

## What was compared

| Area | Reference | This repository |
|---|---|---|
| Kernel base | Linux 6.12.117 | 6.12.23 (OnePlus `sm8850_b_16.0.0_oneplus_15`), 6.12.69 (AOSP GKI) |
| Config | `common/arch/arm64/configs/gki_defconfig` | appended to the same file by the build action |
| Patches | none as files; changes are in-tree | 11 patches under `.github/actions/build-kernel/patches/` |
| Drivers | `vendor/` with Qualcomm driver modernization | upstream trees, unmodified |

## Carried over: five CVE backports

The reference documents a backport set in
`docs/security/coloros1700102-five-cve-backports-20261029.md`. All five fixes
plus their workqueue prerequisite are applied here on every 6.12 profile.

| CVE | Upstream commit | Subject |
|---|---|---|
| CVE-2026-99103 | `cf9c8aaea0d47410df8708bec195889f3a85cd3c` | workqueue: fix unbound pool lifetime for pending pwqs |
| CVE-2026-99136 | `148845aa1921d95ef5dc851c76e6a284f6657df6` | dm-crypt: fix a tiny race condition in crypt_dec_pending |
| CVE-2026-99138 | `385e474086c2e7e29e2dded690be40dc273e20ee` | tcp: fix use-after-free in do_tcp_getsockopt(TCP_CC_INFO) |
| CVE-2026-99139 | `5271b79b7ad68dcb222e893773f92bdabf7750f3` | tcp: fix use-after-free in do_tcp_getsockopt(TCP_CONGESTION) |
| CVE-2026-99167 | `7b16eb911091aae237a8673da94e4dfb9cd21d54` | net/sched: fix use-after-free in __tcf_action_put() |

Four apply unmodified to both 6.12.23 and 6.12.69. The workqueue fix is written
against 6.12.117, where the condition is the `is_percpu_pool()` helper added by
`3180ee71b676`. Neither base has that helper, so the patch here keeps the
equivalent `WQ_UNBOUND` test both trees already use. The reordering, which is
the fix, is identical.

They are applied unconditionally rather than behind a profile flag: each is a
use-after-free or a race reachable by a local attacker, so there is no reason
to build a kernel without them.

## Carried over: config symbols

The reference's `gki_defconfig` adds 28 lines over stock AOSP 6.12.69. Most are
features this repository already enables (KernelSU, SUSFS, DAMON, ADIOS, CAKE,
SYSVIPC, POSIX_MQUEUE, USER_NS, DEVTMPFS, NETFILTER_XT_MATCH_ADDRTYPE). Seven
were missing and are now applied:

| Symbol | Why |
|---|---|
| `CONFIG_EROFS_FS_ZIP_ZSTD=y` | Read zstd-compressed EROFS images. Android 16 system partitions use zstd; without this the kernel only mounts lz4-compressed ones. |
| `CONFIG_PSTORE_BLK=m` | Panic and oops records to a block device, so a crash survives the reboot that follows it. |
| `CONFIG_CRYPTO_AES_ARM64_NEON_BLK=m` | AES through NEON for the block modes dm-crypt and fscrypt use. |
| `CONFIG_HARDLOCKUP_DETECTOR=y` | Catch a CPU that stops taking interrupts, which the softlockup detector cannot see. |
| `CONFIG_HARDLOCKUP_DETECTOR_PREFER_BUDDY=y` | Use the buddy detector, which needs no PMU counter. |
| `CONFIG_NINTENDO_FF=y` | Rumble for Switch controllers, alongside the NTSync support this kernel already ships. |
| `CONFIG_WQ_POWER_EFFICIENT_DEFAULT=y` | What OnePlus ships on its own trees. Replicated so the AOSP-based profiles match. |

The reference swaps `CONFIG_SOFTLOCKUP_DETECTOR=y` out for the hardlockup
detector. Both are independent bools that `select LOCKUP_DETECTOR`, so this
repository keeps both rather than losing softlockup detection.

`EROFS_FS_ZIP_ZSTD`, `HARDLOCKUP_DETECTOR_PREFER_BUDDY` and `NINTENDO_FF`
landed in 5.16, so they are skipped on 5.10 and 5.15 rather than written where
`olddefconfig` would drop them.

## Deliberately not carried over

| Change | Why not |
|---|---|
| `CONFIG_SYSTEM_TRUSTED_KEYS="certs/oos17_0_0_102_stock_gki_module_signing.pem"` | Points at a signing certificate that exists only in the reference tree. Copying it would break the build. |
| `CONFIG_GKI_TASK_STRUCT_VENDOR_SIZE_MAX=1280` | An ABI change from the stock 1024. Only needed if vendor modules require the larger struct; the profiles here build and load at 1024. |
| `CONFIG_SND_HDA_CODEC_HDMI=m`, `CONFIG_SND_AUDIO_GRAPH_CARD=m`, `CONFIG_USB_XHCI_PCI_RENESAS=m` | Hardware the reference's own setup needs. A phone has no Intel HDA controller or Renesas xHCI. |
| Linux 6.12.117 | The reference is 94 stable releases ahead of the 6.12.23 base. Moving there is a kernel upgrade, not a patch: `bore_6.12.patch` and `bore-fix-6.12.23.patch` both reject against the newer `kernel/sched/fair.c` and need reworking first. |
| `vendor/` driver modernization | Qualcomm driver source, not expressible as a patch against the upstream trees this repository pins. |

## Verifying

```sh
scripts/check-patches.sh configs/a16/OP15.json
scripts/check-patches.sh configs/a16/OP15-COS17.json
```

Both report `patch sequence applies cleanly` and list each CVE backport as
`clean`. The CI `Patch dry-run` job runs the same script for every profile that
applies a repo-local patch.
