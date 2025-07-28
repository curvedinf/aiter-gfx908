// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.

#include <hip/hip_runtime.h>

#include <cstring>
#include <iostream>
#include <ostream>
#include <string>
#include <tuple>

// #include "grouped_flatmm.hpp"
#include "m_grouped_flatmm_ck.h"

#include "ck_tile/host.hpp"

template <typename ADataType,
          typename BDataType,
          typename AccDataType,
          typename CDataType,
          typename ALayout,
          typename BLayout,
          typename CLayout,
          typename KernelArguments>
float grouped_flatmm(const KernelArguments& args, const ck_tile::stream_config& s)
{
    // The kPadM, kPadN, kPadK & kBlockPerCu should also come from the Codegen part.
    constexpr bool kPadM = false;
    constexpr bool kPadN = false;
    constexpr bool kPadK = false;

    constexpr int kBlockPerCu = 1;

    constexpr ck_tile::index_t M_Tile = GemmConfig<BDataType>::M_Tile;
    constexpr ck_tile::index_t N_Tile = GemmConfig<BDataType>::N_Tile;
    constexpr ck_tile::index_t K_Tile = GemmConfig<BDataType>::K_Tile;

    constexpr ck_tile::index_t M_Warp = GemmConfig<BDataType>::M_Warp;
    constexpr ck_tile::index_t N_Warp = GemmConfig<BDataType>::N_Warp;
    constexpr ck_tile::index_t K_Warp = GemmConfig<BDataType>::K_Warp;

    constexpr ck_tile::index_t M_Warp_Tile = GemmConfig<BDataType>::M_Warp_Tile;
    constexpr ck_tile::index_t N_Warp_Tile = GemmConfig<BDataType>::N_Warp_Tile;
    constexpr ck_tile::index_t K_Warp_Tile = GemmConfig<BDataType>::K_Warp_Tile;

    using Traits = ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;

    using CodegenFlatmmShape =
        ck_tile::TileFlatmmShape<ck_tile::sequence<M_Tile, N_Tile, K_Tile>,
                                 ck_tile::sequence<M_Warp, N_Warp, K_Warp>,
                                 ck_tile::sequence<M_Warp_Tile, N_Warp_Tile, K_Warp_Tile>>;

    using TilePartitioner = ck_tile::GemmTile1DPartitioner<CodegenFlatmmShape>;

    using GemmPipelineProblem =
        ck_tile::GemmPipelineProblem<ADataType, BDataType, AccDataType, CodegenFlatmmShape, Traits>;

    using BaseGemmPipeline = ck_tile::BaseFlatmmPipelineAGmemBGmemCRegV1<GemmPipelineProblem>;

    // const ck_tile::index_t k_grain     = args.k_batch * K_Tile;
    // const ck_tile::index_t K_split     = (args.K + k_grain - 1) / k_grain * K_Tile;
    // const ck_tile::index_t num_loop    = TilePartitioner::GetLoopNum(K_split);
    // const bool has_hot_loop            = BaseGemmPipeline::BlockHasHotloop(num_loop);
    // const ck_tile::TailNumber tail_num = BaseGemmPipeline::GetBlockLoopTailNum(num_loop);

    const bool has_hot_loop            = true;
    const ck_tile::TailNumber tail_num = ck_tile::TailNumber::Even;

    using CodegenGemmTraits =
        ck_tile::TileGemmTraits<kPadM, kPadN, kPadK, ALayout, BLayout, CLayout>;

    float ave_time{0};

    const auto Run = [&](const auto has_hot_loop_,
                         const auto tail_number_,
                         const auto memory_operation_) {
        constexpr bool has_hot_loop_v   = has_hot_loop_.value;
        constexpr auto tail_number_v    = tail_number_.value;
        constexpr auto memory_operation = memory_operation_.value;
        using CodegenPipelineProblem    = ck_tile::FlatmmPipelineProblem<ADataType,
                                                                         BDataType,
                                                                         AccDataType,
                                                                         CodegenFlatmmShape,
                                                                         CodegenGemmTraits,
                                                                         has_hot_loop_v,
                                                                         tail_number_v>;

        using GemmEpilogue = ck_tile::CShuffleEpilogue<
            ck_tile::CShuffleEpilogueProblem<ADataType,
                                             BDataType,
                                             AccDataType,
                                             CDataType,
                                             CLayout,
                                             CodegenPipelineProblem::kBlockSize,
                                             TilePartitioner::MPerBlock,
                                             TilePartitioner::NPerBlock,
                                             M_Warp,
                                             N_Warp,
                                             M_Warp_Tile,
                                             N_Warp_Tile,
                                             K_Warp_Tile,
                                             CodegenPipelineProblem::TransposeC,
                                             memory_operation>>;

        using CodegenFlatmmPolicy = ck_tile::UniversalFlatmmPipelineAgBgCrPolicy;
        using CodegenFlatmmPipeline =
            ck_tile::FlatmmPipelineAGmemBGmemCRegV1<CodegenPipelineProblem, CodegenFlatmmPolicy>;

        // ToDo: Will add the codegen part to test different pipeline policies in GEMM.
        // Now we only use the BlockGemmASmemBSmemCRegV1DefaultPolicy.
        using Kernel =
            ck_tile::GroupedFlatmmKernel<TilePartitioner, CodegenFlatmmPipeline, GemmEpilogue>;

        auto kargs = Kernel::MakeKernelArgs(args);

        const dim3 grids      = Kernel::GridSize(kargs);
        constexpr dim3 blocks = Kernel::BlockSize();

        // if(!Kernel::IsSupportedArgument(kargs))
        // {
        //     throw std::runtime_error("Wrong! Arguments not supported! Skipping gemm!\n");
        // }

        if(s.log_level_ > 0)
        {
            std::cout << "Launching kernel with args:"
                      << " grid: {" << grids.x << ", " << grids.y << ", " << grids.z << "}"
                      << ", blocks: {" << blocks.x << ", " << blocks.y << ", " << blocks.z << "}"
                      << std::endl;
        }

        ave_time = ck_tile::launch_kernel(
            s, ck_tile::make_kernel<blocks.x, kBlockPerCu>(Kernel{}, grids, blocks, 0, kargs));

        return ave_time;
    };

    const auto RunSplitk = [&](const auto has_hot_loop_, const auto tail_number_) {
        if(args.k_batch == 1)
        {
            Run(has_hot_loop_,
                tail_number_,
                ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                           ck_tile::memory_operation_enum::set>{});
        }
        else
        {
            Run(has_hot_loop_,
                tail_number_,
                ck_tile::integral_constant<ck_tile::memory_operation_enum,
                                           ck_tile::memory_operation_enum::atomic_add>{});
        }
    };

    if(tail_num == ck_tile::TailNumber::Odd)
    {
        RunSplitk(ck_tile::bool_constant<true>{},
                  ck_tile::integral_constant<ck_tile::TailNumber, ck_tile::TailNumber::Odd>{});
    }
    else if(tail_num == ck_tile::TailNumber::Even)
    {
        RunSplitk(ck_tile::bool_constant<true>{},
                  ck_tile::integral_constant<ck_tile::TailNumber, ck_tile::TailNumber::Even>{});
    }
    else
    {
        std::ostringstream err;
        err << "For compute pipeline tail number should always be Full, but have \"" << tail_num
            << "\" which is not supported! PrefetchStages: " << BaseGemmPipeline::PrefetchStages
            << "\n File: " << __FILE__ << ":" << __LINE__ << ", in function: " << __func__;
        throw std::runtime_error(err.str());
    }

    return ave_time;
}

