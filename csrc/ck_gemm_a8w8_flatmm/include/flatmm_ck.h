#pragma once
// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/extension.h>

torch::Tensor flatmm_ck(
    torch::Tensor &XQ,      // [M, K]
    torch::Tensor &WQ,      // [N, K] -> [N/128, K*128]
    torch::Tensor &x_scale, // [K/128, M]
    torch::Tensor &w_scale, // [K/128, N/128]
    torch::Tensor &out      // Out:[M, N] fp16
);
torch::Tensor flatmm_ck_tune(
    torch::Tensor &XQ,
    torch::Tensor &WQ,
    torch::Tensor &x_scale,
    torch::Tensor &w_scale,
    torch::Tensor &out,
    int kernelId,
    int splitK);
