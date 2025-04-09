// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include "moe_ck_gemm_common.cuh"

using A0DataType = F8;
using B0DataType = F8;
using AccDataType = F32;
using EDataType = B16;
using CDEElementOp = TypeCastExpertWeight;
const bool Nswizzle = false;
const bool PerTensorQuant = true;
// CK_MOE_STAGE2_GEMM_DEFINE(16, 128/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(32, 128/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(48, 128/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(64, 128/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(80, 128/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(96, 128/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(112, 128/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(128, 128/sizeof(A0DataType), 2, 2)
// CK_MOE_STAGE2_GEMM_DEFINE(16, 256/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(32, 256/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(48, 256/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(64, 256/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(80, 256/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(96, 256/sizeof(A0DataType), 1, 4)
// CK_MOE_STAGE2_GEMM_DEFINE(112, 256/sizeof(A0DataType), 1, 4)
CK_MOE_STAGE2_GEMM_DEFINE(128, 256/sizeof(A0DataType), 2, 2)