// SPDX-License-Identifier: MIT
// Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

#include <torch/python.h>
#include <c10/cuda/CUDAGuard.h>
#include <ck_tile/core.hpp>
#include <ck_tile/host.hpp>

// =====================================================================================================================
// Definitions and helper structures
//

template <int32_t kSizeD_,
          int32_t kSizeDV_,
          int32_t kBlockM_,
          int32_t kBlockN_,
          int32_t kNumWarps_>
struct FlashMlaKernelTrait
{
    static constexpr int32_t kSizeD                  = kSizeD_;    // hidden dimension size of query and key
    static constexpr int32_t kSizeDV                 = kSizeDV_;   // hidden dimension size of value
    static constexpr int32_t kNumWarps               = kNumWarps_;
    static constexpr int32_t kNumThreads             = kNumWarps * warpSize;
    static constexpr int32_t kNumWarpsSoftmax        = 4;
    static constexpr int32_t kNumThreadsSoftmax      = kNumWarpsSoftmax * warpSize;
    static constexpr int32_t kBlockM                 = kBlockM_;
    static constexpr int32_t kBlockN                 = kBlockN_;
    static constexpr int32_t kFixedOverheadNumBlocks = 5;
    static constexpr int32_t kMaxBatchSize           = 4096;

    static_assert(kSizeD % 64 == 0);
    static_assert(kSizeDV % 64 == 0);
    static_assert(kSizeD >= kSizeDV);
};

using FlashMlaKernelTraitsInstance = FlashMlaKernelTrait<576, 512, 64, 16, 4>;

union TileSchedulerMetaData
{
    struct Core
    {
        int32_t begin_batch_idx;
        int32_t begin_seqlen_idx;
        int32_t end_batch_idx;
        int32_t end_seqlen_idx;
        int32_t begin_n_split_idx;
    };
    uint32_t data[8];
};
constexpr size_t TileSchedulerMetaDataSizeInDw = sizeof(TileSchedulerMetaData) / sizeof(int32_t);

struct FlashMlaFwdParams
{
    int32_t* __restrict__ p_cu_seqlens_k;
    int32_t* __restrict__ p_block_table;
    int32_t* __restrict__ p_tile_scheduler_metadata;
    int32_t* __restrict__ p_num_splits;
    
    void* __restrict__ p_query;
    void* __restrict__ p_key;
    void* __restrict__ p_value;
    void* __restrict__ p_output;
    void* __restrict__ p_softmax_lse;
    void* __restrict__ p_softmax_lseaccum;
    void* __restrict__ p_output_accum;

    int32_t size_b;
    int32_t size_s;
    int32_t size_h;
    int32_t hq_hk_ratio;
    int32_t num_groups;
    int32_t num_cu_parts;
    int64_t block_table_batch_stride;
    int32_t page_block_size;
    float   scale_softmax;
    float   scale_softmax_log2;
    bool    is_causal;

    // Use int64_t if there is int32 overflow case. For now, just use int32 to save sgpr and prevent using
    // spill table.
    using index_t = int32_t;

    index_t stride_b_q;     // stride in batch of query
    index_t stride_s_q;     //    ... in sequence ...
    index_t stride_h_q;     //    ... in head ...
    index_t stride_b_k;     // stride in batch of key
    index_t stride_s_k;     //    ... in sequence ...
    index_t stride_h_k;     //    ... in head ...
    index_t stride_b_v;     // stride in batch of value
    index_t stride_s_v;     //    ... in sequence ...
    index_t stride_h_v;     //    ... in head ...
    index_t stride_b_o;     // stride in batch of output
    index_t stride_s_o;     //    ... in sequence ...
    index_t stride_h_o;     //    ... in head ...
};

// =====================================================================================================================
// Kernel Entries
//

template <typename Traits>
__global__ void kn_get_mla_metadata(
    int32_t*       p_tile_scheduler_metadata,
    int32_t*       p_num_splits,
    const int32_t* p_seqlens_k,
    const int32_t  batch_size,
    const int32_t  num_cu_parts)
{
    __shared__ int lds_num_blocks[Traits::kMaxBatchSize];
    __shared__ int lds_num_splits[Traits::kMaxBatchSize];

    int32_t sum_blocks = 0;
    for (int32_t i = threadIdx.x; i < batch_size; i += warpSize)
    {
        const int32_t num_blocks = ck_tile::integer_divide_ceil(p_seqlens_k[i], Traits::kBlockN);
        sum_blocks += num_blocks;
        lds_num_blocks[i] = num_blocks;
    }

    for (int32_t offset = 32; offset > 0; offset >>= 1)
    {
        sum_blocks += __shfl_xor(sum_blocks, offset);
    }

    sum_blocks += batch_size * Traits::kFixedOverheadNumBlocks;

    if (threadIdx.x == 0)
    {
        // expected payload handled by each cu part.
        const int32_t payload = ck_tile::integer_divide_ceil(sum_blocks, num_cu_parts) +
                                Traits::kFixedOverheadNumBlocks;

        int32_t curr_batch = 0;         // batch ID of the batch which is under review
        int32_t curr_block = 0;         // #blocks handled by previous cu part(s)
        int32_t curr_n_split_idx = 0;   // #cu parts used to handle current batch
        int32_t cum_num_splits = 0;

        lds_num_splits[0] = 0;

        for (int32_t i = 0; i < num_cu_parts; ++i)
        {
            TileSchedulerMetaData::Core metadata;
            metadata.begin_batch_idx   = curr_batch;
            metadata.begin_seqlen_idx  = curr_block * Traits::kBlockN;
            metadata.begin_n_split_idx = curr_n_split_idx;

            int remain_payload = payload;
            while (curr_batch < batch_size)
            {
                const int32_t num_blocks = lds_num_blocks[curr_batch];
                const int32_t curr_remain_blocks = num_blocks - curr_block;

                // If current cu part is able to handle this batch of seqences
                if (remain_payload >= (curr_remain_blocks + Traits::kFixedOverheadNumBlocks))
                {
                    cum_num_splits += (curr_n_split_idx + 1);
                    lds_num_splits[curr_batch + 1] = cum_num_splits;
                    remain_payload -= (curr_remain_blocks + Traits::kFixedOverheadNumBlocks);
                    ++curr_batch;
                    curr_block = 0;
                    curr_n_split_idx = 0;
                }
                else
                {
                    if (remain_payload > Traits::kFixedOverheadNumBlocks)
                    {
                        curr_block += (remain_payload - Traits::kFixedOverheadNumBlocks);
                        ++curr_n_split_idx;
                    }
                    break;
                }
            }

            metadata.end_batch_idx  = curr_block > 0 ? curr_batch : (curr_batch - 1);
            metadata.end_seqlen_idx = curr_block > 0 ? curr_block * Traits::kBlockN : p_seqlens_k[curr_batch - 1];
            *reinterpret_cast<TileSchedulerMetaData::Core*>(
                p_tile_scheduler_metadata + i * TileSchedulerMetaDataSizeInDw) = metadata;
        }
    }

    for (int32_t i = threadIdx.x; i <= batch_size; i += warpSize)
    {
        p_num_splits[i] = lds_num_splits[i];
    }
}

