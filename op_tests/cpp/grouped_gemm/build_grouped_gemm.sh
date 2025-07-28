# SPDX-License-Identifier: MIT
# Copyright (C) 2018-2025, Advanced Micro Devices, Inc. All rights reserved.
#!/bin/bash

echo "######## building m grouped flatmm kernel"
python3 compile.py

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TOP_DIR=$(dirname "$SCRIPT_DIR")/../../

echo "######## linking grouped flatmm"
/opt/rocm/bin/hipcc  -I$TOP_DIR/3rdparty/composable_kernel/include \
                     -I$TOP_DIR/3rdparty/composable_kernel/example/ck_tile/19_grouped_flatmm/ \
                     -I$TOP_DIR/csrc/include \
                     -std=c++17 -O3 \
                     -DUSE_ROCM=1 \
                     -Wno-unused-local-typedef -Wno-unused-variable -Wno-unused-parameter \
                     -mllvm -greedy-reverse-local-assignment=1 -mllvm --slp-threshold=-32 -mllvm -enable-noalias-to-md-conversion=0 \
                     -DCK_ENABLE_BF16 -DCK_ENABLE_BF8 -DCK_ENABLE_FP16 -DCK_ENABLE_FP32 \
                     --offload-arch=gfx942 \
                     -L $SCRIPT_DIR -lm_grouped_flatmm \
                     $SCRIPT_DIR/benchmark_m_grouped_flatmm.cpp -o benchmark_m_grouped_flatmm
