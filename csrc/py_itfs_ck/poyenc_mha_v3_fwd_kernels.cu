#include "mha_common.h"
#include "py_itfs_common.h"
#include <ATen/cuda/CUDAContext.h>
#include <torch/all.h>

namespace aiter {
namespace torch_itfs {

std::vector<at::Tensor> poyenc_mha_v3_fwd(at::Tensor& q,       // [b, sq, hq, d]
                                          const at::Tensor& k, // [b, sk, hk, d]
                                          const at::Tensor& v  // [b, sk, hk, d_v]
)
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

    auto opts = q.options();
    at::Tensor out =
        torch::empty({batch_size, seqlen_q, num_heads, head_size_v}, opts.dtype(q_dtype));

    return {out};
}

} // namespace torch_itfs
} // namespace aiter
