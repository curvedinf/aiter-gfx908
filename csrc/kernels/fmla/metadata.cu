// SPDX-License-Identifier: MIT
// Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.

#include <torch/python.h>
#include <c10/cuda/CUDAGuard.h>
#include "aiter_hip_common.h"
#include "dispatch_utils.h"

__global__ void kn_get_mla_metadata_v0(
    int32_t*       p_num_kv_splits,
    int32_t*       p_max_num_splits,
    const int32_t* p_seqlens,
    int32_t        batch_size,
    int32_t        num_heads_per_head_k,
    int32_t        num_heads_k)
{
    constexpr int32_t kMaxSplits = 16;

    if (threadIdx.x == 0)
    {
        p_num_kv_splits[0] = 0;
        p_max_num_splits[0] = kMaxSplits;
    }

    int32_t base_split = 0;
    int32_t curr_seqlen_idx = threadIdx.x;

    while (curr_seqlen_idx < batch_size)
    {
        const int32_t seqlen = p_seqlens[curr_seqlen_idx];

        p_num_kv_splits[curr_seqlen_idx + 1] = 233;

        curr_seqlen_idx += blockDim.x;
    }
}

//
// Get per batch kv split count for ASM MLA without persistent thread
// group support.
//
// Returns
//   [0] num_kv_splits: (batch_size + 1), dtype torch.int32.
//   [1] max_num_splits: (1), dtype torch.int32.
//
std::vector<torch::Tensor> get_mla_metadata_v0(
    const torch::Tensor& seqlens,               // [batch size + 1]
    const int32_t        num_heads_per_head_k,
    const int32_t        num_heads_k)
{
    TORCH_CHECK(seqlens.stride(0) == 1, "seqlens should be continuous!");
    TORCH_CHECK(seqlens.scalar_type() == at::ScalarType::Int, "seqlens's element type should be int!");

    hipDevice_t dev;
    hipDeviceProp_t dev_prop;
    HIP_CALL(hipGetDevice(&dev));
    HIP_CALL(hipGetDeviceProperties(&dev_prop, dev));

    const int32_t batch_size = seqlens.size(0);

    // declare outputs
    auto num_kv_splits = torch::empty({batch_size + 1}, seqlens.options());
    auto max_num_splits = torch::empty({1}, seqlens.options());

    // launch kernel
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
    const dim3 grid = dim3(1, 1, 1);
    const int32_t num_thr = dev_prop.warpSize; // only use 1 warp for simplicity
    kn_get_mla_metadata_v0<<<grid, num_thr, 0, stream>>>(
        num_kv_splits.data_ptr<int32_t>(),
        max_num_splits.data_ptr<int32_t>(),
        seqlens.data_ptr<int32_t>(),
        batch_size,
        num_heads_per_head_k,
        num_heads_k);

    return {num_kv_splits, max_num_splits};
}