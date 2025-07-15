// SPDX-License-Identifier: MIT
// Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

#pragma once

#include "ck_tile/core.hpp"
#include "aiter_hip_common.h"
#include "macro_utils.hpp"


#define numsplit5

#define VGPR2SHUFFLE(n_s, n_v)  shuffle##n_s = v##n_v
#define SUFFFLE2LDS(n_lds, n_s) o_lds_ptr[n_lds] = shuffle##n_s
#define LDS2VGPR(n_v, n_lds)    v##n_v = o_lds_ptr[n_lds]
#define VGPR2DRAM(n_dram, n_v)  p_output[n_dram] = v##n_v


#define B16_VGPR_2_SHUFFLEX(n_s, n_v)  (shuffle##n_s).x = float_to_bf16(v##n_v);



#define VGPR2SHUFFLE(n_s, n_v)   \
asm volatile (                   \
        "v_mov_b32 %0, %1 \n"      \
        : "=v"(shuffle##n_s)     \
        : "v"(v##n_v)            \
        );         

#define VGPR_F32_2_B16(n_target, n_s0, n_s1)   \
asm volatile (                  \
  "v_cmp_u_f32   s[38:39], %1, %1 \n"           \
  "v_add3_u32    v28, %1, v31, 1 \n"           \
  "v_cndmask_b32  v20, v28, v30, s[38:39] \n"   \
  "v_cmp_u_f32   s[38:39], %2, %2 \n"           \
  "v_add3_u32    v28, %2, v31, 1 \n"           \
  "v_cndmask_b32  v21, v28, v30, s[38:39] \n"    \
  "v_perm_b32    %0, v21, v20, %3 \n"  \
  : "=v"(shuffle##n_target)                                \
  : "v"(shuffle##n_s0),                           \
    "v"(shuffle##n_s1),                           \
    "s"(s_perm)                            \
  : "v20", "v21", "v28", "v30", "v31", "s38", "s39"                      \
  );

// #define B16_VGPR_2_SHUFFLE(n_s, n_v)  (shuffle##n_s).y = float_to_bf16(v##n_v);


#define F32_SUFFFLEY_2_LDS_LOOP(n_lds)  \ 
        o_lds_ptr[n_lds]     = shuffle0;  \
        o_lds_ptr[n_lds + 1] = shuffle1;  \
        o_lds_ptr[n_lds + 2] = shuffle2;  \
        o_lds_ptr[n_lds + 3] = shuffle3;

#define F32_LDS_2_VGPR_LOOP_STRIDE1(func, lds_st_base) \
        F32_LDS_2_VGPR_LOOP_STRIDE1_0_0_0(func, lds_st_base)
#define F32_VGPR_2_DRAM_LOOP_STRIDE1(func, dram_st_base) \
        F32_VGPR_2_DRAM_LOOP_STRIDE1_0_0_0(func, dram_st_base)

        

#define LOOP_STRIDE4_TAIL(...) \

#define LOOP_STRIDE4(n_v_begin, func0, func1, ...) \
        LOOP_STRIDE4_##n_v_begin(func0); \
        func1(__VA_ARGS__);


#define LOOP_STRIDE1(n_v_begin, fuc) \
        LOOP_STRIDE1_##n_v_begin(n_v_begin, fuc, ...);


#define B16_SUFFFLEY_2_LDS_LOOP(n_lds)  \ 
    VGPR_F32_2_B16(0, 0, 1)        \
    VGPR_F32_2_B16(1, 2, 3)        \
    o_lds_ptr[n_lds]     = shuffle0;  \
    o_lds_ptr[n_lds + 1] = shuffle1;



// #define OFFSET_B16_LDS_2_VGPR_LDS(r, i, j)  (r * 576 + i * 288 + j + (j / 2) * 16)
// #define OFFSET_B16_LDS_2_VGPR_VGPR(r, i, j) (r * 8 + i * 2 + j + (j / 2) * 4)
//
// #define OFFSET_B16_VGPR_2_DRAM_VGPR(r, i, j) (r * 4 + i * 8 + j)
// #define OFFSET_B16_VGPR_2_DRAM_DRAM(r, i, j) (r * 2048 + i * 32 + j)



#define B16_VGPR_2_DRAM_LOOP_STRIDE1(func, ptr_base) \
    B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_0(func, ptr_base)

#define B16_LDS_2_VGPR_LOOP_STRIDE1(func, ptr_base) \
    B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_0(func, ptr_base)

#define LDS_2_VGPR(n_v, n_lds)     arr[n_v] = o_lds_ptr[n_lds];

#define VGPR_2_DRAM(n_v, n_dram)   p_output[n_dram] = arr[n_v];


namespace ck_tile {

struct FlashMlaPrefillFwdParams
{
    void* __restrict__ p_output;

    int32_t* __restrict__ p_seqlens_k;      // [b]
    int32_t* __restrict__ p_block_table;    // [b, max_seqlen_pad // block_size]
    int32_t* __restrict__ p_qo_indptr;      // [b]
    
    void* __restrict__ p_query;
    void* __restrict__ p_key;
    void* __restrict__ p_value;
    void* __restrict__ p_softmax_lse;
    void* __restrict__ p_softmax_lseaccum;
    void* __restrict__ p_output_accum;
#ifdef ZZDebug
    void* __restrict__ p_debug_m;
    void* __restrict__ p_debug_value;
    void* __restrict__ p_debug_p;
    void* __restrict__ p_debug_output;
    void* __restrict__ p_debug_q;
#endif

    int32_t size_b;         // batch count
    int32_t size_s;         // seqlen of q
    int32_t size_h;         // head count of q
    int32_t hq_hk_ratio;    // head count of q / head count of kv
    int32_t num_splits;
    int64_t block_table_batch_stride;
    int32_t num_page_blocks;
    int32_t page_block_size;
    float   scale_softmax;
    int32_t mask_y_ratio;

    // Use int64_t if there is int32 overflow case. For now, just use int32 to save sgpr and prevent using
    // spill table.
    using index_t = int32_t;

    index_t stride_b_q;         // stride in batch of query
    index_t stride_s_q;         //    ... in sequence ...
    index_t stride_h_q;         //    ... in head ...
    index_t stride_b_k;         // stride in batch of key
    index_t stride_s_k;         //    ... in sequence ...
    index_t stride_h_k;         //    ... in head ...
    index_t stride_b_v;         // stride in batch of value
    index_t stride_s_v;         //    ... in sequence ...
    index_t stride_h_v;         //    ... in head ...
    index_t stride_b_o;         // stride in batch of output
    index_t stride_s_o;         //    ... in sequence ...
    index_t stride_h_o;         //    ... in head ...
    index_t stride_b_lseacc;
    index_t stride_h_lseacc;
    index_t stride_sp_lseacc;   //    ... in split ...
    index_t stride_b_oacc;
    index_t stride_h_oacc;
    index_t stride_sp_oacc;     //    ... in split ...
    index_t stride_s_oacc;
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
#include "fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1.inc"
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


__device__ void
llvm_amdgcn_raw_buffer_load_lds(int32x4_t rsrc,
                                __attribute__((address_space(3))) uint32_t* lds_ptr,
                                index_t size,
                                index_t voffset,
                                index_t soffset,
                                index_t offset,
                                index_t aux) __asm("llvm.amdgcn.raw.buffer.load.lds");

struct Fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1_total
{
    using scale_t = bf16_t;
    using acc_t   = bf16_t;
    using out_t   = bf16_t;

    // template <typename QRes,
    //           typename KVRes,
    //           typename ORes,
    //           typename LseRes,
    //           typename KVIndicesRes
    //           // typename ORegsType
    //           >
    CK_TILE_DEVICE auto
    operator()(const FlashMlaPrefillFwdParams &params,
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
		auto o_lds_ptr   = reinterpret_cast<uint32_t*>(smem);

		auto o_bf16_lds_ptr   = reinterpret_cast<bf16_t*>(smem);

		auto res_kv_indptr  = make_wave_ptr_resource(kv_indptr);
		auto res_qo         = make_wave_ptr_resource(qo_ptr);

		float s_scalar_1 = 0.f;
		bf16_t* q_nope_ptr = reinterpret_cast<bf16_t*>(params.p_query) + blockIdx.y * 576 * 3 * 16;
		bf16_t* q_rope_ptr = q_nope_ptr + 512;

		auto q_nope_src = ck_tile::make_wave_buffer_resource(reinterpret_cast<void*>(q_nope_ptr), 64 * 576 * 2 * 32 * 3);
		auto q_rope_src = ck_tile::make_wave_buffer_resource(reinterpret_cast<void*>(q_rope_ptr), 64 * 576 * 2 * 32 * 3);


		auto q_ptr      = ck_tile::make_wave_buffer_resource(params.p_query);
		auto kv_ptr     = ck_tile::make_wave_buffer_resource(params.p_key);
		auto o_ptr      = ck_tile::make_wave_buffer_resource(params.p_output);
		auto lse_ptr    = ck_tile::make_wave_buffer_resource(params.p_softmax_lse);
		auto kv_indices = ck_tile::make_wave_buffer_resource(params.p_block_table);


		register int wave_id asm("s7") = __builtin_amdgcn_readfirstlane(threadIdx.x / get_warp_size());
		register int vthread asm("v0") = int(threadIdx.x & 63);


		int32_t offset = int(vthread << 2) + wave_id * 1152;
		int32_t smem_offset = wave_id * 5152; //+ r * 20608 + i * 1280

#pragma unroll
		for (int r = 0; r < 3; ++r)
		{
#pragma unroll
			for (int i = 0; i < 4; ++i) {
				__attribute__((address_space(3))) uint32_t* lds_ptr =
					reinterpret_cast<__attribute__((address_space(3))) uint32_t*>(
						reinterpret_cast<size_t>(
							reinterpret_cast<uint8_t*>(smem) + smem_offset + i * 1280));

				ck_tile::static_for<0, 4, 1>{}([&](auto k_repeat){
					llvm_amdgcn_raw_buffer_load_lds(q_nope_src, lds_ptr, 4, offset + i * 4608, 0, k_repeat * 256, 0);
				});

				llvm_amdgcn_raw_buffer_load_lds(q_rope_src, lds_ptr + 256, 4, offset + i * 4608, 0, 0, 0);
				// offset      += 4608;
			}
			offset      += 18432;
			smem_offset += 20608;
		}


		auto p_output = reinterpret_cast<uint32_t*>(params.p_output);
		auto p_lse    = reinterpret_cast<uint32_t*>(params.p_softmax_lse);

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


		// register int vthread asm("v0") = threadIdx.x;

		register uint32_t v_lse asm("v172");

		register uint32_t v0 asm("v40");
		register uint32_t v1 asm("v41");
		register uint32_t v2 asm("v42");
		register uint32_t v3 asm("v43");
		register uint32_t v4 asm("v44");
		register uint32_t v5 asm("v45");
		register uint32_t v6 asm("v46");
		register uint32_t v7 asm("v47");
		register uint32_t v8 asm("v48");
		register uint32_t v9 asm("v49");

		register uint32_t v10 asm("v50");
		register uint32_t v11 asm("v51");
		register uint32_t v12 asm("v52");
		register uint32_t v13 asm("v53");
		register uint32_t v14 asm("v54");
		register uint32_t v15 asm("v55");
		register uint32_t v16 asm("v56");
		register uint32_t v17 asm("v57");
		register uint32_t v18 asm("v58");
		register uint32_t v19 asm("v59");

		register uint32_t v20 asm("v60");
		register uint32_t v21 asm("v61");
		register uint32_t v22 asm("v62");
		register uint32_t v23 asm("v63");
		register uint32_t v24 asm("v64");
		register uint32_t v25 asm("v65");
		register uint32_t v26 asm("v66");
		register uint32_t v27 asm("v67");
		register uint32_t v28 asm("v68");
		register uint32_t v29 asm("v69");

		register uint32_t v30 asm("v70");
		register uint32_t v31 asm("v71");
		register uint32_t v32 asm("v72");
		register uint32_t v33 asm("v73");
		register uint32_t v34 asm("v74");
		register uint32_t v35 asm("v75");
		register uint32_t v36 asm("v76");
		register uint32_t v37 asm("v77");
		register uint32_t v38 asm("v78");
		register uint32_t v39 asm("v79");

		register uint32_t v40 asm("v80");
		register uint32_t v41 asm("v81");
		register uint32_t v42 asm("v82");
		register uint32_t v43 asm("v83");
		register uint32_t v44 asm("v84");
		register uint32_t v45 asm("v85");
		register uint32_t v46 asm("v86");
		register uint32_t v47 asm("v87");
		register uint32_t v48 asm("v88");
		register uint32_t v49 asm("v89");

		register uint32_t v50 asm("v90");
		register uint32_t v51 asm("v91");
		register uint32_t v52 asm("v92");
		register uint32_t v53 asm("v93");
		register uint32_t v54 asm("v94");
		register uint32_t v55 asm("v95");
		register uint32_t v56 asm("v96");
		register uint32_t v57 asm("v97");
		register uint32_t v58 asm("v98");
		register uint32_t v59 asm("v99");

		register uint32_t v60 asm("v100");
		register uint32_t v61 asm("v101");
		register uint32_t v62 asm("v102");
		register uint32_t v63 asm("v103");
		register uint32_t v64 asm("v104");
		register uint32_t v65 asm("v105");
		register uint32_t v66 asm("v106");
		register uint32_t v67 asm("v107");
		register uint32_t v68 asm("v108");
		register uint32_t v69 asm("v109");

		register uint32_t v70 asm("v110");
		register uint32_t v71 asm("v111");
		register uint32_t v72 asm("v112");
		register uint32_t v73 asm("v113");
		register uint32_t v74 asm("v114");
		register uint32_t v75 asm("v115");
		register uint32_t v76 asm("v116");
		register uint32_t v77 asm("v117");
		register uint32_t v78 asm("v118");
		register uint32_t v79 asm("v119");

		register uint32_t v80 asm("v120");
		register uint32_t v81 asm("v121");
		register uint32_t v82 asm("v122");
		register uint32_t v83 asm("v123");
		register uint32_t v84 asm("v124");
		register uint32_t v85 asm("v125");
		register uint32_t v86 asm("v126");
		register uint32_t v87 asm("v127");
		register uint32_t v88 asm("v128");
		register uint32_t v89 asm("v129");

		register uint32_t v90 asm("v130");
		register uint32_t v91 asm("v131");
		register uint32_t v92 asm("v132");
		register uint32_t v93 asm("v133");
		register uint32_t v94 asm("v134");
		register uint32_t v95 asm("v135");
		register uint32_t v96 asm("v136");
		register uint32_t v97 asm("v137");
		register uint32_t v98 asm("v138");
		register uint32_t v99 asm("v139");

		register uint32_t v100 asm("v140");
		register uint32_t v101 asm("v141");
		register uint32_t v102 asm("v142");
		register uint32_t v103 asm("v143");
		register uint32_t v104 asm("v144");
		register uint32_t v105 asm("v145");
		register uint32_t v106 asm("v146");
		register uint32_t v107 asm("v147");
		register uint32_t v108 asm("v148");
		register uint32_t v109 asm("v149");

		register uint32_t v110 asm("v150");
		register uint32_t v111 asm("v151");
		register uint32_t v112 asm("v152");
		register uint32_t v113 asm("v153");
		register uint32_t v114 asm("v154");
		register uint32_t v115 asm("v155");
		register uint32_t v116 asm("v156");
		register uint32_t v117 asm("v157");
		register uint32_t v118 asm("v158");
		register uint32_t v119 asm("v159");

		register uint32_t v120 asm("v160");
		register uint32_t v121 asm("v161");
		register uint32_t v122 asm("v162");
		register uint32_t v123 asm("v163");
		register uint32_t v124 asm("v164");
		register uint32_t v125 asm("v165");
		register uint32_t v126 asm("v166");
		register uint32_t v127 asm("v167");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winline-asm"
		asm volatile(
#include "fmla_gfx9_a16w16_qh16_m16x4_n16x1_coex0_mask1_total_w.inc"
			:
			 [smem_]"+r"(smem),

			 [lse_result]"=v"(v_lse),

			 [o_regs_0]"+v"(v0),
			 [o_regs_1]"+v"(v1),
			 [o_regs_2]"+v"(v2),
			 [o_regs_3]"+v"(v3),
			 [o_regs_4]"+v"(v4),
			 [o_regs_5]"+v"(v5),
			 [o_regs_6]"+v"(v6),
			 [o_regs_7]"+v"(v7),
			 [o_regs_8]"+v"(v8),
			 [o_regs_9]"+v"(v9),

			 [o_regs_10]"+v"(v10),
			 [o_regs_11]"+v"(v11),
			 [o_regs_12]"+v"(v12),
			 [o_regs_13]"+v"(v13),
			 [o_regs_14]"+v"(v14),
			 [o_regs_15]"+v"(v15),
			 [o_regs_16]"+v"(v16),
			 [o_regs_17]"+v"(v17),
			 [o_regs_18]"+v"(v18),
			 [o_regs_19]"+v"(v19),

			 [o_regs_20]"+v"(v20),
			 [o_regs_21]"+v"(v21),
			 [o_regs_22]"+v"(v22),
			 [o_regs_23]"+v"(v23),
			 [o_regs_24]"+v"(v24),
			 [o_regs_25]"+v"(v25),
			 [o_regs_26]"+v"(v26),
			 [o_regs_27]"+v"(v27),
			 [o_regs_28]"+v"(v28),
			 [o_regs_29]"+v"(v29),

			 [o_regs_30]"+v"(v30),
			 [o_regs_31]"+v"(v31),
			 [o_regs_32]"+v"(v32),
			 [o_regs_33]"+v"(v33),
			 [o_regs_34]"+v"(v34),
			 [o_regs_35]"+v"(v35),
			 [o_regs_36]"+v"(v36),
			 [o_regs_37]"+v"(v37),
			 [o_regs_38]"+v"(v38),
			 [o_regs_39]"+v"(v39),

			 [o_regs_40]"+v"(v40),
			 [o_regs_41]"+v"(v41),
			 [o_regs_42]"+v"(v42),
			 [o_regs_43]"+v"(v43),
			 [o_regs_44]"+v"(v44),
			 [o_regs_45]"+v"(v45),
			 [o_regs_46]"+v"(v46),
			 [o_regs_47]"+v"(v47),
			 [o_regs_48]"+v"(v48),
			 [o_regs_49]"+v"(v49),

			 [o_regs_50]"+v"(v50),
			 [o_regs_51]"+v"(v51),
			 [o_regs_52]"+v"(v52),
			 [o_regs_53]"+v"(v53),
			 [o_regs_54]"+v"(v54),
			 [o_regs_55]"+v"(v55),
			 [o_regs_56]"+v"(v56),
			 [o_regs_57]"+v"(v57),
			 [o_regs_58]"+v"(v58),
			 [o_regs_59]"+v"(v59),

			 [o_regs_60]"+v"(v60),
			 [o_regs_61]"+v"(v61),
			 [o_regs_62]"+v"(v62),
			 [o_regs_63]"+v"(v63),
			 [o_regs_64]"+v"(v64),
			 [o_regs_65]"+v"(v65),
			 [o_regs_66]"+v"(v66),
			 [o_regs_67]"+v"(v67),
			 [o_regs_68]"+v"(v68),
			 [o_regs_69]"+v"(v69),

			 [o_regs_70]"+v"(v70),
			 [o_regs_71]"+v"(v71),
			 [o_regs_72]"+v"(v72),
			 [o_regs_73]"+v"(v73),
			 [o_regs_74]"+v"(v74),
			 [o_regs_75]"+v"(v75),
			 [o_regs_76]"+v"(v76),
			 [o_regs_77]"+v"(v77),
			 [o_regs_78]"+v"(v78),
			 [o_regs_79]"+v"(v79),

			 [o_regs_80]"+v"(v80),
			 [o_regs_81]"+v"(v81),
			 [o_regs_82]"+v"(v82),
			 [o_regs_83]"+v"(v83),
			 [o_regs_84]"+v"(v84),
			 [o_regs_85]"+v"(v85),
			 [o_regs_86]"+v"(v86),
			 [o_regs_87]"+v"(v87),
			 [o_regs_88]"+v"(v88),
			 [o_regs_89]"+v"(v89),

			 [o_regs_90]"+v"(v90),
			 [o_regs_91]"+v"(v91),
			 [o_regs_92]"+v"(v92),
			 [o_regs_93]"+v"(v93),
			 [o_regs_94]"+v"(v94),
			 [o_regs_95]"+v"(v95),
			 [o_regs_96]"+v"(v96),
			 [o_regs_97]"+v"(v97),
			 [o_regs_98]"+v"(v98),
			 [o_regs_99]"+v"(v99),

			 [o_regs_100]"+v"(v100),
			 [o_regs_101]"+v"(v101),
			 [o_regs_102]"+v"(v102),
			 [o_regs_103]"+v"(v103),
			 [o_regs_104]"+v"(v104),
			 [o_regs_105]"+v"(v105),
			 [o_regs_106]"+v"(v106),
			 [o_regs_107]"+v"(v107),
			 [o_regs_108]"+v"(v108),
			 [o_regs_109]"+v"(v109),

			 [o_regs_110]"+v"(v110),
			 [o_regs_111]"+v"(v111),
			 [o_regs_112]"+v"(v112),
			 [o_regs_113]"+v"(v113),
			 [o_regs_114]"+v"(v114),
			 [o_regs_115]"+v"(v115),
			 [o_regs_116]"+v"(v116),
			 [o_regs_117]"+v"(v117),
			 [o_regs_118]"+v"(v118),
			 [o_regs_119]"+v"(v119),

			 [o_regs_120]"+v"(v120),
			 [o_regs_121]"+v"(v121),
			 [o_regs_122]"+v"(v122),
			 [o_regs_123]"+v"(v123),
			 [o_regs_124]"+v"(v124),
			 [o_regs_125]"+v"(v125),
			 [o_regs_126]"+v"(v126),
			 [o_regs_127]"+v"(v127),


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

			[threadIdxx]"+s"(vthread),
			[wave_id]"+s"(wave_id),

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
		  "s40", "s41", "s45", "s46", "s47", "s48", "s49",
		  "s50", "s52", "s53", "s56", "s57", "s58",
		  "s67", "s68", "s69",
		  "s70", "s71", "s73", "s74", "s75", "s76", "s77", "s78", "s79",
		  "s80", "s81", "s82", "s83", "s84",

		  "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v9",
		  "v10", "v11", "v12", "v13", "v14", "v15", "v16", "v17", "v18", "v19",
		  "v20", "v21", "v22", "v23", "v24", "v25", "v26", "v27", "v28", "v29",
		  "v30", "v31", "v32", "v33", "v34", "v35", "v36", "v37", "v38", "v39",
		  // "v40", "v41", "v42", "v43", "v44", "v45", "v46", "v47", "v48", "v49",
		  // "v50", "v51", "v52", "v53", "v54", "v55", "v56", "v57", "v58", "v59",
		  // "v60", "v61", "v62", "v63", 
		  // "v64","v65","v66","v67","v68","v69","v70","v71",
		  // "v72","v73","v74","v75","v76","v77","v78","v79",
		  // "v80","v81","v82","v83","v84","v85","v86","v87",
		  // "v88","v89","v90","v91","v92","v93","v94","v95",
		  // "v128", "v129", "v130", "v131",
		  // "v132", "v133", "v134", "v135",
	//       "v136", "v137", "v138", "v139",
	//       "v140", "v141", "v142", "v143", "v144", "v145", "v146", "v147",
	//       "v148", "v149", "v150", "v151", "v152", "v153", "v154", "v155",
	//       "v156", "v157", "v158", "v159", "v160", "v161", "v162", "v163",
	//       "v164", "v165", "v166", "v167",
	//       "v168", "v169", "v170", "v171"
		  // ,
		  // "v172", "v173", "v174", "v175", "v176", "v177", "v178", "v179",
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

		if (wave_id == 3) {
			return;
		}

#ifdef numsplit1
		register uint32_t shuffle0 asm("v24");
		register uint32_t shuffle1 asm("v25");
		register uint32_t shuffle2 asm("v26");
		register uint32_t shuffle3 asm("v27");

		int s_perm = 0x07060302;


		int o_reg_idx = 0;
		int lds_st_idx = (wave_id * 4608 + 288 * (vthread >> 4) + 8 * (vthread & 15)) >> 2;
		int lds_ld_idx = (wave_id * 4608 + 8 * (vthread >> 3) + 144 * (vthread & 7))  >> 2;

		// int copy_index = 0;
		int copy_index = int((int((vthread & 7)  << 4) +
							 int(vthread >> 3) * 1024 +
							 int(s3) * 3 * 16 * 512 * 2 +
							 wave_id * 16 * 512 * 2) >> 2); //num_splits == 1

		std::array<uint32_t, 16> arr{};

		LOOP_STRIDE4(0, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx);
		LOOP_STRIDE4(1, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 288);
		LOOP_STRIDE4(2, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36);
		LOOP_STRIDE4(3, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36 + 288);
		LOOP_STRIDE4(16, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576);
		LOOP_STRIDE4(17, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 288);
		LOOP_STRIDE4(18, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36);
		LOOP_STRIDE4(19, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36 + 288);
		B16_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx);
		B16_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index);
		copy_index += 64;

		LOOP_STRIDE4(32, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx);
		LOOP_STRIDE4(33, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 288);
		LOOP_STRIDE4(34, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36);
		LOOP_STRIDE4(35, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36 + 288);
		LOOP_STRIDE4(48, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576);
		LOOP_STRIDE4(49, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 288);
		LOOP_STRIDE4(50, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36);
		LOOP_STRIDE4(51, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36 + 288);

		B16_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx);
		B16_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index);
		copy_index += 64;



		LOOP_STRIDE4(64, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx);
		LOOP_STRIDE4(65, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 288);
		LOOP_STRIDE4(66, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36);
		LOOP_STRIDE4(67, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36 + 288);
		LOOP_STRIDE4(80, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576);
		LOOP_STRIDE4(81, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 288);
		LOOP_STRIDE4(82, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36);
		LOOP_STRIDE4(83, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36 + 288);

		B16_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx);
		B16_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index);
		copy_index += 64;


		LOOP_STRIDE4(96, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx);
		LOOP_STRIDE4(97, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 288);
		LOOP_STRIDE4(98, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36);
		LOOP_STRIDE4(99, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 36 + 288);
		LOOP_STRIDE4(112, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576);
		LOOP_STRIDE4(113, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 288);
		LOOP_STRIDE4(114, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36);
		LOOP_STRIDE4(115, VGPR2SHUFFLE, LOOP_STRIDE4_TAIL);
		B16_SUFFFLEY_2_LDS_LOOP(lds_st_idx + 576 + 36 + 288);

		B16_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx);
		B16_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index);
#endif




#ifdef numsplit5
		register uint32_t shuffle0 asm("v20");
		register uint32_t shuffle1 asm("v21");
		register uint32_t shuffle2 asm("v22");
		register uint32_t shuffle3 asm("v23");

		int lds_ld_idx = wave_id * 2112 +
						 int(vthread >> 4) * 4 +
						 int(vthread & 3) * 264 +
						 int((vthread & 15) >> 2) * 64;
		int lds_st_idx = wave_id * 2112 +
						 int(vthread << 2);
		int copy_index = int((int((vthread & 15) << 4) +
							 int(vthread >> 4) * 2048 +
							 int(s3) * 3 * 16 * 512 * 5 * 4 +
							 int(s4) * 16 * 512 * 4 +
							 wave_id * 5 * 16 * 512 * 4) >> 2);

			// printf("s3 %d, s4 %d, copy_index :%d \n", s3, s4, copy_index);

		std::array<uint32_t, 32> arr{};

		LOOP_STRIDE4(0, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx      );
		LOOP_STRIDE4(1, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 264);
		LOOP_STRIDE4(2, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 528);
		LOOP_STRIDE4(3, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 792);

		LOOP_STRIDE4(16, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1056);
		LOOP_STRIDE4(17, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1320);
		LOOP_STRIDE4(18, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1584);
		LOOP_STRIDE4(19, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1848);

		F32_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx)
		F32_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index)
		copy_index += 128;

		LOOP_STRIDE4(32, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx      );
		LOOP_STRIDE4(33, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 264);
		LOOP_STRIDE4(34, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 528);
		LOOP_STRIDE4(35, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 792);

		LOOP_STRIDE4(48, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1056);
		LOOP_STRIDE4(49, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1320);
		LOOP_STRIDE4(50, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1584);
		LOOP_STRIDE4(51, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1848);
		F32_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx)
		F32_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index)
		copy_index += 128;

		LOOP_STRIDE4(64, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx      );
		LOOP_STRIDE4(65, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 264);
		LOOP_STRIDE4(66, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 528);
		LOOP_STRIDE4(67, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 792);

		LOOP_STRIDE4(80, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1056);
		LOOP_STRIDE4(81, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1320);
		LOOP_STRIDE4(82, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1584);
		LOOP_STRIDE4(83, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1848);
		F32_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx)
		F32_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index)
		copy_index += 128;

		LOOP_STRIDE4(96, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx      );
		LOOP_STRIDE4(97, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 264);
		LOOP_STRIDE4(98, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 528);
		LOOP_STRIDE4(99, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 792);

		LOOP_STRIDE4(112, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1056);
		LOOP_STRIDE4(113, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1320);
		LOOP_STRIDE4(114, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1584);
		LOOP_STRIDE4(115, VGPR2SHUFFLE, F32_SUFFFLEY_2_LDS_LOOP, lds_st_idx + 1848);
		F32_LDS_2_VGPR_LOOP_STRIDE1(LDS_2_VGPR, lds_ld_idx)
		F32_VGPR_2_DRAM_LOOP_STRIDE1(VGPR_2_DRAM, copy_index)

		int lse_index = int((int((vthread & 15) << 2) +
							int(s3) * 3 * 16 * 5 * 4 +
							int(s4) * 16 * 4 +
							wave_id * 5 * 16 * 4) >> 2);

		p_lse[lse_index] = v_lse;
#endif
    }
};

} // namespace ck_tile

