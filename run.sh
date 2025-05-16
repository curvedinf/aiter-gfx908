#! /bin/bash

rm -rf ~/.triton/cache
## normal run

#AMD_INSERT_AMDGCN=/app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/hack_vmcnt.s
#AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 ROCPROF_ATT_LIBRARY_PATH=/app/att-decoder-v3-3.0.0-Linux/opt/rocm/lib rocprofv3 --advanced-thread-trace --att-parse trace -i att.json -d compare_David/aggregate_load -- python op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 16 106496 16384 --metric bandwidth
#AMD_INSERT_TTGIR=/app/aiter/compare_David/aggregate_load/hack0.ttgir AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 ROCPROF_ATT_LIBRARY_PATH=/app/att-decoder-v3-3.0.0-Linux/opt/rocm/lib rocprofv3 --advanced-thread-trace --att-parse trace -i att.json -d compare_David/aggregate_load/att_hack0 --

#AMD_INSERT_TTGIR=/app/aiter/skinny_M128/hack3.ttgir AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 ROCPROF_ATT_LIBRARY_PATH=/app/att-decoder-v3-3.0.0-Linux/opt/rocm/lib rocprofv3 --advanced-thread-trace --att-parse trace -i att.json -d /app/aiter/skinny_M128/att_hack3 -- python op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth
AMD_INSERT_TTGIR=/app/aiter/skinny_M128/hack3.ttgir AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 rocprof --stats python op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth

## att trace
#AMD_INSERT_TTGIR=/app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/hack2.ttgir
#AMD_INSERT_AMDGCN=/app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/hack_vmcnt.s AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 ROCPROF_ATT_LIBRARY_PATH=/app/att-decoder-v3-3.0.0-Linux/opt/rocm/lib rocprofv3 --advanced-thread-trace --att-parse trace -i att.json -d /app/aiter/study_aggregate_load/AL/BM32-BN128-BK512_nS2-nW4/att_hack_asm --  python op_benchmarks/triton/bench_gemm_afp4wfp4.py --model llama3-405B --metric bandwidth
