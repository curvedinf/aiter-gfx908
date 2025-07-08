// SPDX-License-Identifier: MIT
// Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

#pragma once

#include "ck_tile/core.hpp"

namespace ck_tile {

// "S"tream update output along "N"
// A in smem, B load from global
// require 4 wave, occupancy=1c
struct Fmla_m16x4_n16x1_Base
{
    static constexpr index_t Block_M  = 64;
    static constexpr index_t Block_N0 = 16;
    static constexpr index_t Block_K0 = 576;
    static constexpr index_t Block_N1 = 512;
    static constexpr index_t Block_K1 = 16;

    static constexpr index_t WarpPerBlock_M = 4;
    static constexpr index_t WarpPerBlock_N = 1;
    static constexpr index_t WarpPerBlock_K = 1;

    static constexpr index_t Warp_M0 = 16;
    static constexpr index_t Warp_N0 = 16;
    static constexpr index_t Warp_K0 = 32;

    static constexpr index_t Warp_M1 = 16;
    static constexpr index_t Warp_N1 = 16;
    static constexpr index_t Warp_K1 = 32;

    static constexpr index_t BlockSize = 256;

    // static constexpr index_t KPack = 2; // this is used to gurantee every threads can do dwordx4

    // TODO: note Nr/Kr/W need consider KPack
    static constexpr index_t Repeat_M0 = Block_M  / (Warp_M0 * WarpPerBlock_M); // 2
    static constexpr index_t Repeat_N0 = Block_N0 / (Warp_N0 * WarpPerBlock_N); // 2
    static constexpr index_t Repeat_K0 = Block_K0 / (Warp_K0 * WarpPerBlock_K); // 16

    // static CK_TILE_DEVICE constexpr auto MakeCBlockDist()
    // {
    //     constexpr auto c_block_outer_dstr_encoding = tile_distribution_encoding<
    //         sequence<>,
    //         tuple<sequence<Repeat_M, WarpPerBlock_M>, sequence<Repeat_N, WarpPerBlock_N>>,
    //         tuple<sequence<1, 2>>,
    //         tuple<sequence<1, 1>>,
    //         sequence<2, 1>, // !! note here is different
    //         sequence<0, 0>>{};
    //
    //     using WG = WarpGemmMfmaF16F16F32M16N16K32TransposedCDistribution;
    //
    //     constexpr auto c_block_dstr_encode = detail::make_embed_tile_distribution_encoding(
    //         c_block_outer_dstr_encoding, typename WG::CWarpDstrEncoding{});
    //     constexpr auto c_block_dstr = make_static_tile_distribution(c_block_dstr_encode);
    //     return c_block_dstr;
    // }

    // CK_TILE_HOST_DEVICE static constexpr ck_tile::index_t GetSmemSize()
    // {
    //     //                    y     y     p     p      p      y
    //     // reg before shfl  M0(2)*N0(2)*Nl(4)*Nw(4)*Mw(16)*Nv(4)
    //     // but order is N0*M0*Nv
    //     // in LDS we need store as
    //     //          M0(2)* N0(2) *  Nl(4) * Nw(4) * (Mw(16)*Nv(4) + 4)
    //     //             y    y       wave-id  lid/16  lid%16   v
    //     constexpr index_t nbufs = 2;
    //     return 2 * 2 * 4 * 4 * (16 * 4 + 4) * sizeof(bf16_t) * nbufs;
    // }
};

struct Fmla_m16x4_n16x1_Bf16: public Fmla_m16x4_n16x1_Base
{
    using scale_t = bf16_t;
    using acc_t   = bf16_t;
    using out_t   = bf16_t;

