#include <fmt/core.h>
#include "asm_mla_decode_fwd.h"
#include "../utils.h"

namespace aiter{

#define MD_NAME "asm_mla_decode_fwd"


void asm_mla_decode_fwd(
                    std::optional<std::string> folder, 
                    void* Q,                 //   [num_seqs, num_heads, head_size]
                    void* KV,                //   [num_page, page_size, num_kv_heads, head_size]
                    void* kv_indptr,         //   [batch_size+1]
                    void* kv_page_indices,   //   [num_page_used]
                    void* kv_last_page_lens, //   [batch_size]
                    float softmax_scale,
                    // following are output
                    void* logits, //[batch_size, num_kv_splits, num_heads, v_head_dim]
                    void* attn_lse,   //[batch_size, num_kv_splits, num_heads,  1]
                    void* output,
                    int num_seqs,
                    int num_heads,
                    int num_kv_heads,
                    int stride_Q,
                    int stride_Page,
                    int attn_lse_stride_0,
                    int attn_lse_stride_1,
                    int attn_lse_stride_2,
                    int output_stride_0,
                    int output_stride_1,
                    const int page_size,
                    const int q_itemsize,
                    const int kv_itemsize,
                    const int num_kv_splits,
                    const int v_head_dim,
                    const hipStream_t stream) {
  std::vector<std::string> args{std::to_string(page_size), std::to_string(q_itemsize), std::to_string(kv_itemsize), std::to_string(num_kv_splits), std::to_string(v_head_dim)};
  std::string func_name = get_default_func_name(MD_NAME, args);
  if(!folder){
    folder = func_name;
  }
  if (not_built(folder.value())) {
    std::string cmd = fmt::format(
        R"(python3 asm_mla_decode_fwd.py --hsaco_path={hsaco_path} \
                                    --page_size={page_size} \
                                    --q_itemsize={q_itemsize} \
                                    --kv_itemsize={kv_itemsize} \
                                    --num_kv_splits={num_kv_splits} \
                                    --v_head_dim={v_head_dim})",
        fmt::arg("hsaco_path", "../../../hsa/mla_stage1_a16w16_bf16.co"),
        fmt::arg("page_size", page_size),
        fmt::arg("q_itemsize", q_itemsize),
        fmt::arg("kv_itemsize", kv_itemsize),
        fmt::arg("num_kv_splits", num_kv_splits),
        fmt::arg("v_head_dim", v_head_dim));
    executeCmd(cmd);
  }
  run_lib(func_name, folder.value(), Q, KV, kv_indptr, kv_page_indices, kv_last_page_lens, softmax_scale, logits, attn_lse, output, num_seqs, num_heads, num_kv_heads, stride_Q, stride_Page, attn_lse_stride_0, attn_lse_stride_1, attn_lse_stride_2, output_stride_0, output_stride_1, reinterpret_cast<const void*>(stream));
}
#undef MD_NAME
}