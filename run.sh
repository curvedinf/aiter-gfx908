#! /bin/bash

rm -rf ~/.triton/cache
AMD_SERIALIZE_KERNEL=3 TRITON_HIP_USE_ASYNC_COPY=1 python op_benchmarks/triton/bench_gemm_afp4wfp4.py --model llama3-405B --metric bandwidth