    // TODO: need paired with tile_window_linear!
    // TODO: need call init_raw() before call this function!
    // template <typename AWindow, typename BWindow, typename OWindow, typename ScaleTensor>
    CK_TILE_DEVICE auto
    operator()(scale_t* q_nope,
               scale_t* q_rope
               // ,
               // const int32_t k_nope_smem_begin, 
               // const int32_t k_rope_smem_begin,
               )
    {
        register float v_c0 asm("v64");
        register float v_c1 asm("v65");
        register float v_c2 asm("v66");
        register float v_c3 asm("v67");
        register float v_c4 asm("v68");
        register float v_c5 asm("v69");
        register float v_c6 asm("v70");
        register float v_c7 asm("v71");
        register float v_c8 asm("v72");
        register float v_c9 asm("v73");
        register float v_c10 asm("v74");
        register float v_c11 asm("v75");
        register float v_c12 asm("v76");
        register float v_c13 asm("v77");
        register float v_c14 asm("v78");
        register float v_c15 asm("v79");
        register float v_c16 asm("v80");
        register float v_c17 asm("v81");
        register float v_c18 asm("v82");
        register float v_c19 asm("v83");
        register float v_c20 asm("v84");
        register float v_c21 asm("v85");
        register float v_c22 asm("v86");
        register float v_c23 asm("v87");
        register float v_c24 asm("v88");
        register float v_c25 asm("v89");
        register float v_c26 asm("v90");
        register float v_c27 asm("v91");
        register float v_c28 asm("v92");
        register float v_c29 asm("v93");
        register float v_c30 asm("v94");
        register float v_c31 asm("v95");

        uint32_t* q_nope_reg = reinterpret_cast<uint32_t*>(q_nope);
        uint32_t* q_rope_reg = reinterpret_cast<uint32_t*>(q_rope);

        // smem layout:
        // k nope * 2:
        // (128 + 8) * 4
        int lane_id  = threadIdx.x % 64;
        int sld_y_os = (lane_id % 16) * 4 + (lane_id / 16) * 128;
        sld_y_os *= 2;

        // every threads need 8xK in contiguous register
        // ... and every wave need the same data
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winline-asm"
        asm volatile(
#include "fmla_gfx9_m16x4n16x1.inc"
            :

            :
            // [k_nope_0_smem_begin]"s"(k_nope_smem_begin),
            // [k_nope_1_smem_begin]"s"(k_nope_smem_begin),
            // [k_rope_0_smem_begin]"s"(k_rope_smem_begin),
            // [k_rope_1_smem_begin]"s"(k_rope_smem_begin),
            // [k_nope_smem_off]"v"(),
            // [k_rope_smem_off]"v"(),
            [q_reg_0]"v"(q_nope_reg[0]),
            [q_reg_1]"v"(q_nope_reg[1]),
            [q_reg_2]"v"(q_nope_reg[2]),
            [q_reg_3]"v"(q_nope_reg[3]),
            [q_reg_4]"v"(q_nope_reg[4]),
            [q_reg_5]"v"(q_nope_reg[5]),
            [q_reg_6]"v"(q_nope_reg[6]),
            [q_reg_7]"v"(q_nope_reg[7]),

            [q_reg_8]"v"(q_nope_reg[8]),
            [q_reg_9]"v"(q_nope_reg[9]),
            [q_reg_10]"v"(q_nope_reg[10]),
            [q_reg_11]"v"(q_nope_reg[11]),
            [q_reg_12]"v"(q_nope_reg[12]),
            [q_reg_13]"v"(q_nope_reg[13]),
            [q_reg_14]"v"(q_nope_reg[14]),
            [q_reg_15]"v"(q_nope_reg[15]),

            [q_reg_16]"v"(q_rope_reg[0]),
            [q_reg_17]"v"(q_rope_reg[1]),

            [q_reg_18]"v"(q_nope_reg[16]),
            [q_reg_19]"v"(q_nope_reg[17]),
            [q_reg_20]"v"(q_nope_reg[18]),
            [q_reg_21]"v"(q_nope_reg[19]),
            [q_reg_22]"v"(q_nope_reg[20]),
            [q_reg_23]"v"(q_nope_reg[21]),
            [q_reg_24]"v"(q_nope_reg[22]),
            [q_reg_25]"v"(q_nope_reg[23]),

            [q_reg_26]"v"(q_nope_reg[24]),
            [q_reg_27]"v"(q_nope_reg[25]),
            [q_reg_28]"v"(q_nope_reg[26]),
            [q_reg_29]"v"(q_nope_reg[27]),
            [q_reg_30]"v"(q_nope_reg[28]),
            [q_reg_31]"v"(q_nope_reg[29]),
            [q_reg_32]"v"(q_nope_reg[30]),
            [q_reg_33]"v"(q_nope_reg[31]),

            [q_reg_34]"v"(q_rope_reg[2]),
            [q_reg_35]"v"(q_rope_reg[3]),

            [q_reg_36]"v"(q_nope_reg[32]),
            [q_reg_37]"v"(q_nope_reg[33]),
            [q_reg_38]"v"(q_nope_reg[34]),
            [q_reg_39]"v"(q_nope_reg[35]),
            [q_reg_40]"v"(q_nope_reg[36]),
            [q_reg_41]"v"(q_nope_reg[37]),
            [q_reg_42]"v"(q_nope_reg[38]),
            [q_reg_43]"v"(q_nope_reg[39]),


            [q_reg_44]"v"(q_nope_reg[40]),
            [q_reg_45]"v"(q_nope_reg[41]),
            [q_reg_46]"v"(q_nope_reg[42]),
            [q_reg_47]"v"(q_nope_reg[43]),
            [q_reg_48]"v"(q_nope_reg[44]),
            [q_reg_49]"v"(q_nope_reg[45]),
            [q_reg_50]"v"(q_nope_reg[46]),
            [q_reg_51]"v"(q_nope_reg[47]),

            [q_reg_52]"v"(q_rope_reg[4]),
            [q_reg_53]"v"(q_rope_reg[5]),

            [q_reg_54]"v"(q_nope_reg[48]),
            [q_reg_55]"v"(q_nope_reg[49]),
            [q_reg_56]"v"(q_nope_reg[50]),
            [q_reg_57]"v"(q_nope_reg[51]),
            [q_reg_58]"v"(q_nope_reg[52]),
            [q_reg_59]"v"(q_nope_reg[53]),
            [q_reg_60]"v"(q_nope_reg[54]),
            [q_reg_61]"v"(q_nope_reg[55]),

            [q_reg_62]"v"(q_nope_reg[56]),
            [q_reg_63]"v"(q_nope_reg[57]),
            [q_reg_64]"v"(q_nope_reg[58]),
            [q_reg_65]"v"(q_nope_reg[59]),
            [q_reg_66]"v"(q_nope_reg[60]),
            [q_reg_67]"v"(q_nope_reg[61]),
            [q_reg_68]"v"(q_nope_reg[62]),
            [q_reg_69]"v"(q_nope_reg[63]),

            [q_reg_70]"v"(q_rope_reg[6]),
            [q_reg_71]"v"(q_rope_reg[7])
        );
#pragma clang diagnostic pop
        // clang-format on
    }
};

struct __attribute__((packed)) ptr_resource
{
    const void* ptr;
};

CK_TILE_DEVICE auto make_wave_ptr_resource(const void* ptr)
{
    ptr_resource res{ptr};
    ck_tile::int32x2_t r = __builtin_bit_cast(ck_tile::int32x2_t, res);
    r.x         = __builtin_amdgcn_readfirstlane(r.x);
    r.y         = __builtin_amdgcn_readfirstlane(r.y);
    return r;
}

struct Fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1_total
{
    using scale_t = bf16_t;
    using acc_t   = bf16_t;
    using out_t   = bf16_t;

