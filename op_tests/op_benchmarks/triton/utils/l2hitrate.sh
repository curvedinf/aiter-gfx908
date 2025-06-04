#!/bin/bash

# rocprofv2_cache.sh
# Usage: ./rocprofv2_cache.sh --- <command...> --- <kernel_name>
# Profiles L2 cache hit rates using rocprofv2 with TCC_HIT[0] and TCC_MISS[0]

# Ensure the script is called with "---" at the beginning
if [ "$#" -lt 1 ] || [ "$1" != "---" ]; then
    echo "Usage: $0 --- <command...> --- <kernel_name>"
    exit 1
fi
shift  # Remove the initial "---"

# Collect all arguments for the command until the next "---"
declare -a COMMAND_ARRAY
while [ "$#" -gt 0 ] && [ "$1" != "---" ]; do
    COMMAND_ARRAY+=("$1")
    shift
done

if [ "$#" -eq 0 ]; then
    echo "Error: Missing '---' separator and kernel name."
    echo "Usage: $0 --- <command...> --- <kernel_name>"
    exit 1
fi

# Remove the separator "---"
if [ "$1" = "---" ]; then
    shift
fi

if [ "$#" -lt 1 ]; then
    echo "Error: Missing kernel name."
    echo "Usage: $0 --- <command...> --- <kernel_name>"
    exit 1
fi

KERNEL_NAME="$1"
shift

# Define metrics file
METRICS_FILE="cache_metrics.txt"

# Create metrics file only if it doesn't exist
if [ ! -f "$METRICS_FILE" ]; then
    cat << EOF > "$METRICS_FILE"
pmc: TCC_HIT_sum,TCC_MISS_sum
kernel: $KERNEL_NAME
EOF
fi

# Define output directory
OUTPUT_DIR="rocprof_cache_batch"
mkdir -p "$OUTPUT_DIR"
touch "$OUTPUT_DIR/rocprofv2.log"

# Split environment variables and actual command
ENV_VARS=()
CMD=()
parsing_env=true

for arg in "${COMMAND_ARRAY[@]}"; do
    if [[ "$parsing_env" = true && "$arg" == *"="* ]]; then
        ENV_VARS+=("$arg")
    else
        parsing_env=false
        CMD+=("$arg")
    fi
done

# Display what we're running
echo "Profiling kernel $KERNEL_NAME..."
echo "Environment variables: ${ENV_VARS[*]}"
echo "Running command: ${CMD[*]}"

# Export environment variables
for env_var in "${ENV_VARS[@]}"; do
    export "$env_var"
done

# Run rocprofv3 with the command (not the env vars)
rocprofv3 -i "$METRICS_FILE" -d "$OUTPUT_DIR" --kernel-include-regex "$KERNEL_NAME" -- "${CMD[@]}" > "$OUTPUT_DIR/rocprofv2.log" 2>&1

# Find results file
RESULTS_FILE=$(find "$OUTPUT_DIR" -name "*counter_collection.csv" -type f 2>/dev/null | head -n 1)
if [ -z "$RESULTS_FILE" ]; then
    echo "Error: No results CSV found in $OUTPUT_DIR."
    echo "Check $OUTPUT_DIR/rocprofv2.log for errors."
    cat "$OUTPUT_DIR/rocprofv2.log"
else
    echo "Results saved to: $RESULTS_FILE"
fi

# Provide output details
echo "Output directory: $OUTPUT_DIR"
echo "-----------------------"

python print_l2hitrate.py

# Cleanup: Remove all created directories and metrics file
echo "Cleaning up created files and directories..."
rm -rf rocprof_cache_batch
if [ -f "$METRICS_FILE" ]; then
    rm "$METRICS_FILE"
    rm -rf .rocprofv3
    echo "Removed $METRICS_FILE"
fi
echo "Cleanup complete."