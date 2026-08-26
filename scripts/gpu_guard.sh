#!/usr/bin/env bash
# Usage: scripts/gpu_guard.sh [--card N] <command ...>
# Aborts if a vllm server is running, or the target GPU (default: any) shows
# non-trivial use. --card N restricts the use-check to card N so e.g. a
# benchmark can run on card1 while card0 runs a tuner.
set -euo pipefail

CARD=""
if [[ "${1:-}" == "--card" ]]; then
  CARD="$2"
  shift 2
fi

# Match the actual server process ('vllm serve ...'), not any command line
# that merely contains the venv path (e.g. our own /vllm-gfx908/.venv/bin/...).
if pgrep -f 'vllm serve' >/dev/null 2>&1; then
  echo "gpu_guard: vllm server running -- GPUs are in use, aborting." >&2
  pgrep -af 'vllm serve' | head -3 >&2
  exit 1
fi

# Any considered GPU showing non-trivial use -> busy.
use=$(rocm-smi -u --csv 2>/dev/null | awk -F, -v card="$CARD" '
  NR>1 && $NF ~ /[0-9]/ {
    if (card != "" && $1 != "card" card) next
    gsub(/[% ]/,"",$NF); if ($NF+0 > 5) { print $0; exit 1 }
  }') \
  || { echo "gpu_guard: GPU use above 5% -- aborting:" >&2; echo "$use" >&2; exit 1; }

exec "$@"
