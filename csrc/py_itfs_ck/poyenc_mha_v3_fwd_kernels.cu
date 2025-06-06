#include "mha_common.h"
#include "py_itfs_common.h"
#include <ATen/cuda/CUDAContext.h>
#include <torch/all.h>

#include "fmha_fwd.hpp"
#include "mask.hpp"

namespace aiter {
namespace torch_itfs {

struct host_args
{
    ck_tile::index_t batch;
    ck_tile::index_t seqlen_q;
    ck_tile::index_t seqlen_k;
    ck_tile::index_t hdim_q;
    ck_tile::index_t hdim_v;
    ck_tile::index_t nhead_q;
    ck_tile::index_t nhead_k;

    float scale_s;

    const void* q_ptr;
    ck_tile::index_t stride_q;
    ck_tile::index_t nhead_stride_q;
    ck_tile::index_t batch_stride_q;

    const void* k_ptr;
    ck_tile::index_t stride_k;
    ck_tile::index_t nhead_stride_k;
    ck_tile::index_t batch_stride_k;

    const void* v_ptr;
    ck_tile::index_t stride_v;
    ck_tile::index_t nhead_stride_v;
    ck_tile::index_t batch_stride_v;

    void* o_ptr;
    ck_tile::index_t stride_o;
    ck_tile::index_t nhead_stride_o;
    ck_tile::index_t batch_stride_o;
};

//////////////////////////////////////////////////////////////////////////////////////
struct FmhaFwdBf16
{
};

template <typename DataType>
struct FmhaFwdTypeConfig;

template <>
struct FmhaFwdTypeConfig<FmhaFwdBf16>
{
    using QDataType             = ck_tile::bf16_t;
    using KDataType             = ck_tile::bf16_t;
    using VDataType             = ck_tile::bf16_t;
    using BiasDataType          = ck_tile::bf16_t;
    using RandValOutputDataType = uint8_t;
    using LSEDataType           = float; // data type for lse(logsumexp L_j = max_j + log(l_j))
    using SaccDataType          = float; // data type for first gemm accumulation
    using SMPLComputeDataType   = float; // data type for reduction, softmax
    using PDataType             = ck_tile::bf16_t; // data type for A matrix of second gemm
    using OaccDataType          = float;           // data type for second gemm accumulation
    using ODataType             = ck_tile::bf16_t;
};

using fmha_dtype_0 = FmhaFwdBf16;

using fmha_block_tile_0 = ck_tile::sequence<128, 128, 32, 128, 32, 128>;

using fmha_shape_0 = ck_tile::TileFmhaShape<fmha_block_tile_0,
                                            ck_tile::sequence<4, 1, 1>,
                                            ck_tile::sequence<32, 32, 16>,
                                            ck_tile::sequence<4, 1, 1>,
                                            ck_tile::sequence<32, 32, 16>,
                                            true>;

using fmha_trait_0 = ck_tile::TileFmhaTraits<true,
                                             true,
                                             true,
                                             true,
                                             false,
                                             ck_tile::BlockAttentionBiasEnum::NO_BIAS,
                                             false,
                                             false,
                                             false,
                                             false,
                                             -1,
                                             false>;

using fmha_variant_0 =
    ck_tile::ComposedAttention<false * ck_tile::LOGITS_SOFT_CAP, CK_TILE_FMHA_FWD_FAST_EXP2>;

using fmha_mask_0 = ck_tile::SimplifiedGenericAttentionMask<false>;

using fmha_pipeline_problem_0 = ck_tile::BlockFmhaPipelineProblem<
    typename FmhaFwdTypeConfig<fmha_dtype_0>::QDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::KDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::VDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::SaccDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::SMPLComputeDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::BiasDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::RandValOutputDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::LSEDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::PDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::OaccDataType,
    typename FmhaFwdTypeConfig<fmha_dtype_0>::ODataType,
    fmha_shape_0,
    false,
    fmha_variant_0,
    fmha_mask_0,
    fmha_trait_0>;

using fmha_pipeline_0 = ck_tile::BlockFmhaPipelineQRKSVSAsync<fmha_pipeline_problem_0>;

using fmha_epilogue_0 = ck_tile::Default2DEpilogue<
    ck_tile::Default2DEpilogueProblem<typename FmhaFwdTypeConfig<FmhaFwdBf16>::OaccDataType,
                                      typename FmhaFwdTypeConfig<FmhaFwdBf16>::ODataType,
                                      true,
                                      true>>;

using fmha_kernel_0 = ck_tile::FmhaFwdKernel<fmha_pipeline_0, fmha_epilogue_0>;
//////////////////////////////////////////////////////////////////////////////////////

std::vector<at::Tensor> poyenc_mha_v3_fwd(const at::Tensor& q, // [b, sq, hq, d]
                                          const at::Tensor& k, // [b, sk, hk, d]
                                          const at::Tensor& v, // [b, sk, hk, d_v]
                                          float softmax_scale)
{
    auto q_dtype = q.dtype();
    TORCH_CHECK(q_dtype == torch::kFloat16 || q_dtype == torch::kBFloat16,
                "FlashAttention only support fp16 and bf16 data type");

    TORCH_CHECK(k.dtype() == q_dtype, "query and key must have the same dtype");
    TORCH_CHECK(v.dtype() == q_dtype, "query and value must have the same dtype");

    std::string q_dtype_str = q_dtype == torch::kFloat16 ? "fp16" : "bf16";

    CHECK_DEVICE(q);
    CHECK_DEVICE(k);
    CHECK_DEVICE(v);

    TORCH_CHECK(q.stride(-1) == 1, "Input tensor must have contiguous last dimension");
    TORCH_CHECK(k.stride(-1) == 1, "Input tensor must have contiguous last dimension");
    TORCH_CHECK(v.stride(-1) == 1, "Input tensor must have contiguous last dimension");

    const auto sizes = q.sizes();

    const int batch_size  = sizes[0];
    int seqlen_q          = sizes[1];
    int num_heads         = sizes[2];
    const int head_size_q = sizes[3];
    const int head_size_v = v.sizes()[3];
    const int seqlen_k    = k.size(1);
    const int num_heads_k = k.size(2);
    TORCH_CHECK(batch_size > 0, "batch size must be positive");
    TORCH_CHECK(head_size_q <= 256, "CK only supports head dimension at most 256");
    TORCH_CHECK(head_size_v <= 256, "CK only supports head dimension at most 256");
    TORCH_CHECK(head_size_q % 8 == 0,
                "query, key, value, and out_ must have a head_size_q that is a multiple of 8");
    TORCH_CHECK(head_size_v % 8 == 0,
                "query, key, value, and out_ must have a head_size_q that is a multiple of 8");
    TORCH_CHECK(num_heads % num_heads_k == 0,
                "Number of heads in key/value must divide number of heads in query");

    CHECK_SHAPE(q, batch_size, seqlen_q, num_heads, head_size_q);
    CHECK_SHAPE(k, batch_size, seqlen_k, num_heads_k, head_size_q);
    CHECK_SHAPE(v, batch_size, seqlen_k, num_heads_k, head_size_v);

    host_args args;

    args.batch    = batch_size;
    args.seqlen_q = seqlen_q;
    args.seqlen_k = seqlen_k;
    args.hdim_q   = head_size_q;
    args.hdim_v   = head_size_v;
    args.nhead_q  = num_heads;
    args.nhead_k  = num_heads_k;

    args.scale_s = softmax_scale;

    args.q_ptr          = q.data_ptr();
    args.batch_stride_q = q.stride(0);
    args.stride_q       = q.stride(1);
    args.nhead_stride_q = q.stride(2);

    args.k_ptr          = k.data_ptr();
    args.batch_stride_k = k.stride(0);
    args.stride_k       = k.stride(1);
    args.nhead_stride_k = k.stride(2);

    args.v_ptr          = v.data_ptr();
    args.batch_stride_v = v.stride(0);
    args.stride_v       = v.stride(1);
    args.nhead_stride_v = v.stride(2);

    auto opts = q.options();
    at::Tensor out =
        torch::empty({batch_size, seqlen_q, num_heads, head_size_v}, opts.dtype(q_dtype));

    args.o_ptr          = out.data_ptr();
    args.batch_stride_o = out.stride(0);
    args.stride_o       = out.stride(1);
    args.nhead_stride_o = out.stride(2);

    auto kargs = fmha_kernel_0::MakeKargsImpl(args.q_ptr,
                                              args.k_ptr,
                                              args.v_ptr,
                                              nullptr, // bias_ptr
                                              nullptr, // rand_val_ptr
                                              nullptr, // lse_ptr
                                              args.o_ptr,
                                              args.seqlen_q,
                                              args.seqlen_k,
                                              args.hdim_q,
                                              args.hdim_v,
                                              args.nhead_q,
                                              args.nhead_q / args.nhead_k,
                                              args.scale_s,
                                              1.0f, // scale_p
                                              1.0f, // scale_o
                                              0.0f, // logits_soft_cap
                                              args.stride_q,
                                              args.stride_k,
                                              args.stride_v,
                                              0, // stride_bias
                                              0, // stride_randval
                                              args.stride_o,
                                              args.nhead_stride_q,
                                              args.nhead_stride_k,
                                              args.nhead_stride_v,
                                              0, // nhead_stride_bias
                                              0, // nhead_stride_randval
                                              0, // nhead_stride_lse
                                              args.nhead_stride_o,
                                              args.batch_stride_q,
                                              args.batch_stride_k,
                                              args.batch_stride_v,
                                              0, // batch_stride_bias
                                              0, // batch_stride_randval
                                              0, // batch_stride_lse
                                              args.batch_stride_o,
                                              0,                         // window_size_left
                                              0,                         // window_size_right
                                              0,                         // mask_type
                                              0.0f,                      // p_drop
                                              false,                     // s_randval
                                              std::make_pair(0UL, 0UL)); // drop_seed_offset

    dim3 grids =
        fmha_kernel_0::GridSize(args.batch, args.nhead_q, args.seqlen_q, args.hdim_v, false);
    constexpr dim3 blocks                  = fmha_kernel_0::BlockSize();
    constexpr ck_tile::index_t kBlockPerCu = fmha_kernel_0::kBlockPerCu;

    auto stream = at::cuda::getCurrentHIPStream().stream();
    ck_tile::stream_config stream_config{stream};

    [[maybe_unused]] const float time = ck_tile::launch_kernel(
        stream_config,
        ck_tile::make_kernel<blocks.x, kBlockPerCu>(fmha_kernel_0{}, grids, blocks, 0, kargs));

    return {out};
}

} // namespace torch_itfs
} // namespace aiter
