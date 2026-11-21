#!/usr/bin/env bash
# Re-apply the SUSFS hunks that reject on android16-6.12 (6.12.69) for context reasons.
#
# Called from the "Apply SUSFS Patches" step in action.yml. It lives in its own
# file because that step's run block must stay under GitHub's 21,000-character
# expression limit.
#
# Env:
#   COMMON_KERNEL_FOLDER  kernel tree root
#   GITHUB_ACTION_PATH    action directory, for the patch files
#
# Runs only when the corresponding hunk actually rejected, so this is a no-op on
# a base where upstream applies cleanly.

set -euo pipefail

# GKI android16-6.12 (6.12.30+) refactored show_smaps_rollup(), so the two
# SUS_MAP hunks for fs/proc/task_mmu.c reject on 6.12.69. Apply the adapted fix
# only when the original hunks actually rejected.
# The replacement carries BOTH checks: one at the top of the do-loop (normal
# path) and one after vma_next() inside the mmap_lock_is_contended block.
if find "$COMMON_KERNEL_FOLDER" -name 'task_mmu.c.rej' -print | grep -q .; then
  task_mmu_fix="${GITHUB_ACTION_PATH}/patches/susfs-fix-task_mmu-sus-map-gki-6.12.patch"
  if [ -f "$task_mmu_fix" ]; then
    echo "Applying adapted SUSFS fix for fs/proc/task_mmu.c (refactored show_smaps_rollup)"
    patch -p1 --forward -d "$COMMON_KERNEL_FOLDER" < "$task_mmu_fix"
    rm -f "$COMMON_KERNEL_FOLDER/fs/proc/task_mmu.c.rej"
  else
    echo "::error::fs/proc/task_mmu.c rejected and no adapted fix exists at $task_mmu_fix"
    exit 1
  fi
fi
