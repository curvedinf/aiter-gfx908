// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
#pragma once
#include <hip/hip_runtime.h>
#include <iostream>
#include <filesystem>
#include <unistd.h>
#include <limits.h>
#include "ck_tile/core.hpp"

namespace fs = std::filesystem;

#if CK_TILE_USE_OCP_FP8
constexpr auto FP8_MAX = 448.f;
#else
constexpr auto FP8_MAX = 240.f;
#endif

#define HIP_CALL(call)                                                                                                           \
    do                                                                                                                           \
    {                                                                                                                            \
        hipError_t err = call;                                                                                                   \
        if (err != hipSuccess)                                                                                                   \
        {                                                                                                                        \
            printf("\n[AITER] %s:%d fail to call %s ---> [HIP error](%s)\n", __FILE__, __LINE__, #call, hipGetErrorString(err)); \
            exit(0);                                                                                                             \
        }                                                                                                                        \
    } while (0)

struct p3
{
    unsigned int _p0;
    unsigned int _p1;
    unsigned int _p2;
};
struct p2
{
    unsigned int _p0;
    unsigned int _p1;
};
struct p1
{
    unsigned int _p0;
};

std::string get_gpu_arch_hip() {
    int device_count;
    hipError_t err = hipGetDeviceCount(&device_count);
    if (err != hipSuccess || device_count == 0) {
        std::cerr <<  "No GPU Found" << std::endl;
    }

    hipDeviceProp_t prop;
    err = hipGetDeviceProperties(&prop, 0);
    if (err != hipSuccess) {
        std::cerr << "Failed to get GPU device properties: " << hipGetErrorString(err) << std::endl;
    }

    std::string arch_full = prop.gcnArchName;
    size_t colon_pos = arch_full.find(':');
    if (colon_pos != std::string::npos) {
        return arch_full.substr(0, colon_pos);
    } else {
        return arch_full;
    }
}

std::string get_aiter_asm_dir() {
    std::string arch = get_gpu_arch_hip();
    fs::path aiter_core_dir = std::filesystem::absolute(__FILE__).parent_path().parent_path().parent_path().parent_path();
    fs::path aiter_asm_dir = aiter_core_dir / "hsa" / arch / "";

    if (!fs::exists(aiter_asm_dir)) {
        std::cerr << "cannot find aiter asm dir: " << aiter_asm_dir << std::endl;
        return fs::path();
    }
    return aiter_asm_dir;
}

struct AiterAsmKernelArgs
{
    void *args_ptr;
    void *arg_size_ptr;
    int gdx;
    int gdy;
    int gdz;
    int bdx;
    int bdy;
    int bdz;
    const hipStream_t stream;
};

class AiterAsmKernel
{
private:
    hipModule_t module;
    hipFunction_t kernel_func;

public:
    AiterAsmKernel(const char *name, const char *hsaco)
    {
        std::string AITER_ASM_DIR;
        if (const char* env_val = std::getenv("AITER_ASM_DIR")) {
            AITER_ASM_DIR = env_val;
        } else {
            AITER_ASM_DIR = get_aiter_asm_dir();
        }
        std::cout << "[aiter] hipModuleLoad: " << (AITER_ASM_DIR + hsaco).c_str() << " GetFunction: " << name;
        HIP_CALL(hipModuleLoad(&module, (AITER_ASM_DIR + hsaco).c_str()));
        HIP_CALL(hipModuleGetFunction(&kernel_func, module, name));
        std::cout << " Success" << std::endl;
    };

    ~AiterAsmKernel()
    {
        HIP_CALL(hipModuleUnload(module));
    }

    void launch_kernel(const AiterAsmKernelArgs &kargs)
    {
        void *config[] = {HIP_LAUNCH_PARAM_BUFFER_POINTER, kargs.args_ptr,
                          HIP_LAUNCH_PARAM_BUFFER_SIZE, kargs.arg_size_ptr,
                          HIP_LAUNCH_PARAM_END};

        HIP_CALL(hipModuleLaunchKernel(kernel_func,
                                       kargs.gdx, kargs.gdy, kargs.gdz,
                                       kargs.bdx, kargs.bdy, kargs.bdz,
                                       0, kargs.stream, nullptr, (void **)&config));
    };
};