template <typename Layout>
static constexpr inline auto is_row_major(Layout layout_)
{
    return ck_tile::bool_constant<std::is_same_v<ck_tile::remove_cvref_t<decltype(layout_)>,
                                                 ck_tile::tensor_layout::gemm::RowMajor>>{};
}

template <typename T>
auto shuffle_b(const ck_tile::HostTensor<T>& t)
{
    assert(t.get_lengths().size() == 2);
    int n_ = t.get_lengths()[1];
    int k_ = t.get_lengths()[0];

    constexpr int N_Warp_Tile = GemmConfig<T>::N_Warp_Tile;
    constexpr int N_Warp      = GemmConfig<T>::N_Warp;
    constexpr int KPerLane    = GemmConfig<T>::K_Warp_Tile / (64 / N_Warp_Tile);

    ck_tile::HostTensor<T> t_view({n_ / N_Warp_Tile,
                                   N_Warp_Tile,
                                   k_ / (64 * KPerLane / N_Warp_Tile),
                                   64 / N_Warp_Tile,
                                   KPerLane});
    std::copy(t.begin(), t.end(), t_view.begin());
    return ck_tile::reference_permute(t_view, {0, 2, 3, 1, 4});
}

template <typename ADataType, typename BDataType, typename AccDataType, typename CDataType>
auto calculate_rtol_atol(const ck_tile::index_t K,
                         const ck_tile::index_t kbatch,
                         const float max_accumulated_value)
{
    using ComputeType =
        std::conditional_t<sizeof(ADataType) < sizeof(BDataType), ADataType, BDataType>;
    // Calculate thresholds
    const auto rtol = ck_tile::get_relative_threshold<ComputeType, CDataType, AccDataType>(
        ck_tile::integer_divide_ceil(K, kbatch));
    const auto atol = ck_tile::get_absolute_threshold<ComputeType, CDataType, AccDataType>(
        max_accumulated_value / kbatch, ck_tile::integer_divide_ceil(K, kbatch));
    // Calculate error due to split_k accumulation
    const auto rtol_split_k =
        ck_tile::get_relative_threshold<CDataType, CDataType, CDataType>(kbatch);
    const auto atol_split_k = ck_tile::get_absolute_threshold<CDataType, CDataType, CDataType>(
        max_accumulated_value, kbatch);
    // Use higher threshold
    return ck_tile::make_tuple(std::max(rtol, rtol_split_k), std::max(atol, atol_split_k));
}

template <typename ADataType,
          typename BDataType,
          typename AccDataType,
          typename CDataType,
          typename ALayout,
          typename BLayout,
          typename CLayout>
