// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
#include "aiter_hip_common.h"
#include "py_itfs_common.h"
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include <cmath>
#include <hip/hip_runtime.h>
#include <torch/all.h>

struct __attribute__((packed)) KernelArgs
{
    void* ptr_D;
    p2 _p0;
    void* ptr_C;
    p2 _p1;
    void* ptr_A;
    p2 _p2;
    void* ptr_B;
    p2 _p3;
    float alpha;
    p3 _p4;
    float beta;
    p3 _p5;

    unsigned int stride_D0;
    p3 _p6;
    unsigned int stride_D1;
    p3 _p7;
    unsigned int stride_C0;
    p3 _p8;
    unsigned int stride_C1;
    p3 _p9;
    unsigned int stride_A0;
    p3 _p10;
    unsigned int stride_A1;
    p3 _p11;
    unsigned int stride_B0;
    p3 _p12;
    unsigned int stride_B1;
    p3 _p13;
    unsigned int M;
    p3 _p14;
    unsigned int N;
    p3 _p15;
    unsigned int K;
    p3 _p16;
    void* ptr_ScaleA;
    p2 _p17;
    void* ptr_ScaleB;
    p2 _p18;
    unsigned int stride_ScaleA0;
    p3 _p19;
    unsigned int stride_ScaleA1;
    p3 _p20;
    unsigned int stride_ScaleB0;
    p3 _p21;
    unsigned int stride_ScaleB1;
    p3 _p22;
    int log2_k_split;
    // p3 _p23;
};

int get_heuristic_mblksize(int M, int N, const std::vector<int>& available_tiles)
{
    hipDevice_t dev;
    hipDeviceProp_t dev_prop;
    HIP_CALL(hipGetDevice(&dev));
    HIP_CALL(hipGetDeviceProperties(&dev_prop, dev));
    uint32_t num_cu      = dev_prop.multiProcessorCount;
    uint32_t empty_cu    = num_cu;
    uint32_t tg_num      = 0;
    uint32_t round       = 0xffffffff;
    int selectedmblksize = 0;

    for(auto tile : available_tiles)
    {
        if((M * N % 256) == 0)
        {
            tg_num               = M * N / 256;
            uint32_t local_round = (tg_num + num_cu - 1) / num_cu;
            if(local_round < round)
            {
                round            = local_round;
                selectedmblksize = tile;
                empty_cu         = local_round * num_cu - tg_num;
            }
            else if(local_round == round)
            {
                if(empty_cu > (local_round * num_cu - tg_num))
                {
                    round            = local_round;
                    selectedmblksize = tile;
                    empty_cu         = local_round * num_cu - tg_num;
                }
            }
        }
    }
    return selectedmblksize;
};

int get_heuristic_ksplit(
    int dim, int inter_dim, int tileM, int tileN, const std::vector<int>& available_ksplit)
{
    hipDevice_t dev;
    hipDeviceProp_t dev_prop;
    HIP_CALL(hipGetDevice(&dev));
    HIP_CALL(hipGetDeviceProperties(&dev_prop, dev));
    uint32_t num_cu   = dev_prop.multiProcessorCount;
    uint32_t empty_cu = num_cu;
    uint32_t tg_num   = 0;
    uint32_t round    = 0xffffffff;
    int selectedK     = ((dim * inter_dim) / tileM * tileN > num_cu) ? 1 : 0;
    if(selectedK == 0)
        return 0;

    for(auto tile : available_ksplit)
    {
        if((inter_dim % tile) == 0)
        {
            tg_num = (dim * inter_dim) / tileM * tileN;
            // tg_num               = inter_dim / tile;
            tg_num               = tg_num / tile;
            uint32_t local_round = (tg_num + num_cu - 1) / num_cu;
            if(local_round < round)
            {
                round     = local_round;
                selectedK = tile;
                empty_cu  = local_round * num_cu - tg_num;
            }
            else if(local_round == round)
            {
                if(empty_cu > (local_round * num_cu - tg_num))
                {
                    round     = local_round;
                    selectedK = tile;
                    empty_cu  = local_round * num_cu - tg_num;
                }
            }
        }
    }
    return selectedK;
}

// A4W4 asm gemm kernel
// D=A*B*alpha+beta*C
torch::Tensor gemm_a4w4_asm(torch::Tensor& A,       // A:[M, K/2] f4x2
                            torch::Tensor& B,       // B:[N, K/2] f4x2
                            torch::Tensor& A_scale, // A_scale:[M, K/32] e8m0 paded
                            torch::Tensor& B_scale, // B_scale:[N, K/32] e8m0 paded
                            torch::Tensor& out,     // Out:[M, N] bf16
                            torch::Tensor& bias,    // bias:[M, N] f32
                            std::optional<float> alpha      = 1.0,
                            std::optional<float> beta       = 0.0,
                            std::optional<bool> bpreshuffle = true,
                            std::optional<int> log2_k_split = 99)

