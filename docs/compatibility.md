# Compatibility

## OnePlus devices

> [!WARNING]
> Every kernel here is built from [OnePlus official sources](https://github.com/OnePlusOSS/)
> and is expected to work only on stock ROMs.

- Profiles exist for OxygenOS 14, 15 and 16, covering kernel bases 5.10 through
  6.12. The [README](../README.md#supported-devices) lists which devices each
  release line covers.
- Do not flash a zip across a major Android OTA (for example A15 to A16) unless
  it has been confirmed working for that build. The KMI has to match.

## Non-OnePlus devices

> [!WARNING]
> Disable dm-verity and verification with fastboot, or by other means, before
> flashing a OnePlus kernel on a non-OnePlus device.

- If your device is not listed below, pick the profile whose kernel version is
  closest and matches the KMI exactly. The `androidXX-YY.ZZ` part must match;
  the trailing `AAA` must be the same or higher. See the
  [KernelSU KMI guide](https://kernelsu.org/guide/installation.html#kmi).
- The list is community-maintained. Reports of devices that work, or that have
  stopped working, are welcome.

| Device | Working OnePlus kernel | Kernel version |
| --- | --- | --- |
| Poco X7 Pro (worked previously), Realme GT 7 Pro | OnePlus 13, OnePlus Ace 5 Pro | `android15-6.6.89` |
| Realme GT Neo 5 SE, Realme GT Neo 5 | OnePlus 10T, OnePlus 10 Pro, OnePlus Ace 2, OnePlus 11R (partial) | `android12-5.10.226`, `android12-5.10.209` |
| Realme GT 5, Poco F6 Pro | OnePlus 11 | `android13-5.15.167`, `android13-5.15.180` |
| Realme GT Neo 6 SE, Realme GT Neo 6T | OnePlus Nord 4 | `android14-6.1.118` |
| Realme GT 2 Pro | OnePlus 10 Pro | `android12-5.10.226` |
| Poco F8 Ultra | OnePlus 15 | `android16-6.12.23` |
| Xiaomi 12T Pro | OnePlus 10T | `android12-5.10.226`, `android12-5.10.236` |

A device appearing here means someone reported it booting. It does not mean
every subsystem was exercised. Treat it as a starting point, not a guarantee.
