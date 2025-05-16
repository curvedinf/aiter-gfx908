#! /bin/bash

#rm -rf ~/.triton/cache

function benchmark {
  export BLOCK_SIZE_N=$1
  export NUM_WARPS=$2
  export AGGREGATED_LOADS=$3
  echo "BLOCK_SIZE: " $BLOCK_SIZE_N " NUM_WARPS: " $NUM_WARPS "AGGREGATED_LOADS: " $AGGREGATED_LOADS
  for i in seq 2; do
    AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1 python op_benchmarks/triton/bench_gemm_afp4wfp4.py --model llama3-405B --metric bandwidth
  done
}

benchmark 16 1 0
benchmark 16 1 -1

benchmark 32 1 0
benchmark 32 1 -1

benchmark 32 2 0
benchmark 32 2 -1

benchmark 64 2 0
benchmark 64 2 -1

benchmark 64 4 0
benchmark 64 4 -1
