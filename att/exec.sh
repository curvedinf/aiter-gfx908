#!/usr/bin/bash

rocprof --stats python ../op_tests/op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 256 106496 16384 --metric bandwidth

