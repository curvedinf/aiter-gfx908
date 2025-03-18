// SPDX-License-Identifier: MIT
// Copyright (c) 2024, Advanced Micro Devices, Inc. All rights reserved.
#include <hip/hip_runtime.h>
#include <hip/hip_fp16.h>
#include <torch/all.h>
#include <ATen/cuda/CUDAContext.h>
#include <c10/cuda/CUDAGuard.h>
#include "aiter_hip_common.h"

struct __attribute__((packed)) KernelArgs
{
    void *ptr_O;
    p2 _p0;
    void *ptr_X;
    p2 _p1;
    void *ptr_GU;
    p2 _p2;
    void *ptr_XC;
    p2 _p3;
    void *ptr_XQ;
    p2 _p4;
    void *ptr_GUQ;
    p2 _p5;
    void *ptr_SMQ;
    p2 _p6;
    void *ptr_STP;
    p2 _p7;
    void *ptr_SEP;
    p2 _p8;
    unsigned int dim;
    p3 _p9;
    unsigned int hidden_dim;
    p3 _p10;
    unsigned int token_cnt;
    p3 _p11;
    unsigned int eprt_cnt;
    p3 _p12;
    unsigned int Xs;
    p3 _p13;
    unsigned int GUs;
    p3 _p14;
    unsigned int Os;
    p3 _p15;
    unsigned int eGUs;
    p3 _p16;
    unsigned int eGUQs;
    p3 _p17;
    unsigned int eSMQs;
    p3 _p18;
    unsigned int topk;
    p3 _p19;
};

class MoeStage1_Kernel
{
private:
    hipModule_t module;
    hipFunction_t kernel_func;
    uint32_t sub_GU = 512;
    bool is_int4 = false;

public:
    MoeStage1_Kernel(const char *name, const char *hsaco, uint32_t sub_GU = 512)
    {
        const char *AITER_ASM_DIR = std::getenv("AITER_ASM_DIR");
        std::cout << "hipModuleLoad: " << (std::string(AITER_ASM_DIR) + hsaco).c_str() << " GetFunction: " << name;
        HIP_CALL(hipModuleLoad(&module, (std::string(AITER_ASM_DIR) + hsaco).c_str()));
        HIP_CALL(hipModuleGetFunction(&kernel_func, module, name));
        std::cout << " Success" << std::endl;
        this->sub_GU = sub_GU;
    };

    void set_int4(bool is_int4_)
    {
        is_int4 = is_int4_;
    }

    template <typename T, typename T_O, bool switchGxy = false>
    void launch_kernel(torch::Tensor &out,               // [token_cnt, dim]
                       torch::Tensor &input,             // [token_cnt, dim] M,K
                       torch::Tensor &w1,                // [expert, hidden_dim, dim] N,K
                       torch::Tensor &w2,                // [expert, dim, hidden_dim]
                       torch::Tensor &sorted_token_ids,  // [max_num_tokens_padded]
                       torch::Tensor &sorted_weight_buf, // [max_num_tokens_padded]
                       torch::Tensor &sorted_expert_ids, // [max_num_m_blocks]
                       torch::Tensor &num_valid_ids,     // [1]
                       uint32_t topk,                    //
                       std::optional<torch::Tensor> input_dqn = std::nullopt,
                       std::optional<torch::Tensor> w1_dqn = std::nullopt,
                       std::optional<torch::Tensor> w2_dqn = std::nullopt,
                       std::optional<torch::Tensor> w2_smooth_qnt = std::nullopt //
    )
    {
        int token_cnt = out.size(0);
        int dim = input.size(1);
        int sub_X_cnt = sorted_expert_ids.size(0);
        int eprt = w1.size(0);
        int hidden_dim = is_int4 ? w2.size(2) * 8 : w2.size(2);
        uint32_t sub_GU = this->sub_GU;
        uint32_t I_elemSize = sizeof(T);
        uint32_t O_elemSize = sizeof(T_O);

        int stride_X = input.stride(0) * input.element_size();
        int stride_GU = dim * I_elemSize;;
        if (is_int4)
        {
            stride_GU /= 2;
        }
        int stride_expert_GU = stride_GU * hidden_dim;
        //int stride_expert_D = stride_D * dim;
        int stride_expert_GUDQN = w1_dqn.has_value() ? w1_dqn.value().stride(0) * sizeof(float) : 0;
        //int stride_expert_DDQN = w2_dqn.has_value() ? w2_dqn.value().stride(0) * sizeof(float) : 0;
        int stride_expert_SMTDQN = hidden_dim * sizeof(float);
        int stride_O = hidden_dim * O_elemSize * topk;
        if (hidden_dim * 2 == w1.size(1))
        {
            stride_expert_GU *= 2;
        }

        KernelArgs args;
        size_t arg_size = sizeof(args);
        args.ptr_O = out.data_ptr();
        args.ptr_X = input.data_ptr();
        args.ptr_GU = w1.data_ptr();
        args.ptr_XC = num_valid_ids.data_ptr();
        if constexpr (std::is_same<T, uint8_t>::value)
        {
            args.ptr_XQ = input_dqn.value().data_ptr();
            args.ptr_GUQ = w1_dqn.value().data_ptr();
            args.ptr_SMQ = w2_smooth_qnt.has_value() ? w2_smooth_qnt.value().data_ptr() : nullptr;
        }
        else
        {
            args.ptr_XQ = nullptr;
            args.ptr_GUQ = nullptr;
            args.ptr_SMQ = nullptr;
        }
        args.ptr_STP = sorted_token_ids.data_ptr();
        args.ptr_SEP = sorted_expert_ids.data_ptr();
        args.dim = dim;
        args.hidden_dim = hidden_dim;
        args.token_cnt = token_cnt;
        args.eprt_cnt = eprt;
        args.Xs = stride_X;
        args.GUs = stride_GU;
        args.Os = stride_O;
        args.eGUs = stride_expert_GU;
        args.eGUQs = stride_expert_GUDQN;
        args.eSMQs = stride_expert_SMTDQN;
        args.topk = topk;

        void *config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, &args, HIP_LAUNCH_PARAM_BUFFER_SIZE,
                          &arg_size, HIP_LAUNCH_PARAM_END};