float invoke_gemm(int n_warmup, int n_repeat, const ck_tile::MaskedGroupedFlatmmHostArgs& args)
{
    float ave_time =
        grouped_flatmm<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(
            args, ck_tile::stream_config{nullptr, true, 1, n_warmup, n_repeat});

    std::string op_name{"Grouped Gemm"};

    std::size_t flop     = std::size_t(2) * args.Max_M * args.N * args.K;
    std::size_t num_byte = sizeof(ADataType) * args.Max_M * args.K +
                           sizeof(BDataType) * args.N * args.K +
                           sizeof(CDataType) * args.Max_M * args.N;

    float tflops     = static_cast<float>(flop) / 1.E9 / ave_time;
    float gb_per_sec = num_byte / 1.E6 / ave_time;

    std::cout << "Perf: " << std::setw(10) << ave_time << " ms, " << tflops << " TFlops, "
              << gb_per_sec << " GB/s, " << op_name << std::endl;

    return ave_time;
}

template <typename PrecType, typename ALayout, typename BLayout, typename CLayout>
int run_grouped_flatmm_example_with_layouts(int argc,
                                            char* argv[],
                                            const ALayout a_layout                  = ALayout{},
                                            const BLayout b_layout                  = BLayout{},
                                            [[maybe_unused]] const CLayout c_layout = CLayout{})
{
    auto [result, arg_parser] = create_args(argc, argv);

    if(!result)
    {
        return -1;
    };

    using ADataType   = typename GemmBasicTypeConfig<PrecType>::ADataType;
    using BDataType   = typename GemmBasicTypeConfig<PrecType>::BDataType;
    using CDataType   = typename GemmBasicTypeConfig<PrecType>::CDataType;
    using AccDataType = typename GemmBasicTypeConfig<PrecType>::AccDataType;

    const int group_count = arg_parser.get_int("group_count");
    const int repeat      = arg_parser.get_int("repeat");
    const int warmup      = arg_parser.get_int("warmup");

    std::vector<ck_tile::index_t> Ms = arg_parser.get_int_vec("Ms");
    std::vector<ck_tile::index_t> Ns = arg_parser.get_int_vec("Ns");
    std::vector<ck_tile::index_t> Ks = arg_parser.get_int_vec("Ks");
    std::vector<ck_tile::index_t> stride_As;
    std::vector<ck_tile::index_t> stride_Bs;
    std::vector<ck_tile::index_t> stride_Cs;
    ck_tile::index_t kbatch = arg_parser.get_int("split_k");

    std::vector<ck_tile::HostTensor<ADataType>> a_m_k_tensors;
    std::vector<ck_tile::HostTensor<BDataType>> b_k_n_tensors;
    std::vector<ck_tile::HostTensor<CDataType>> c_m_n_tensors;

    std::vector<std::unique_ptr<ck_tile::DeviceMem>> a_m_k_dev_buf;
    std::vector<std::unique_ptr<ck_tile::DeviceMem>> b_shfl_dev_buf;
    std::vector<std::unique_ptr<ck_tile::DeviceMem>> c_m_n_dev_buf;

    std::vector<void*> group_a_ptrs;
    std::vector<void*> group_b_ptrs;
    std::vector<void*> group_c_ptrs;

    if(!(int(Ms.size()) == group_count && int(Ns.size()) == group_count &&
         int(Ks.size()) == group_count))
    {
        std::cout << "Please check the input data." << std::endl;
        for(int i = 0; i < group_count; i++)
        {
            Ms.push_back(256 + 256 * i);
            Ns.push_back(128 + 128 * i);
            Ks.push_back(512 + 512 * i);
        }
    }

    for(int i = 0; i < group_count; ++i)
    {
        const ck_tile::index_t M = Ms[i];
        const ck_tile::index_t N = Ns[i];
        const ck_tile::index_t K = Ks[i];

        stride_As.push_back(ck_tile::get_default_stride(M, K, 0, is_row_major(a_layout)));
        stride_Bs.push_back(ck_tile::get_default_stride(K, N, 0, is_row_major(b_layout)));
        stride_Cs.push_back(ck_tile::get_default_stride(M, N, 0, is_row_major(c_layout)));

        a_m_k_tensors.push_back(ck_tile::HostTensor<ADataType>(
            ck_tile::host_tensor_descriptor(M, K, stride_As[i], is_row_major(a_layout))));
        b_k_n_tensors.push_back(ck_tile::HostTensor<BDataType>(
            ck_tile::host_tensor_descriptor(K, N, stride_Bs[i], is_row_major(b_layout))));
        c_m_n_tensors.push_back(ck_tile::HostTensor<CDataType>(
            ck_tile::host_tensor_descriptor(M, N, stride_Cs[i], is_row_major(c_layout))));

        std::cout << "gemm[" << i << "]"
                  << " a_m_k: " << a_m_k_tensors[i].mDesc << " b_k_n: " << b_k_n_tensors[i].mDesc
                  << " c_m_n: " << c_m_n_tensors[i].mDesc << std::endl;

        ck_tile::FillUniformDistribution<ADataType>{-1.f, 1.f}(a_m_k_tensors[i]);
        ck_tile::FillUniformDistribution<BDataType>{-4.f, 4.f}(b_k_n_tensors[i]);
        ck_tile::HostTensor<BDataType> b_shuffle_host = shuffle_b<BDataType>(b_k_n_tensors[i]);

        a_m_k_dev_buf.push_back(std::make_unique<ck_tile::DeviceMem>(
            a_m_k_tensors[i].get_element_space_size_in_bytes()));
        b_shfl_dev_buf.push_back(
            std::make_unique<ck_tile::DeviceMem>(b_shuffle_host.get_element_space_size_in_bytes()));
        c_m_n_dev_buf.push_back(std::make_unique<ck_tile::DeviceMem>(
            c_m_n_tensors[i].get_element_space_size_in_bytes()));

        a_m_k_dev_buf[i]->ToDevice(a_m_k_tensors[i].data());
        b_shfl_dev_buf[i]->ToDevice(b_shuffle_host.data());
        c_m_n_tensors[i].SetZero();
        c_m_n_dev_buf[i]->SetZero();

        group_a_ptrs.push_back(a_m_k_dev_buf[i]->GetDeviceBuffer());
        group_b_ptrs.push_back(b_shfl_dev_buf[i]->GetDeviceBuffer());
        group_c_ptrs.push_back(c_m_n_dev_buf[i]->GetDeviceBuffer());
    }

    ck_tile::DeviceMem group_m_dev_buf(group_count * sizeof(ck_tile::index_t));
    ck_tile::DeviceMem group_n_dev_buf(group_count * sizeof(ck_tile::index_t));
    ck_tile::DeviceMem group_k_dev_buf(group_count * sizeof(ck_tile::index_t));
    ck_tile::DeviceMem group_a_ptrs_dev_buf(group_count * sizeof(void*));
    ck_tile::DeviceMem group_b_ptrs_dev_buf(group_count * sizeof(void*));
    ck_tile::DeviceMem group_c_ptrs_dev_buf(group_count * sizeof(void*));
    ck_tile::DeviceMem group_stride_a_dev_buf(group_count * sizeof(ck_tile::index_t));
    ck_tile::DeviceMem group_stride_b_dev_buf(group_count * sizeof(ck_tile::index_t));
    ck_tile::DeviceMem group_stride_c_dev_buf(group_count * sizeof(ck_tile::index_t));

    group_m_dev_buf.ToDevice(Ms.data());
    group_n_dev_buf.ToDevice(Ns.data());
    group_k_dev_buf.ToDevice(Ks.data());
    group_a_ptrs_dev_buf.ToDevice(group_a_ptrs.data());
    group_b_ptrs_dev_buf.ToDevice(group_b_ptrs.data());
    group_c_ptrs_dev_buf.ToDevice(group_c_ptrs.data());
    group_stride_a_dev_buf.ToDevice(stride_As.data());
    group_stride_b_dev_buf.ToDevice(stride_Bs.data());
    group_stride_c_dev_buf.ToDevice(stride_Cs.data());

    ck_tile::GroupedFlatmmHostArgs kernal_args{
        group_count,
        static_cast<ck_tile::index_t*>(group_m_dev_buf.GetDeviceBuffer()),
        static_cast<ck_tile::index_t*>(group_n_dev_buf.GetDeviceBuffer()),
        static_cast<ck_tile::index_t*>(group_k_dev_buf.GetDeviceBuffer()),
        static_cast<const void**>(group_a_ptrs_dev_buf.GetDeviceBuffer()),
        static_cast<ck_tile::index_t*>(group_stride_a_dev_buf.GetDeviceBuffer()),
        static_cast<const void**>(group_b_ptrs_dev_buf.GetDeviceBuffer()),
        static_cast<ck_tile::index_t*>(group_stride_b_dev_buf.GetDeviceBuffer()),
        static_cast<void**>(group_c_ptrs_dev_buf.GetDeviceBuffer()),
        static_cast<ck_tile::index_t*>(group_stride_c_dev_buf.GetDeviceBuffer()),
        kbatch,
    };

    invoke_gemm<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(
        warmup, repeat, kernal_args);

    for(int i = 0; i < group_count; i++)
    {
        c_m_n_dev_buf[i]->FromDevice(c_m_n_tensors[i].data());
    }

    bool pass{true};
    if(arg_parser.get_int("v") == 1)
    {
        for(int i = 0; i < group_count; ++i)
        {
            ck_tile::HostTensor<CDataType> c_m_n_host_ref(ck_tile::host_tensor_descriptor(
                Ms[i], Ns[i], stride_Cs[i], is_row_major(CLayout{})));
            c_m_n_host_ref.SetZero();
            ck_tile::reference_gemm<ADataType, BDataType, AccDataType, CDataType>(
                a_m_k_tensors[i], b_k_n_tensors[i], c_m_n_host_ref);
            const float max_accumulated_value =
                *std::max_element(c_m_n_host_ref.mData.begin(), c_m_n_host_ref.mData.end());
            const auto rtol_atol =
                calculate_rtol_atol<ADataType, BDataType, AccDataType, CDataType>(
                    Ks[i], 1 /*kbatch*/, max_accumulated_value);
            pass &= ck_tile::check_err(c_m_n_tensors[i],
                                       c_m_n_host_ref,
                                       "Error: Incorrect results!",
                                       rtol_atol.at(ck_tile::number<0>{}),
                                       rtol_atol.at(ck_tile::number<1>{}));
            std::cout << "gemm[" << i
                      << "] Relative error threshold: " << rtol_atol.at(ck_tile::number<0>{})
                      << " Absolute error threshold: " << rtol_atol.at(ck_tile::number<1>{})
                      << std::endl;
        }
        std::cout << "The CPU verification result is:" << (pass ? "correct" : "fail") << std::endl;
    }
    else if(arg_parser.get_int("v") == 2)
    {
        for(int i = 0; i < group_count; ++i)
        {
            ck_tile::index_t M        = Ms[i];
            ck_tile::index_t N        = Ns[i];
            ck_tile::index_t K        = Ks[i];
            ck_tile::index_t stride_A = stride_As[i];
            ck_tile::index_t stride_B = stride_Bs[i];
            ck_tile::index_t stride_C = stride_Cs[i];

            ADataType* d_A;
            BDataType* d_B;
            CDataType* d_C;

            ck_tile::hip_check_error(hipMalloc(&d_A, M * K * sizeof(ADataType)));
            ck_tile::hip_check_error(hipMalloc(&d_B, N * K * sizeof(BDataType)));
            ck_tile::hip_check_error(hipMalloc(&d_C, M * N * sizeof(CDataType)));

            ck_tile::hip_check_error(hipMemcpy(
                d_A, a_m_k_tensors[i].data(), M * K * sizeof(ADataType), hipMemcpyHostToDevice));
            ck_tile::hip_check_error(hipMemcpy(
                d_B, b_k_n_tensors[i].data(), N * K * sizeof(BDataType), hipMemcpyHostToDevice));

            ck_tile::reference_gemm_gpu<ADataType,
                                        BDataType,
                                        AccDataType,
                                        CDataType,
                                        ALayout,
                                        BLayout,
                                        CLayout>(
                d_A, d_B, d_C, M, N, K, stride_A, stride_B, stride_C);

            ck_tile::HostTensor<CDataType> c_gpu_ref_host(
                ck_tile::host_tensor_descriptor(M, N, stride_C, is_row_major(CLayout{})));
            ck_tile::hip_check_error(hipMemcpy(
                c_gpu_ref_host.data(), d_C, M * N * sizeof(CDataType), hipMemcpyDeviceToHost));

            ck_tile::hip_check_error(hipFree(d_A));
            ck_tile::hip_check_error(hipFree(d_B));
            ck_tile::hip_check_error(hipFree(d_C));

            const float max_accumulated_value =
                *std::max_element(c_gpu_ref_host.mData.begin(), c_gpu_ref_host.mData.end());
            const auto rtol_atol =
                calculate_rtol_atol<ADataType, BDataType, AccDataType, CDataType>(
                    K, kbatch, max_accumulated_value);

            float rtol = 1e-3;
            float atol = 1e-3;

            pass = ck_tile::check_err(
                c_m_n_tensors[i], c_gpu_ref_host, "Error: Incorrect results!", rtol, atol);

            std::cout << "gemm[" << i << "]\nRelative error threshold: " << rtol
                      << " Absolute error threshold: " << atol << std::endl;
            std::cout << "The GPU veification result is: " << (pass ? "correct" : "fail")
                      << std::endl;
        }
    }

    return pass;
}