template <typename Traits, typename scalar_t>
__global__ void kn_fmla_fwd_splictkv_combine(
    const FlashMlaFwdParams params)
{

}

// =====================================================================================================================
// Dispatches
//

template <typename Traits>
void dispatch_get_mla_metadata(
    int32_t*       p_tile_scheduler_metadata,
    int32_t*       p_num_splits,
    const int32_t* p_cache_seqlens,
    const int32_t  batch_size,
    const int32_t  num_cu_parts)
{
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();

    const uint32_t grid  = 1;
    const uint32_t block = warpSize;

    kn_get_mla_metadata<Traits><<<grid, block, 0, stream>>>(
        p_tile_scheduler_metadata,
        p_num_splits,
        p_cache_seqlens,
        batch_size,
        num_cu_parts);
}

template <typename Traits, typename scalar_t>
void dispatch_fmla_fwd_splictkv_combine(
    const FlashMlaFwdParams& params)
{

}

#define DISPATCH_TYPES(TYPE, NAME, ...)                 \
    switch ((TYPE))                                     \
    {                                                   \
        case at::ScalarType::BFloat16:                  \
        {                                               \
            using scalar_t = at::BFloat16;              \
            __VA_ARGS__;                                \
            break;                                      \
        }                                               \
        case at::ScalarType::Half:                      \
        {                                               \
            using scalar_t = at::Half;                  \
            __VA_ARGS__;                                \
            break;                                      \
        }                                               \
        default:                                        \
            TORCH_CHECK(false, NAME " does't support ", \
                        toString((TYPE)), ".");         \
    }

// =====================================================================================================================
// Interfaces
//

std::vector<torch::Tensor> get_mla_metadata(
    const torch::Tensor& cache_seqlens,
    const int32_t        num_heads_per_head_k,
    const int32_t        num_heads_k)
{
    using Traits = FlashMlaKernelTraitsInstance;

    const torch::TensorOptions tensor_options = cache_seqlens.options();
    const int32_t batch_size = cache_seqlens.size(0);
    assert(batch_size <= Traits::kMaxBatchSize);

    hipDevice_t dev;
    hipDeviceProp_t dev_prop;
    ck_tile::hip_check_error(hipGetDevice(&dev));
    ck_tile::hip_check_error(hipGetDeviceProperties(&dev_prop, dev));
    const int32_t cu_count = dev_prop.multiProcessorCount;
    const int32_t cu_parts = cu_count / num_heads_k /
                             ck_tile::integer_divide_ceil(num_heads_per_head_k, Traits::kBlockM);

    auto tile_scheduler_metadata = torch::empty({cu_parts, TileSchedulerMetaDataSizeInDw}, tensor_options);
    auto num_splits = torch::empty({batch_size + 1}, tensor_options);

    dispatch_get_mla_metadata<Traits>(
        tile_scheduler_metadata.data_ptr<int32_t>(),
        num_splits.data_ptr<int32_t>(),
        cache_seqlens.data_ptr<int32_t>(),
        batch_size,
        cu_parts);

    return {tile_scheduler_metadata, num_splits};
}

// std::vector<torch::Tensor> flash_mla_fwd_with_kvcache_impl(
//     const torch::Tensor& query,
//     const torch::Tensor& key_cache,
//     const torch::Tensor& value_cache,
//     const int32_t        head_size_v,
//     const torch::Tensor& cache_seqlens,
//     const torch::Tensor& block_table,
//     const float          softmax_scale,
//     const bool           is_causal,
//     const torch::Tensor& tile_scheduler_metadata,
//     const torch::Tensor& num_splits)
// {
//     using Traits = FlashMlaKernelTraitsInstance;
//
//     FlashMlaFwdParams params = {};
//     
//     DISPATCH_TYPES(
//         query.scalar_type(),
//         "fmla_fwd",
//         [&](){
//             dispatch_fmla_fwd_splictkv_combine<Traits, scalar_t>(params);
//         }(););
// }
