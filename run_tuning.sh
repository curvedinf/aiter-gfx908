export AMD_SERIALIZE_KERNEL=3

#export TRITON_HIP_USE_ASYNC_COPY=1
#export ASYNC_COPY_BYPASS_PERMUTE=1
#export TRITON_HIP_ASYNC_FAST_SWIZZLE=1
#export TRITON_HIP_ASYNC_COPY_OVERLAP=1

export TRITON_HIP_AGGREGATE_LOAD_FACTOR=2
export BLOCK_SIZE_M=128
export BLOCK_SIZE_N=256
export BLOCK_SIZE_K=256
export WAVES_PER_EU=2
export CACHE=".cg"
export NUM_WARPS=8

for TRITON_HIP_AGGREGATE_LOAD_FACTOR in 0 2 4; do
  for BLOCK_SIZE_M in 128; do
    for BLOCK_SIZE_N in 128 256; do
      for BLOCK_SIZE_K in 128 256 512; do
        for CACHE in ".cg" ".ca" ".cv"; do
          for NUM_WARPS in 2 4 8; do
            echo -n "AGGREGATE_FACTOR: $TRITON_HIP_AGGREGATE_LOAD_FACTOR  BLOCK_M: $BLOCK_SIZE_M  BLOCK_N: $BLOCK_SIZE_N  BLOCK_K: $BLOCK_SIZE_K  WAVES_PER_EU: $WAVES_PER_EU  NUM_WARPS: $NUM_WARPS  CACHE: $CACHE $ "
            rocprof --stats python ./op_tests/op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth &> /dev/null
            cat /aiter/results.stats.csv | grep _gemm_afp4_wfp4_kernel.kd | cut -d, -f 4
            echo
          done
        done
      done
    done
  done
done