template <typename PrecType, typename ALayout, typename BLayout, typename CLayout>
int run_contiguous_grouped_flatmm_example_with_layouts(
    int argc,
    char* argv[],
    const ALayout a_layout                  = ALayout{},
    const BLayout b_layout                  = BLayout{},
    [[maybe_unused]] const CLayout c_layout = CLayout{})
{
    auto [result, arg_parser] = create_args(argc, argv);

    if(!result)
    {
        return -1;
    };

    using ADataType   = typename GemmBasicTypeConfig<PrecType>::ADataType;
    using BDataType   = typename GemmBasicTypeConfig<PrecType>::BDataType;
    using CDataType   = typename GemmBasicTypeConfig<PrecType>::CDataType;
    using AccDataType = typename GemmBasicTypeConfig<PrecType>::AccDataType;

    constexpr int BlockM = GemmConfig<BDataType>::M_Tile;

    const int group_count = arg_parser.get_int("group_count");
    const int repeat      = arg_parser.get_int("repeat");
    const int warmup      = arg_parser.get_int("warmup");

    std::vector<ck_tile::index_t> Ms = arg_parser.get_int_vec("Ms");
    std::vector<ck_tile::index_t> Ns = arg_parser.get_int_vec("Ns");
    std::vector<ck_tile::index_t> Ks = arg_parser.get_int_vec("Ks");

    if(!(int(Ms.size()) == group_count))
    {
        std::cout << "Please check the input data." << std::endl;
        // padding additional Ms if needed
        for(int i = 0; i < group_count; i++)
        {
            Ms.push_back(256 + 64 * i);
        }
    }

    ck_tile::index_t M =
        std::reduce(Ms.begin(), Ms.begin() + group_count, 0, [](auto acc, auto group_m) {
            // round up to the multiple of BlockM
            return acc + (group_m + BlockM - 1) / BlockM * BlockM;
        });
    std::cout << "Total M: " << M << std::endl;
    ck_tile::index_t N = Ns[0];
    ck_tile::index_t K = Ks[0];

    ck_tile::index_t kbatch = arg_parser.get_int("split_k");

    ck_tile::index_t stride_A = 0;
    ck_tile::index_t stride_B = 0;
    ck_tile::index_t stride_C = 0;

    stride_A = ck_tile::get_default_stride(M, K, stride_A, is_row_major(a_layout));
    stride_B = ck_tile::get_default_stride(K, N * group_count, stride_B, is_row_major(b_layout));
    stride_C = ck_tile::get_default_stride(M, N, stride_C, is_row_major(c_layout));

    ck_tile::HostTensor<ADataType> a_m_k_tensor(
        ck_tile::host_tensor_descriptor(M, K, stride_A, is_row_major(a_layout)));
    ck_tile::HostTensor<BDataType> b_k_n_tensor(ck_tile::HostTensor<BDataType>(
        ck_tile::host_tensor_descriptor(K, N * group_count, stride_B, is_row_major(b_layout))));
    ck_tile::HostTensor<CDataType> c_m_n_tensor(ck_tile::HostTensor<CDataType>(
        ck_tile::host_tensor_descriptor(M, N, stride_C, is_row_major(c_layout))));

    std::vector<ck_tile::index_t> m_indices(M);
    int indices_fill_start = 0;
    for(int i = 0; i < group_count; ++i)
    {
        int group_m        = Ms[i];
        int padded_group_m = (group_m + BlockM - 1) / BlockM * BlockM;
        for(int j = 0; j < padded_group_m; j++)
        {
            m_indices[indices_fill_start + j] = j < group_m ? i : -1; // -1 for padding
        }
        indices_fill_start += padded_group_m;
    }

    ck_tile::FillUniformDistribution<ADataType>{-1.f, 1.f}(a_m_k_tensor);
    ck_tile::FillUniformDistribution<BDataType>{-.5f, .5f}(b_k_n_tensor);

    constexpr int N_Warp_Tile = GemmConfig<BDataType>::N_Warp_Tile;
    assert(N % N_Warp_Tile == 0 &&
           "N must be divisible by N_Warp_Tile for contiguous grouped gemm");
    ck_tile::HostTensor<BDataType> b_shuffle_host = shuffle_b<BDataType>(b_k_n_tensor);

    std::unique_ptr<ck_tile::DeviceMem> a_m_k_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(a_m_k_tensor.get_element_space_size_in_bytes()));
    std::unique_ptr<ck_tile::DeviceMem> b_shfl_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(b_shuffle_host.get_element_space_size_in_bytes()));
    std::unique_ptr<ck_tile::DeviceMem> c_m_n_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(c_m_n_tensor.get_element_space_size_in_bytes()));
    c_m_n_dev_buf->SetZero();

    ck_tile::DeviceMem m_indices_dev_buf(M * sizeof(ck_tile::index_t));
    m_indices_dev_buf.ToDevice(m_indices.data());

    a_m_k_dev_buf->ToDevice(a_m_k_tensor.data());
    b_shfl_dev_buf->ToDevice(b_shuffle_host.data());

    ck_tile::ContiguousGroupedFlatmmHostArgs kernal_args{
        static_cast<ck_tile::index_t*>(m_indices_dev_buf.GetDeviceBuffer()),
        M,
        N,
        K,
        a_m_k_dev_buf->GetDeviceBuffer(),
        stride_A,
        b_shfl_dev_buf->GetDeviceBuffer(),
        stride_B,
        c_m_n_dev_buf->GetDeviceBuffer(),
        stride_C,
        kbatch,
    };

    invoke_gemm<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(
        warmup, repeat, kernal_args);
    c_m_n_dev_buf->FromDevice(c_m_n_tensor.data());

    bool pass{true};
    if(arg_parser.get_int("v") == 1)
    {
        throw std::runtime_error(
            "Not support v=1 host verification in contiguous grouped gemm, use "
            "v=2 device verification instead");
    }
    else if(arg_parser.get_int("v") == 2)
    {
        BDataType* d_B;
        CDataType* d_C;
        ck_tile::hip_check_error(hipMalloc(&d_B, N * K * sizeof(BDataType)));
        ck_tile::hip_check_error(hipMalloc(&d_C, M * N * sizeof(CDataType)));
        ck_tile::hip_check_error(hipMemset(d_C, 0, M * N * sizeof(CDataType)));

        ck_tile::HostTensor<CDataType> c_gpu_ref_host(
            ck_tile::host_tensor_descriptor(M, N, stride_C, is_row_major(CLayout{})));

        ck_tile::index_t acc_m = 0;
        for(int i = 0; i < group_count; ++i)
        {
            ck_tile::index_t padded_M = (Ms[i] + BlockM - 1) / BlockM * BlockM;

            ck_tile::hip_check_error(hipMemcpy(d_B,
                                               b_k_n_tensor.data() + i * N * K,
                                               N * K * sizeof(BDataType),
                                               hipMemcpyHostToDevice));
            ck_tile::reference_gemm_gpu<ADataType,
                                        BDataType,
                                        AccDataType,
                                        CDataType,
                                        ALayout,
                                        BLayout,
                                        CLayout>(
                static_cast<ADataType*>(a_m_k_dev_buf->GetDeviceBuffer()) + acc_m * K,
                d_B,
                d_C + acc_m * N,
                padded_M,
                N,
                K,
                stride_A,
                stride_B,
                stride_C);
            acc_m += padded_M;
        }
        ck_tile::hip_check_error(hipMemcpy(
            c_gpu_ref_host.data(), d_C, M * N * sizeof(CDataType), hipMemcpyDeviceToHost));

        ck_tile::hip_check_error(hipFree(d_B));
        ck_tile::hip_check_error(hipFree(d_C));

        float rtol = 1e-3;
        float atol = 1e-3;

        pass = ck_tile::check_err(
            c_m_n_tensor, c_gpu_ref_host, "Error: Incorrect results!", rtol, atol);

        std::cout << "Relative error threshold: " << rtol << " Absolute error threshold: " << atol
                  << std::endl;
        std::cout << "The GPU veification result is: " << (pass ? "correct" : "fail") << std::endl;
    }

    return pass;
}

