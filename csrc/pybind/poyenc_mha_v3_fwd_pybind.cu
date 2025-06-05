// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include "rocm_ops.hpp"
#include "torch/poyenc_mha_v3_fwd.h"

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) { POYENC_MHA_V3_FWD_PYBIND; }