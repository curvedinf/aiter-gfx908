#pragma once
// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
#include <torch/extension.h>

namespace aiter {
namespace torch_itfs {
std::vector<at::Tensor> poyenc_mha_v3_fwd(const at::Tensor& q, // [b, sq, hq, d]
                                          const at::Tensor& k, // [b, sk, hk, d]
                                          const at::Tensor& v, // [b, sk, hk, d_v]
                                          float softmax_scale);
} // namespace torch_itfs
} // namespace aiter