template <typename PrecType, typename ALayout, typename BLayout, typename CLayout>
int run_masked_grouped_flatmm_example_with_layouts(
    int argc,
    char* argv[],
    const ALayout a_layout                  = ALayout{},
    const BLayout b_layout                  = BLayout{},
    [[maybe_unused]] const CLayout c_layout = CLayout{})
{
    auto [result, arg_parser] = create_args(argc, argv);

    if(!result)
    {
        return -1;
    };

    using ADataType   = typename GemmBasicTypeConfig<PrecType>::ADataType;
    using BDataType   = typename GemmBasicTypeConfig<PrecType>::BDataType;
    using CDataType   = typename GemmBasicTypeConfig<PrecType>::CDataType;
    using AccDataType = typename GemmBasicTypeConfig<PrecType>::AccDataType;

    constexpr int BlockM = GemmConfig<BDataType>::M_Tile;

    const int group_count = arg_parser.get_int("group_count");
    const int repeat      = arg_parser.get_int("repeat");
    const int warmup      = arg_parser.get_int("warmup");

    std::vector<ck_tile::index_t> Ms = arg_parser.get_int_vec("Ms");
    std::vector<ck_tile::index_t> Ns = arg_parser.get_int_vec("Ns");
    std::vector<ck_tile::index_t> Ks = arg_parser.get_int_vec("Ks");

    if(!(int(Ms.size()) == group_count))
    {
        std::cout << "Please check the input data." << std::endl;
        // padding additional Ms if needed
        for(int i = 0; i < group_count; i++)
        {
            Ms.push_back(256 + 64 * i);
        }
    }

    ck_tile::index_t M = *(std::max_element(Ms.begin(), Ms.end()));
    ck_tile::index_t N = Ns[0];
    ck_tile::index_t K = Ks[0];

    ck_tile::index_t kbatch = arg_parser.get_int("split_k");

    ck_tile::index_t stride_A = K;
    ck_tile::index_t stride_B = K;
    ck_tile::index_t stride_C = N;

    stride_A = ck_tile::get_default_stride(group_count * M, K, stride_A, is_row_major(a_layout));
    stride_B = ck_tile::get_default_stride(K, N * group_count, stride_B, is_row_major(b_layout));
    stride_C = ck_tile::get_default_stride(group_count * M, N, stride_C, is_row_major(c_layout));

    ck_tile::HostTensor<ADataType> a_m_k_tensor(
        ck_tile::host_tensor_descriptor(group_count * M, K, stride_A, is_row_major(a_layout)));
    ck_tile::HostTensor<BDataType> b_k_n_tensor(ck_tile::HostTensor<BDataType>(
        ck_tile::host_tensor_descriptor(K, N * group_count, stride_B, is_row_major(b_layout))));
    ck_tile::HostTensor<CDataType> c_m_n_tensor(ck_tile::HostTensor<CDataType>(
        ck_tile::host_tensor_descriptor(group_count * M, N, stride_C, is_row_major(c_layout))));

    std::vector<ck_tile::index_t> m_indices(group_count);
    int indices_fill_start = 0;
    for(int i = 0; i < group_count; ++i)
    {
        int group_m        = Ms[i];
        int padded_group_m = (group_m + BlockM - 1) / BlockM * BlockM;
        for(int j = 0; j < padded_group_m; j++)
        {
            m_indices[i] = padded_group_m; // -1 for padding
        }
    }

    ck_tile::FillUniformDistribution<ADataType>{-1.f, 1.f}(a_m_k_tensor);
    ck_tile::FillUniformDistribution<BDataType>{-.5f, .5f}(b_k_n_tensor);

    constexpr int N_Warp_Tile = GemmConfig<BDataType>::N_Warp_Tile;
    assert(N % N_Warp_Tile == 0 &&
           "N must be divisible by N_Warp_Tile for contiguous grouped gemm");
    ck_tile::HostTensor<BDataType> b_shuffle_host = shuffle_b<BDataType>(b_k_n_tensor);

    std::unique_ptr<ck_tile::DeviceMem> a_m_k_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(a_m_k_tensor.get_element_space_size_in_bytes()));
    std::unique_ptr<ck_tile::DeviceMem> b_shfl_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(b_shuffle_host.get_element_space_size_in_bytes()));
    std::unique_ptr<ck_tile::DeviceMem> c_m_n_dev_buf(
        std::make_unique<ck_tile::DeviceMem>(c_m_n_tensor.get_element_space_size_in_bytes()));
    c_m_n_dev_buf->SetZero();

    ck_tile::DeviceMem m_indices_dev_buf(group_count * sizeof(ck_tile::index_t));
    m_indices_dev_buf.ToDevice(m_indices.data());

    a_m_k_dev_buf->ToDevice(a_m_k_tensor.data());
    b_shfl_dev_buf->ToDevice(b_shuffle_host.data());

    aiter::m_grouped_flatmm_ck(ck_tile::stream_config{nullptr, true, 1, warmup, repeat},
                               static_cast<int32_t*>(m_indices_dev_buf.GetDeviceBuffer()),
                               group_count,
                               M,
                               N,
                               K,
                               a_m_k_dev_buf->GetDeviceBuffer(),
                               b_shfl_dev_buf->GetDeviceBuffer(),
                               c_m_n_dev_buf->GetDeviceBuffer());

    // ck_tile::MaskedGroupedFlatmmHostArgs kernal_args{
    //     static_cast<ck_tile::index_t*>(m_indices_dev_buf.GetDeviceBuffer()),
    //     group_count,
    //     M,
    //     N,
    //     K,
    //     a_m_k_dev_buf->GetDeviceBuffer(),
    //     stride_A,
    //     b_shfl_dev_buf->GetDeviceBuffer(),
    //     stride_B,
    //     c_m_n_dev_buf->GetDeviceBuffer(),
    //     stride_C,
    //     kbatch,
    // };

    // invoke_gemm<ADataType, BDataType, AccDataType, CDataType, ALayout, BLayout, CLayout>(
    //     warmup, repeat, kernal_args);
    c_m_n_dev_buf->FromDevice(c_m_n_tensor.data());

    bool pass{true};
    if(arg_parser.get_int("v") == 1)
    {
        throw std::runtime_error(
            "Not support v=1 host verification in contiguous grouped gemm, use "
            "v=2 device verification instead");
    }
    else if(arg_parser.get_int("v") == 2)
    {
        BDataType* d_B;
        CDataType* d_C;
        ck_tile::hip_check_error(hipMalloc(&d_B, N * K * sizeof(BDataType)));
        ck_tile::hip_check_error(hipMalloc(&d_C, group_count * M * N * sizeof(CDataType)));
        ck_tile::hip_check_error(hipMemset(d_C, 0, group_count * M * N * sizeof(CDataType)));

        ck_tile::HostTensor<CDataType> c_gpu_ref_host(
            ck_tile::host_tensor_descriptor(group_count * M, N, stride_C, is_row_major(CLayout{})));
        ck_tile::index_t acc_m = 0;
        for(int i = 0; i < group_count; ++i)
        {
            ck_tile::hip_check_error(hipMemcpy(d_B,
                                               b_k_n_tensor.data() + i * N * K,
                                               N * K * sizeof(BDataType),
                                               hipMemcpyHostToDevice));
            ck_tile::reference_gemm_gpu<ADataType,
                                        BDataType,
                                        AccDataType,
                                        CDataType,
                                        ALayout,
                                        BLayout,
                                        CLayout>(
                static_cast<ADataType*>(a_m_k_dev_buf->GetDeviceBuffer()) + i * M * K,
                d_B,
                d_C + i * M * N,
                m_indices[i],
                N,
                K,
                stride_A,
                stride_B,
                stride_C);
            ck_tile::hip_check_error(hipMemcpy(c_gpu_ref_host.data() + i * M * N,
                                               d_C + i * M * N,
                                               M * N * sizeof(CDataType),
                                               hipMemcpyDeviceToHost));
        }

        ck_tile::hip_check_error(hipFree(d_B));
        ck_tile::hip_check_error(hipFree(d_C));

        const float max_accumulated_value =
            *std::max_element(c_gpu_ref_host.mData.begin(), c_gpu_ref_host.mData.end());
        const auto rtol_atol = calculate_rtol_atol<ADataType, BDataType, AccDataType, CDataType>(
            K, kbatch, max_accumulated_value);
        pass = ck_tile::check_err(c_m_n_tensor,
                                  c_gpu_ref_host,
                                  "Error: Incorrect results!",
                                  rtol_atol.at(ck_tile::number<0>{}),
                                  rtol_atol.at(ck_tile::number<1>{}));

        std::cout << "Relative error threshold: " << rtol_atol.at(ck_tile::number<0>{})
                  << " Absolute error threshold: " << rtol_atol.at(ck_tile::number<1>{})
                  << std::endl;
        std::cout << "The GPU veification result is: " << (pass ? "correct" : "fail") << std::endl;
    }

    return pass;
}

int run_grouped_flatmm_example(int argc, char* argv[])
{
    auto [result, arg_parser] = create_args(argc, argv);
    if(!result)
        return -1;

    using Row = ck_tile::tensor_layout::gemm::RowMajor;
    using Col = ck_tile::tensor_layout::gemm::ColumnMajor;

    std::string data_type = arg_parser.get_str("prec");
    std::string mode      = arg_parser.get_str("mode");
    std::string a_layout  = arg_parser.get_str("a_layout");
    std::string b_layout  = arg_parser.get_str("b_layout");

    if(a_layout == "R" && b_layout == "C")
    {
        run_masked_grouped_flatmm_example_with_layouts<ck_tile::bf16_t>(
            argc, argv, Row{}, Col{}, Row{});
    }
    else
    {
        throw std::runtime_error("Unsupported data layout configuration for A,B and C tensors!");
    }
    return -1;
}

int main(int argc, char* argv[]) { return !run_grouped_flatmm_example(argc, argv); }