{
    TORCH_CHECK(
        out.dtype() == torch::ScalarType::BFloat16, __func__, " only support BFloat16 output now!");
    int Mdim = A.size(0);
    int Ndim = B.size(0);
    int Kdim = A.size(1) * 2; // always fp4_x2F
    KernelArgs args;
    size_t arg_size = sizeof(args);
    args.ptr_D      = (void*)out.data_ptr();
    args.ptr_C      = (void*)bias.data_ptr();
    args.ptr_A      = (void*)A.data_ptr();
    args.ptr_B      = (void*)B.data_ptr();

    args.alpha          = alpha.value();
    args.beta           = beta.value();
    args.stride_C0      = out.stride(0);
    args.stride_A0      = A.stride(0) * 2; // always fp4_x2
    args.stride_B0      = B.stride(0) * 2; // always fp4_x2
    args.M              = Mdim;
    args.N              = Ndim;
    args.K              = Kdim;
    args.ptr_ScaleA     = (void*)A_scale.data_ptr();
    args.ptr_ScaleB     = (void*)B_scale.data_ptr();
    args.stride_ScaleA0 = A_scale.stride(0);
    args.stride_ScaleB0 = B_scale.stride(0);

    const at::cuda::OptionalCUDAGuard device_guard(device_of(A));
    const cudaStream_t stream = at::cuda::getCurrentCUDAStream();

    // TODO should get from kernel ; ini arg for 256x256 tiles
    int tg_group_size = 32;
    int SUBM          = 256;
    int SUBN          = 256;
    int gdz           = 1;
    args.log2_k_split = 0;

    int selectedksplit = get_heuristic_ksplit(Mdim, Ndim, SUBM, SUBN, {2, 4, 8, 16});
    selectedksplit     = std::log2(selectedksplit);
    int selectedMTile  = get_heuristic_mblksize(Mdim, Ndim, {256, 128});

    AiterAsmKernel* impl_ptr = nullptr;
    if(log2_k_split.value() != 0 || selectedksplit != 0)
    {
        int k_num = 1;
        if(log2_k_split.value() == 99)
        {
            k_num             = 1 << selectedksplit;
            args.log2_k_split = selectedksplit;
        }
        else
        {
            k_num             = 1 << log2_k_split.value();
            args.log2_k_split = log2_k_split.value();
        }
        static AiterAsmKernel SplitK_impl(
            "_ZN5aiter45f4gemm_outBF16_128x512_scale_B_Shuffle_KSplitE",
            "f4gemm/f4gemm_outBF16_128x512_scale_B_Shuffle_KSplit.co");
        impl_ptr = &SplitK_impl;
        SUBM     = 128;
        SUBN     = 512;

        assert(Kdim % k_num == 0);
        int k_per_tg = Kdim / k_num;
        k_per_tg     = ((k_per_tg + 256 - 1) / 256) * 256;
        gdz          = (Kdim + k_per_tg - 1) / k_per_tg;
        // printf("Debug: Kdim %d, log2_k_split %d, k_per_tg %d, global_tg_z %d\n",
        //        Kdim,
        //        log2_k_split.value(),
        //        k_per_tg,
        //        gdz);
    }
    else if(selectedMTile < 256)
    {
        static AiterAsmKernel noSplitK_m128_impl(
            "_ZN5aiter38f4gemm_outBF16_128x512_scale_B_ShuffleE",
            "f4gemm/f4gemm_outBF16_128x512_scale_B_Shuffle.co");
        impl_ptr = &noSplitK_m128_impl;
        SUBM     = 128;
        SUBN     = 512;
    }
    else if(bpreshuffle.has_value())
    {
        static AiterAsmKernel noSplitK_bpreshuffle_m128_impl(
            "_ZN5aiter45f4gemm_bf16_per1x32Fp4_tn_bpreshuffle_256x256E",
            "f4gemm/f4gemm_bf16_per1x32Fp4_tn_bpreshuffle_256x256.co");
        impl_ptr = &noSplitK_bpreshuffle_m128_impl;
    }
    else
    {
        static AiterAsmKernel noSplitK_m128("_ZN5aiter33f4gemm_bf16_per1x32Fp4_tn_256x256E",
                                            "f4gemm/f4gemm_bf16_per1x32Fp4_tn_256x256.co");
        impl_ptr = &noSplitK_m128;
    }

    int gdx = (Ndim + SUBN - 1) / SUBN;
    int gdy = (Mdim + SUBM - 1) / SUBM;

    impl_ptr->launch_kernel({&args,
                             &arg_size,
                             gdx, // gdx
                             gdy, // gdy
                             gdz, // gdz
                             256, // bdx: 4 wv64
                             1,   // bdy
                             1,   // bdz
                             stream});
    return out;
}
