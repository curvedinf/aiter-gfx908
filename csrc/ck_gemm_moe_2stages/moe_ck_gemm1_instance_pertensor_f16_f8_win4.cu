// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include "gemm_moe_2stages_common.cuh"

using A0DataType = F8;
using B0DataType = I4;
using AccDataType = F32;
using EDataType = F16;
using CDEElementOp = MulABScaleWint4;
const bool Nswizzle = false;
const bool PerTensorQuant = true;
CK_MOE_STAGE1_GEMM_DEFINE(256, 32, 128, 128/sizeof(A0DataType), 1, 4, 32)
CK_MOE_STAGE1_GEMM_DEFINE(256, 64, 128, 128/sizeof(A0DataType), 1, 4, 32)
CK_MOE_STAGE1_GEMM_DEFINE(256, 128, 128, 128/sizeof(A0DataType), 1, 4, 32)