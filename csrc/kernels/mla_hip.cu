// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.

#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include <cassert>

#define CHECK_HIP(call) \
    do { \
        hipError_t err = call; \
        if (err != hipSuccess) { \
            std::cerr << "[HIP ERROR] " << #call << " failed: " << hipGetErrorString(err) << std::endl; \
            return torch::Tensor(); \
        } \
    } while (0)

void print_tensor_shape(const char* name, const torch::Tensor& tensor) {
    auto sizes = tensor.sizes();
    printf("%s shape: [", name);
    for (size_t i = 0; i < sizes.size(); ++i) {
        printf("%ld", sizes[i]);
        if (i != sizes.size() - 1) printf(", ");
    }
    printf("]\n");
}

__global__ void mla_decode_hip_kernel(
    const __hip_bfloat16* __restrict__ q,     // [B, H_q, D_qk]
    const __hip_bfloat16* __restrict__ kv,    // [P * S, H_kv, D_qk]
    __hip_bfloat16* __restrict__ out,         // [B, H_q, D_v]
    const int* __restrict__ kv_indptr,        // [B+1]
    const int* __restrict__ kv_indices,       // [#used_kv]
    int D_qk, int D_v, int H_q, int H_kv, int B, int S,
    int max_tile, float softmax_scale
) {
    int b = blockIdx.x;
    int h = blockIdx.y;
    int d = threadIdx.x;
    if (d >= D_qk) return;

    int idx_q = b * H_q + h;
    int idx_o = b * H_q + h;
    const __hip_bfloat16* q_ptr = q + idx_q * D_qk;
    __hip_bfloat16* out_ptr = out + idx_o * D_v;

    int start = kv_indptr[b];
    int end = kv_indptr[b + 1];
    int len = end - start;

    extern __shared__ float shared_mem[];
    float* dot_buf = shared_mem;              // [max_tile]
    float* reduce_buf = dot_buf + max_tile;   // [D_qk]

    float acc = 0.0f;
    float p_sum = 0.0f;

    float local_max = -1e9f;

    for (int i = 0; i < len; ++i) {
        int global_idx = start + i;
        int page = kv_indices[global_idx];
        int flat_idx = page * S * H_kv * D_qk;
        const __hip_bfloat16* k_ptr = kv + flat_idx;

        float dot = __bfloat162float(q_ptr[d]) * __bfloat162float(k_ptr[d]);
        reduce_buf[d] = dot;
        __syncthreads();

        if (d == 0) {
            float total_dot = 0.0f;
            for (int j = 0; j < D_qk; ++j)
                total_dot += reduce_buf[j];
            dot_buf[i] = total_dot;
        }
        __syncthreads();

        if (d == 0)
            local_max = fmaxf(local_max, dot_buf[i]);
    }
    __syncthreads();

    __shared__ float e_max;
    if (d == 0) e_max = local_max;
    __syncthreads();

    for (int i = 0; i < len; ++i) {
        int global_idx = start + i;
        int page = kv_indices[global_idx];
        int flat_idx = page * S * H_kv * D_qk;
        const __hip_bfloat16* v_ptr = kv + flat_idx;

        float p = expf((dot_buf[i] - e_max) * softmax_scale);
        float v = __bfloat162float(v_ptr[d]);
        acc += p * v;
        p_sum += p;
    }

    if (d < D_v) {
        out_ptr[d] = __float2bfloat16(acc / (p_sum + 1e-6f));
    }
}

torch::Tensor mla_decode_fwd_hip(torch::Tensor &Q, torch::Tensor &KV, torch::Tensor &O,
    torch::Tensor &kv_indptr, torch::Tensor &kv_page_indices, torch::Tensor &kv_last_page_lens, float softmax_scale)
{
    TORCH_CHECK(Q.dtype() == torch::kBFloat16, "Q must be bfloat16");
    TORCH_CHECK(KV.dtype() == torch::kBFloat16, "KV must be bfloat16");
    TORCH_CHECK(O.dtype() == torch::kBFloat16, "O must be bfloat16");

    const at::cuda::OptionalCUDAGuard device_guard(device_of(Q));
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();

    int B = Q.size(0);
    int H_q = Q.size(1);
    int D_qk = Q.size(2);
    int P = KV.size(0);
    int S = KV.size(1);
    int H_kv = KV.size(2);
    int D_v = O.size(2);

    TORCH_CHECK(H_kv == 1, "num_kv_heads > 2 not support currently");

    // printf("===================================\n");
    // print_tensor_shape("Q", Q);
    // print_tensor_shape("KV", KV);
    // print_tensor_shape("O", O);
    // print_tensor_shape("kv_indptr", kv_indptr);
    // print_tensor_shape("kv_page_indices", kv_page_indices);
    // print_tensor_shape("kv_last_page_lens", kv_last_page_lens);
    // std::cout << "B=" << B << ", H_q=" << H_q << ", H_kv=" << H_kv << ", D_qk=" << D_qk << ", D_v=" << D_v << ", P=" << P << ", S=" << S << ", softmax_scale=" << softmax_scale << std::endl;

    const __hip_bfloat16* q_ptr = reinterpret_cast<const __hip_bfloat16*>(Q.data_ptr<at::BFloat16>());
    const __hip_bfloat16* kv_ptr = reinterpret_cast<const __hip_bfloat16*>(KV.data_ptr<at::BFloat16>());
    __hip_bfloat16* out_ptr = reinterpret_cast<__hip_bfloat16*>(O.data_ptr<at::BFloat16>());

    const int* indptr_ptr = kv_indptr.data_ptr<int>();
    const int* indices_ptr = kv_page_indices.data_ptr<int>();

    int max_tile_len = 8192;
    size_t shared_mem = (max_tile_len + D_qk * 2) * sizeof(float);

    dim3 grid(B, H_q);
    dim3 block(D_qk);

    //std::cout << "grid("<< grid.x << "," << grid.y << "," << grid.z << "), block(" << block.x << "), max_tile_len=" << max_tile_len << ", shared=" << shared_mem << " bytes\n";

    mla_decode_hip_kernel<<<grid, block, shared_mem, stream>>>(
        q_ptr, kv_ptr, out_ptr,
        indptr_ptr, indices_ptr,
        D_qk, D_v, H_q, H_kv, B, S, max_tile_len, softmax_scale);

    CHECK_HIP(hipGetLastError());

    return O;
}
