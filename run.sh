#!/usr/bin/bash

rm -rf ~/.triton/cache/

TRITON_ALWAYS_COMPILE=1 \
  python op_tests/op_benchmarks/triton/bench_gemm_a16w16.py --shape 8192 8192 8192