    template <typename QRes,
              typename KVRes,
              typename ORes,
              typename LseRes,
              typename KVIndicesRes
              >
    CK_TILE_DEVICE auto
    operator()(QRes&   q_ptr,
               KVRes&  kv_ptr,
               ORes&   o_ptr,
               LseRes& lse_ptr,
               KVIndicesRes& kv_indices,
               int32_t* kv_indptr,
               float s_scalar,
               int32_t s_head_num_q,
               int32_t kv_splits,
               int32_t stride_q_b,
               int32_t page_block_size,
               int32_t s_log2_plen,
               int32_t* qo_ptr,
               CK_TILE_LDS_ADDR void* smem
               )
    {
        auto res_kv_indptr  = make_wave_ptr_resource(kv_indptr);
        auto res_qo         = make_wave_ptr_resource(qo_ptr);

        register float s64 asm("s64") = s_scalar;
        register int s65 asm("s65") = s_head_num_q;
        register int s67 asm("s67") = kv_splits;
        register int s66 asm("s66") = stride_q_b;
        register int s68 asm("s68") = page_block_size;
        register int s69 asm("s69") = s_log2_plen;


        register int s32 asm("s32") = res_qo[0];
        register int s33 asm("s33") = res_qo[1];

        register int s28 asm("s28") = res_kv_indptr[0];
        register int s29 asm("s29") = res_kv_indptr[1];

        register int s24 asm("s24") = kv_indices[0];
        register int s25 asm("s25") = kv_indices[1];
        register int s26 asm("s26") = kv_indices[2];
        register int s27 asm("s27") = kv_indices[3];

        register int s20 asm("s20") = kv_ptr[0];
        register int s21 asm("s21") = kv_ptr[1];
        register int s22 asm("s22") = kv_ptr[2];
        register int s23 asm("s23") = kv_ptr[3];

        // True-------------------------------
        register int s16 asm("s16") = q_ptr[0];
        register int s17 asm("s17") = q_ptr[1];
        register int s18 asm("s18") = q_ptr[2];
        register int s19 asm("s19") = q_ptr[3];

        register int s12 asm("s12") = lse_ptr[0];
        register int s13 asm("s13") = lse_ptr[1];
        register int s14 asm("s14") = lse_ptr[2];
        register int s15 asm("s15") = lse_ptr[3];
        // True-------------------------------

        register int s8 asm("s8") = o_ptr[0];
        register int s9 asm("s9") = o_ptr[1];
        register int s10 asm("s10") = o_ptr[2];
        register int s11 asm("s11") = o_ptr[3];

        register int s2 asm("s2") = blockIdx.x;
        register int s3 asm("s3") = blockIdx.y;
        register int s4 asm("s4") = blockIdx.z;

        register int v0 asm("v0") = threadIdx.x;

        register int  s_c0 asm("v64") = 0;
        register int  s_c1 asm("v65") = 1;
        register int  s_c2 asm("v66") = 2;
        register int  s_c3 asm("v67") = 3;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winline-asm"
        asm volatile(
#include "fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1_total.inc"
            :
            [smem_]"+r"(smem),
             [s_80]"=v"(s_c0),
             [s_81]"=v"(s_c1),
             [s_50]"=v"(s_c2),
             [s_45]"=v"(s_c3),

            [kv_indptr_res_0]"+s"(s28),
            [kv_indptr_res_1]"+s"(s29),
            [qo_res_0]"+s"(s32),
            [qo_res_1]"+s"(s33),

            [q_res_0]"+s"(s16),
            [q_res_1]"+s"(s17),
            [q_res_2]"+s"(s18),
            [kv_res_0]"+s"(s20),
            [kv_res_1]"+s"(s21),
            [kv_res_2]"+s"(s22),
            [o_res_0]"+s"(s8),
            [o_res_1]"+s"(s9),
            [o_res_2]"+s"(s10),
            [lse_res_0]"+s"(s12),
            [lse_res_1]"+s"(s13),
            [lse_res_2]"+s"(s14),
            [kv_indices_res_0]"+s"(s24),
            [kv_indices_res_1]"+s"(s25),
            [kv_indices_res_2]"+s"(s26),

            [lse_res_3]"+s"(s15),
            [q_res_3]"+s"(s19),
            [kv_res_3]"+s"(s23),
            [o_res_3]"+s"(s11),
            [kv_indices_res_3]"+s"(s27),

            [threadIdxx]"+s"(v0),

            [blockIdxx]"+s"(s2),
            [blockIdxy]"+s"(s3),
            [blockIdxz]"+s"(s4)


            :
            [s_scalar]"s"(s64),
            [s_head_num_q]"s"(s65),
            [s_kv_splits]"s"(s67),
            [s_stride_q_b]"s"(s66), //bytes
            [s_page_block_size]"s"(s68),
            [s_log2_plen]"s"(s69)

            // [s_scalar]"s"(s_scalar)
            // [s_head_num_q]"s"(s_head_num_q),
            // [s_kv_splits]"s"(kv_splits),
            // [s_stride_q_b]"s"(stride_q_b) //bytes
            // [s_page_block_size]"s"(page_block_size),
            // [s_log2_plen]"s"(s_log2_plen)
            :
          "memory", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9",
          "a10", "a11", "a12", "a13", "a14", "a15", "a16", "a17", "a18", "a19",
          "a20", "a21", "a22", "a23", "a24", "a25", "a26", "a27", "a28", "a29",
          "a30", "a31", "a32", "a33", "a34", "a35", "a36", "a37", "a38", "a39",
          "a40", "a41", "a42", "a43", "a44", "a45", "a46", "a47", "a48", "a49",
          "a50", "a51", "a52", "a53", "a54", "a55", "a56", "a57", "a58", "a59",
          "a60", "a61", "a62", "a63", "a64", "a65", "a66", "a67", "a68", "a69",
          "a70", "a71", "a72", "a73", "a74", "a75", "a76", "a77", "a78", "a79",
          "a80", "a81", "a82", "a83", "a84", "a85", "a86", "a87", "a88", "a89",
          "a90", "a91", "a92", "a93", "a94", "a95", "a96", "a97", "a98", "a99",
          "a100", "a101", "a102", "a103", "a104", "a105", "a106", "a107",
          "a108", "a109", "a110", "a111", "a112", "a113", "a114", "a115",
          "a116", "a117", "a118", "a119", "a120", "a121", "a122", "a123",
          "a124", "a125", "a126", "a127", "a128", "a129", "a130", "a131",
          "a132", "a133", "a134", "a135", "a136", "a137", "a138", "a139",
          "a140", "a141", "a142", "a143", "a144", "a145", "a146", "a147",
          "a148", "a149", "a150", "a151", "a152", "a153", "a154", "a155",
          "a156", "a157", "a158", "a159", "a160", "a161", "a162", "a163",
          "a164", "a165", "a166", "a167", "a168", "a169", "a170", "a171",
          "a172", "a173", "a174", "a175", "a176", "a177", "a178", "a179",
          "a180", "a181", "a182", "a183", "a184", "a185", "a186", "a187",
          "a188", "a189", "a190", "a191", "a192", "a193", "a194", "a195",
          "a196", "a197", "a198", "a199", "a200", "a201", "a202", "a203",
          "a204", "a205", "a206", "a207", "a208", "a209", "a210", "a211",
          "a212", "a213", "a214", "a215", "a216", "a217", "a218", "a219",
          "a220", "a221", "a222", "a223", "a224", "a225", "a226", "a227",
          "a228", "a229", "a230", "a231", "a232", "a233", "a234", "a235",
          "a236", "a237", "a238", "a239", "a240", "a241", "a242", "a243",
          "a244", "a245", "a246", "a247", "a248", "a249", "a250", "a251",
          "a252", "a253", "a254", "a255", 
          "s1", "s6",

          "s34", "s35", "s36", "s37", "s38", "s39",
          "s45", "s46", "s47",
          "s50", "s52", "s53", "s56", "s57", "s58",
          "s67", "s69",
          "s70", "s71", "s73", "s74", "s75", "s78", "s79",
          "s82", "s83", "s84",

          "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v9",
          "v10", "v11", "v12", "v13", "v14", "v15", "v16", "v17", "v18", "v19",
          "v20", "v21", "v22", "v23", "v24", "v25", "v26", "v27", "v28", "v29",
          "v30", "v31", "v32", "v33", "v34", "v35", "v36", "v37", "v38", "v39",
          "v40", "v41", "v42", "v43", "v44", "v45", "v46", "v47", "v48", "v49",
          "v50", "v51", "v52", "v53", "v54", "v55", "v56", "v57", "v58", "v59",
          "v60", "v61", "v62", "v63", 
          "v64","v65","v66","v67","v68","v69","v70","v71",
          "v72","v73","v74","v75","v76","v77","v78","v79",
          "v80","v81","v82","v83","v84","v85","v86","v87",
          "v88","v89","v90","v91","v92","v93","v94","v95",
          "v128", "v129", "v130", "v131",
          "v132", "v133", "v134", "v135", "v136", "v137", "v138", "v139",
          "v140", "v141", "v142", "v143", "v144", "v145", "v146", "v147",
          "v148", "v149", "v150", "v151", "v152", "v153", "v154", "v155",
          "v156", "v157", "v158", "v159", "v160", "v161", "v162", "v163",
          "v164", "v165", "v166", "v167", "v168", "v169", "v170", "v171",
          "v172", "v173", "v174", "v175", "v176", "v177", "v178", "v179",
          "v180", "v181", "v182", "v183", "v184", "v185", "v186", "v187",
          "v188", "v189", "v190", "v191", "v192", "v193", "v194", "v195",
          "v196", "v197", "v198", "v199", "v200", "v201", "v202", "v203",
          "v204", "v205", "v206", "v207", "v208", "v209", "v210", "v211",
          "v212", "v213", "v214", "v215", "v216", "v217", "v218", "v219",
          "v220", "v221", "v222", "v223", "v224", "v225", "v226", "v227",
          "v228", "v229", "v230", "v231", "v232", "v233", "v234", "v235",
          "v236", "v237", "v238", "v239", "v240", "v241", "v242", "v243",
          "v244", "v245", "v246", "v247", "v248", "v249", "v250", "v251",
          "v252", "v253", "v254", "v255"
        );
#pragma clang diagnostic pop
        // clang-format on
        //

		// [q_res_0]"s"(q_ptr[0]),
		// [q_res_1]"s"(q_ptr[1]),
		// [q_res_2]"s"(q_ptr[2]),
		// [q_res_3]"s"(q_ptr[3]),
		// [kv_res_0]"s"(kv_ptr[0]),
		// [kv_res_1]"s"(kv_ptr[1]),
		// [kv_res_2]"s"(kv_ptr[2]),
		// [kv_res_3]"s"(kv_ptr[3]),
		// [o_res_0]"s"(o_ptr[0]),
		// [o_res_1]"s"(o_ptr[1]),
		// [o_res_2]"s"(o_ptr[2]),
		// [o_res_3]"s"(o_ptr[3]),
		// [lse_res_0]"s"(lse_ptr[0]),
		// [lse_res_1]"s"(lse_ptr[1]),
		// [lse_res_2]"s"(lse_ptr[2]),
		// [lse_res_3]"s"(lse_ptr[3]),
		// [kv_indptr_res_0]"s"(res_kv_indptr[0]),
		// [kv_indptr_res_1]"s"(res_kv_indptr[1]),
		// [kv_indices_res_0]"s"(kv_indices[0]),
		// [kv_indices_res_1]"s"(kv_indices[1]),
		// [kv_indices_res_2]"s"(kv_indices[2]),
		// [kv_indices_res_3]"s"(kv_indices[3]),
		// [qo_res_0]"s"(res_qo[0]),
		// [qo_res_1]"s"(res_qo[1]),
    }
};

} // namespace ck_tile