        int bdx = 256;
        int gdx = ((hidden_dim + sub_GU - 1) / sub_GU);
        int gdy = sub_X_cnt;
        int gdz = 1;
        //std::cout << "args.dim: " << args.dim << std::endl;
        //std::cout << "args.hidden_dim: " << args.hidden_dim << std::endl;
        //std::cout << "args.token_cnt: " << args.token_cnt << std::endl;
        //std::cout << "args.eprt_cnt: " << args.eprt_cnt << std::endl;
        //std::cout << "args.stride_X: " << args.Xs << std::endl;
        //std::cout << "args.stride_GU: " << args.GUs << std::endl;
        //std::cout << "args.stride_O: " << args.Os << std::endl;
        //std::cout << "args.stride_expert_GU: " << args.eGUs << std::endl;
        //std::cout << "args.stride_expert_GUDQN: " << args.eGUQs << std::endl;
        //std::cout << "args.stride_expert_SMTDQN: " << args.eSMQs << std::endl;
        //std::cout << "args.topk: " << args.topk << std::endl;
        //std::cout << "gdx: " << gdx << std::endl;
        //std::cout << "gdy: " << gdy << std::endl;

        const at::cuda::OptionalCUDAGuard device_guard(device_of(input));
        const cudaStream_t stream = at::cuda::getCurrentCUDAStream();
        if constexpr (switchGxy)
        {
            HIP_CALL(hipModuleLaunchKernel(kernel_func,
                                           gdy, gdx, gdz,
                                           bdx, 1, 1,
                                           0, stream, nullptr, (void **)&config));
        }
        else
        {
            HIP_CALL(hipModuleLaunchKernel(kernel_func,
                                           gdx, gdy, gdz,
                                           bdx, 1, 1,
                                           0, stream, nullptr, (void **)&config));
        }
    };
};

void moe_stage1_fp8_g1u1(torch::Tensor &out,               // [token_cnt, dim]
                              torch::Tensor &input,             // [token_cnt, dim] M,K
                              torch::Tensor &gate,              // [expert, hidden_dim*2, dim] N,K
                              torch::Tensor &down,              // [expert, dim, hidden_dim]
                              torch::Tensor &sorted_token_ids,  // [max_num_tokens_padded]
                              torch::Tensor &sorted_weight_buf, // [max_num_tokens_padded]
                              torch::Tensor &sorted_expert_ids, // [max_num_m_blocks]
                              torch::Tensor &num_valid_ids,     // [1]
                              uint32_t topk,                    //
                              torch::Tensor &fc1_scale,         // [expert, 1, hidden_dim]
                              std::optional<torch::Tensor> &fc2_scale,     // [expert, 1, dim]
                              torch::Tensor input_scale,        // [expert, 1, dim]
                              std::optional<torch::Tensor> fc2_smooth_scale = std::nullopt) // [expert, 1, hidden_dim])
{
    MoeStage1_Kernel *impl_ptr = nullptr;
    int hidden_dim = down.size(2);
    int sub_X_cnt = sorted_expert_ids.size(0);
    // int selectedTile = get_heuristic_tile(hidden_dim, sub_X_cnt); // todo,add tune interface here
    const char *enable_vskip = std::getenv("AITER_ENABLE_VSKIP");

    if (out.dtype() == at::ScalarType::BFloat16 && hidden_dim % 256 == 0)
    {
        static MoeStage1_Kernel impl_128_novs("stage1_moe_fp8_g1u1_subX128_subGU128", "stage1_moe_fp8_g1u1_subX128_subGU128.co", 128);
        impl_ptr = &impl_128_novs;
    }
    else
        TORCH_CHECK(false, __func__, " Only support out dtype = bf16, hidden_dim % 256 = 0");

    impl_ptr->launch_kernel<uint8_t, uint16_t, false>(out,
                                                      input,
                                                      gate,
                                                      down,
                                                      sorted_token_ids,
                                                      sorted_weight_buf,
                                                      sorted_expert_ids,
                                                      num_valid_ids,
                                                      topk,
                                                      // quant args
                                                      input_scale,
                                                      fc1_scale,
                                                      fc2_scale,
                                                      fc2_smooth_scale);
}
