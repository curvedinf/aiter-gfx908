#!/usr/bin/bash

rm -rf ~/.triton/cache

ROCPROF_ATT_LIBRARY_PATH=~/system/att-decoder-v3-3.0.0-Linux/opt/rocm/lib \
  TRITON_ALWAYS_COMPILE=1 \
  AMD_SERIALIZE_KERNEL=3 \
  TRITON_HIP_USE_ASYNC_COPY=1 \
  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 \
  TRITON_HIP_ASYNC_FAST_SWIZZLE=1 \
  rocprofv3 \
  -d skinny_256_2 \
  -i att.json \
  --advanced-thread-trace --att-parse trace \
  -- \
  ./exec.sh

