// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

#include "grouped_gemm_common.cuh"
#include "grouped_gemm_lookup.h"
#include <cmath>
#include "py_itfs_common.h"

using RowwiseKernel = std::function<
    torch::Tensor(torch::Tensor &, torch::Tensor &,
                  torch::Tensor &, torch::Tensor &,
                  torch::Tensor &, std::optional<torch::Tensor>)>;

// Define a custom hash function for std::tuple<int, int, int>
struct IntTupleHash
{
  size_t operator()(const std::tuple<int, int, int> &t) const
  {
    auto hash1 = std::hash<int>{}(std::get<0>(t));
    auto hash2 = std::hash<int>{}(std::get<1>(t));
    auto hash3 = std::hash<int>{}(std::get<2>(t));
    return hash1 ^ hash2 ^ hash3;
  }
};

// For certain high priority shapes, we directly use the best kernel rather
// than use heuristics.
using RowwiseKernelMap = std::unordered_map<
    std::tuple<int, int, int>,
    RowwiseKernel,
    IntTupleHash>;

template <typename ABDataType, typename DDataType, typename EDataType>
RowwiseKernel rowwise_heuristic_dispatch(int M, int N, int K)
{
  // Apply shape heuristics to find a suitable kernel implementation.
  return grouped_flatmm<ABDataType, ABDataType, DDataType, EDataType, EDataType, EDataType, EDataType, 256, 128, 128, 128, 16, 16, 32, 1, 4, 1, 1>(
    at::cuda::getCurrentCUDAStream().stream(),
    M,
    N,
    K
  );
}

// Helper function to return the next largest power of 2
static constexpr int nextPow2(unsigned int num)
{
  if (num <= 1)
    return 1;
  return 1 << (CHAR_BIT * sizeof(num) - __builtin_clz(num - 1));
}

template <typename ABDataType, typename DDataType, typename EDataType>
RowwiseKernel rowwise_dispatch(int M, int N, int K)
{
  // For a given shape, either find the best kernel via lookup or heuristic.
  // For many small M shapes, we bucket them to the next largest kernel.
  // This is fine since kernels are padded anyway.

  static const auto lookup = []
  {
    return RowwiseKernelMap{GENERATE_LOOKUP_TABLE(ABDataType, DDataType, EDataType)};
  }();

  // First check if this shape(M,N,K) is available in the direct lookup.
  auto it = lookup.find({M, N, K});
  // If we found an optimal kernel, use it.
  if (it != lookup.end())
  {
    return it->second;
  }

  int padded_m = M;
  if (M > 1 && M <= 16)
  {
    padded_m = 16;
  }
  else if (M <= 16384)
  {
    padded_m = nextPow2(M);
  }
  else if (M <= 20480)
  {
    padded_m = 20480;
  }
  // Second check if this shape(padded_m,N,K) is available in the direct lookup.
  it = lookup.find({padded_m, N, K});
  // If we found an optimal kernel, use it.
  if (it != lookup.end())
  {
    return it->second;
  }
  // Otherwise, use heuristics.
  return rowwise_heuristic_dispatch<ABDataType, DDataType, EDataType>(M, N, K);
}

torch::Tensor m_grouped_gemm(
    torch::Tensor &XQ,
    torch::Tensor &WQ,
    torch::Tensor &x_scale,
    torch::Tensor &w_scale,
    torch::Tensor &Y,
    torch::Tensor &group_layout)
{
  TORCH_CHECK((XQ.dtype() == at::ScalarType::Char || XQ.dtype() == torch_fp8) &&
                  XQ.dtype() == WQ.dtype(),
              "Weights and activations should both be int8/fp8!");
  TORCH_CHECK(x_scale.dtype() == w_scale.dtype(),
              "Scales should have the same dtype!");
  if (bias != std::nullopt)
    TORCH_CHECK(bias.value().dtype() == Y.dtype(),
                "Out amd bias should have the same dtype!");

  int M = XQ.size(0);
  int N = WQ.size(0);
  int K = XQ.size(1);
  int KBatch = std::pow(2, splitK);

  rowwise_dispatch<F16, F32, F16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
  

//   if (XQ.dtype() == at::ScalarType::Char)
//   {
//     if (x_scale.dtype() == at::ScalarType::Float && Y.dtype() == at::ScalarType::Half)
//     {
//       rowwise_dispatch<I8, F32, F16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (x_scale.dtype() == at::ScalarType::Float && Y.dtype() == at::ScalarType::BFloat16)
//     {
//       rowwise_dispatch<I8, F32, B16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (Y.dtype() == at::ScalarType::Half)
//     {
//       rowwise_dispatch<I8, F16, F16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (Y.dtype() == at::ScalarType::BFloat16)
//     {
//       rowwise_dispatch<I8, B16, B16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else
//     {
//       TORCH_CHECK(false, "Unsupported scales/output dtype!");
//     }
//   }
//   else
//   {
//     if (x_scale.dtype() == at::ScalarType::Float && Y.dtype() == at::ScalarType::Half)
//     {
//       rowwise_dispatch<F8, F32, F16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (x_scale.dtype() == at::ScalarType::Float && Y.dtype() == at::ScalarType::BFloat16)
//     {
//       rowwise_dispatch<F8, F32, B16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (Y.dtype() == at::ScalarType::Half)
//     {
//       rowwise_dispatch<F8, F16, F16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else if (Y.dtype() == at::ScalarType::BFloat16)
//     {
//       rowwise_dispatch<F8, B16, B16>(M, N, K)(XQ, WQ, x_scale, w_scale, Y, bias, KBatch);
//     }
//     else
//     {
//       TORCH_CHECK(false, "Unsupported scales/output dtype!");
//     }
//   }
  return Y;
}
