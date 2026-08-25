#!/usr/bin/env bash
# Abort unless all MI100s are idle and no vllm process is running.
# Usage: scripts/gpu_guard.sh <command ...>
# The dev stack serves from ~/aiter via PYTHONPATH; nothing in this worktree
# may compete with it for GPUs.
set -euo pipefail

# Match the actual server process ('vllm serve ...'), not any command line
# that merely contains the venv path (e.g. our own /vllm-gfx908/.venv/bin/...).
if pgrep -f 'vllm serve' >/dev/null 2>&1; then
  echo "gpu_guard: vllm server running -- GPUs are in use, aborting." >&2
  pgrep -af 'vllm serve' | head -3 >&2
  exit 1
fi

# Any GPU showing non-trivial use -> busy.
use=$(rocm-smi -u --csv 2>/dev/null | awk -F, '
  NR>1 && $NF ~ /[0-9]/ { gsub(/[% ]/,"",$NF); if ($NF+0 > 5) { print $0; exit 1 } }') \
  || { echo "gpu_guard: GPU use above 5% -- aborting:" >&2; echo "$use" >&2; exit 1; }

exec "$@"
