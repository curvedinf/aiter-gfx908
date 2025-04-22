// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include "gemm_moe_2stages_common.cuh"

using A0DataType = I8;
using B0DataType = I8;
using AccDataType = I32;
using EDataType = B16;
using CDEElementOp = MulABScale;
const bool Nswizzle = false;
const bool PerTensorQuant = false;
CK_MOE_STAGE1_GEMM_DEFINE(256, 32, 128, 256/sizeof(A0DataType), 1, 4, 16)
CK_MOE_STAGE1_GEMM_DEFINE(256, 64, 128, 256/sizeof(A0DataType), 1, 4, 16)
CK_MOE_STAGE1_GEMM_DEFINE(256, 128, 128, 128/sizeof(A0DataType), 2, 2, 16)

