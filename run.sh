#! /bin/bash

rm -rf ~/.triton/cache
cmd=$(rocprof --stats python op_benchmarks/triton/bench_gemm_a8w8_blockscale.py --model all -M 32 --metric time)

grep _gemm_a8w8_blockscale_kernel results.stats.csv | awk -F',' '{print $(NF-1)}'
