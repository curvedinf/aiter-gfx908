	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	_gemm_afp4_wfp4_kernel_preshuffled_scales ; -- Begin function _gemm_afp4_wfp4_kernel_preshuffled_scales
	.p2align	8
	.type	_gemm_afp4_wfp4_kernel_preshuffled_scales,@function
_gemm_afp4_wfp4_kernel_preshuffled_scales: ; @_gemm_afp4_wfp4_kernel_preshuffled_scales
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.5:
	.file	1 "/app/aiter/aiter/ops/triton" "gemm_afp4wfp4.py"
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.p2align	8
; %bb.6:
.LBB0_0:
	s_cmp_lt_i32 s14, 1
	s_mov_b32 s29, 1
	s_cbranch_scc1 .LBB0_4
; %bb.1:
	s_mov_b32 s28, s13
	.file	2 "/app/OAI-triton/python/triton/language" "standard.py"
	s_addk_i32 s13, 0xff
	s_ashr_i32 s14, s13, 31
	s_lshr_b32 s14, s14, 24
	s_add_i32 s13, s13, s14
	s_ashr_i32 s13, s13, 8
	.file	3 "/app/aiter/aiter/ops/triton/utils" "pid_preprocessing.py"
	s_abs_i32 s17, s13
	v_cvt_f32_u32_e32 v1, s17
	s_sub_i32 s19, 0, s17
	s_load_dword s18, s[0:1], 0x38
	s_load_dwordx2 s[30:31], s[0:1], 0x40
	s_load_dword s14, s[0:1], 0x48
	s_abs_i32 s0, s16
	v_rcp_iflag_f32_e32 v1, v1
	s_xor_b32 s1, s16, s13
	s_ashr_i32 s1, s1, 31
	v_lshrrev_b32_e32 v10, 3, v0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_or_b32_e32 v11, 32, v10
	v_or_b32_e32 v12, 64, v10
	v_or_b32_e32 v13, 0x60, v10
	v_readfirstlane_b32 s20, v1
	s_mul_i32 s19, s19, s20
	s_mul_hi_u32 s19, s20, s19
	s_add_i32 s20, s20, s19
	s_mul_hi_u32 s19, s0, s20
	s_mul_i32 s20, s19, s17
	s_sub_i32 s0, s0, s20
	s_add_i32 s21, s19, 1
	s_sub_i32 s20, s0, s17
	s_cmp_ge_u32 s0, s17
	s_cselect_b32 s19, s21, s19
	s_cselect_b32 s0, s20, s0
	s_add_i32 s20, s19, 1
	s_cmp_ge_u32 s0, s17
	s_cselect_b32 s0, s20, s19
	s_xor_b32 s0, s0, s1
	s_sub_i32 s0, s0, s1
	s_mul_i32 s1, s0, s13
	s_sub_i32 s16, s16, s1
	s_abs_i32 s1, s12
	v_cvt_f32_u32_e32 v1, s1
	s_lshl_b32 s13, s0, 7
	s_sub_i32 s19, 0, s1
	v_or_b32_e32 v4, s13, v10
	v_rcp_iflag_f32_e32 v1, v1
	s_bfe_i32 s17, s0, 0x10018
	v_add_u32_e32 v4, s17, v4
	v_xor_b32_e32 v4, s17, v4
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_or_b32_e32 v16, s13, v11
	v_or_b32_e32 v17, s13, v12
	v_or_b32_e32 v18, s13, v13
	v_mul_lo_u32 v19, s19, v1
	v_mul_hi_u32 v19, v1, v19
	v_add_u32_e32 v22, v1, v19
	v_mul_hi_u32 v1, v4, v22
	v_mul_lo_u32 v1, v1, s1
	v_sub_u32_e32 v1, v4, v1
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	s_lshl_b32 s34, s16, 8
	v_or_b32_e32 v10, s34, v10
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	s_bfe_i32 s19, s16, 0x10017
	v_add_u32_e32 v10, s19, v10
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_xor_b32_e32 v1, s17, v1
	v_subrev_u32_e32 v24, s17, v1
	v_add_u32_e32 v1, s17, v16
	v_xor_b32_e32 v1, s17, v1
	v_mul_hi_u32 v4, v1, v22
	v_mul_lo_u32 v4, v4, s1
	v_sub_u32_e32 v1, v1, v4
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_or_b32_e32 v11, s34, v11
	v_add_u32_e32 v11, s19, v11
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_xor_b32_e32 v11, s19, v11
	v_or_b32_e32 v12, s34, v12
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_xor_b32_e32 v1, s17, v1
	v_subrev_u32_e32 v16, s17, v1
	v_add_u32_e32 v1, s17, v17
	v_xor_b32_e32 v1, s17, v1
	v_mul_hi_u32 v4, v1, v22
	v_mul_lo_u32 v4, v4, s1
	v_sub_u32_e32 v1, v1, v4
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_or_b32_e32 v13, s34, v13
	v_lshrrev_b32_e32 v45, 6, v0
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_bfe_i32 v5, v0, 4, 1
	v_and_b32_e32 v3, 16, v0
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_xor_b32_e32 v1, s17, v1
	v_subrev_u32_e32 v17, s17, v1
	v_add_u32_e32 v1, s17, v18
	v_xor_b32_e32 v1, s17, v1
	v_mul_hi_u32 v4, v1, v22
	v_mul_lo_u32 v4, v4, s1
	v_sub_u32_e32 v1, v1, v4
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_lshrrev_b32_e32 v18, 1, v0
	v_and_b32_e32 v40, 64, v18
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_subrev_u32_e32 v4, s1, v1
	v_cmp_le_u32_e32 vcc, s1, v1
	v_and_b32_e32 v6, 32, v0
	v_lshlrev_b32_e32 v14, 4, v0
	v_cndmask_b32_e32 v1, v1, v4, vcc
	v_xor_b32_e32 v1, s17, v1
	v_subrev_u32_e32 v30, s17, v1
	s_abs_i32 s17, s28
	v_cvt_f32_u32_e32 v19, s17
	s_sub_i32 s20, 0, s17
	v_lshlrev_b32_e32 v1, 2, v0
	v_and_b32_e32 v4, 0xfc, v1
	v_rcp_iflag_f32_e32 v18, v19
	v_xor_b32_e32 v19, s19, v10
	v_bfe_i32 v7, v0, 5, 1
	v_and_b32_e32 v8, 64, v0
	v_mul_f32_e32 v18, 0x4f7ffffe, v18
	v_cvt_u32_f32_e32 v18, v18
	v_and_b32_e32 v15, 0x70, v14
	v_and_b32_e32 v14, 0xf0, v14
	v_lshlrev_b32_e32 v3, 4, v3
	v_mul_lo_u32 v20, s20, v18
	v_mul_hi_u32 v20, v18, v20
	v_add_u32_e32 v18, v18, v20
	v_mul_hi_u32 v20, v19, v18
	v_mul_lo_u32 v20, v20, s17
	v_sub_u32_e32 v19, v19, v20
	v_subrev_u32_e32 v20, s17, v19
	v_cmp_le_u32_e32 vcc, s17, v19
	v_bfe_i32 v9, v0, 6, 1
	v_mul_i32_i24_e32 v33, -16, v8
	v_cndmask_b32_e32 v19, v19, v20, vcc
	v_subrev_u32_e32 v20, s17, v19
	v_cmp_le_u32_e32 vcc, s17, v19
	v_lshrrev_b32_e32 v1, 1, v8
	v_and_b32_e32 v2, 63, v0
	v_cndmask_b32_e32 v19, v19, v20, vcc
	v_xor_b32_e32 v19, s19, v19
	v_subrev_u32_e32 v32, s19, v19
	v_mul_hi_u32 v19, v11, v18
	v_mul_lo_u32 v19, v19, s17
	v_sub_u32_e32 v11, v11, v19
	v_subrev_u32_e32 v19, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	s_add_i32 s42, 0, 0x25800
	s_add_i32 s41, 0, 0x24000
	v_cndmask_b32_e32 v11, v11, v19, vcc
	v_subrev_u32_e32 v19, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	s_mov_b32 s23, 0x27000
	s_mov_b32 s22, 0x7ffffffe
	v_cndmask_b32_e32 v11, v11, v19, vcc
	v_xor_b32_e32 v11, s19, v11
	v_subrev_u32_e32 v34, s19, v11
	v_add_u32_e32 v11, s19, v12
	v_xor_b32_e32 v11, s19, v11
	v_mul_hi_u32 v12, v11, v18
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	s_mov_b32 s20, s8
	s_add_i32 s40, 0, 0x18000
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_and_b32_e32 v74, 15, v0
	v_or_b32_e32 v75, 16, v74
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_xor_b32_e32 v11, s19, v11
	v_subrev_u32_e32 v36, s19, v11
	v_add_u32_e32 v11, s19, v13
	v_xor_b32_e32 v11, s19, v11
	v_mul_hi_u32 v12, v11, v18
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	s_mov_b32 s37, 0
	v_accvgpr_write_b32 a3, 0
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_xor_b32_e32 v11, s19, v11
	v_subrev_u32_e32 v38, s19, v11
	v_add_u32_e32 v11, 0x80, v10
	v_xor_b32_e32 v11, s19, v11
	v_mul_hi_u32 v12, v11, v18
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_accvgpr_write_b32 a0, 0
	v_accvgpr_write_b32 a7, 0
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_accvgpr_write_b32 a6, 0
	v_accvgpr_write_b32 a5, 0
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_add_u32_e32 v12, 0xa0, v10
	v_xor_b32_e32 v12, s19, v12
	v_mul_hi_u32 v13, v12, v18
	v_mul_lo_u32 v13, v13, s17
	v_sub_u32_e32 v12, v12, v13
	v_subrev_u32_e32 v13, s17, v12
	v_cmp_le_u32_e32 vcc, s17, v12
	v_xor_b32_e32 v11, s19, v11
	v_subrev_u32_e32 v11, s19, v11
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_subrev_u32_e32 v13, s17, v12
	v_cmp_le_u32_e32 vcc, s17, v12
	s_waitcnt lgkmcnt(0)
	v_mul_lo_u32 v41, v11, s18
	v_accvgpr_write_b32 a4, 0
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_add_u32_e32 v13, 0xc0, v10
	v_xor_b32_e32 v13, s19, v13
	v_mul_hi_u32 v19, v13, v18
	v_mul_lo_u32 v19, v19, s17
	v_sub_u32_e32 v13, v13, v19
	v_subrev_u32_e32 v19, s17, v13
	v_cmp_le_u32_e32 vcc, s17, v13
	v_add_u32_e32 v10, 0xe0, v10
	v_xor_b32_e32 v10, s19, v10
	v_cndmask_b32_e32 v13, v13, v19, vcc
	v_subrev_u32_e32 v19, s17, v13
	v_cmp_le_u32_e32 vcc, s17, v13
	v_xor_b32_e32 v12, s19, v12
	v_subrev_u32_e32 v12, s19, v12
	v_cndmask_b32_e32 v13, v13, v19, vcc
	v_mul_hi_u32 v19, v10, v18
	v_mul_lo_u32 v19, v19, s17
	v_sub_u32_e32 v10, v10, v19
	v_subrev_u32_e32 v19, s17, v10
	v_cmp_le_u32_e32 vcc, s17, v10
	v_xor_b32_e32 v13, s19, v13
	v_subrev_u32_e32 v13, s19, v13
	v_cndmask_b32_e32 v10, v10, v19, vcc
	v_subrev_u32_e32 v19, s17, v10
	v_cmp_le_u32_e32 vcc, s17, v10
	v_mul_lo_u32 v42, v12, s18
	v_mul_lo_u32 v43, v13, s18
	v_cndmask_b32_e32 v10, v10, v19, vcc
	v_xor_b32_e32 v10, s19, v10
	v_subrev_u32_e32 v10, s19, v10
	s_lshl_b32 s19, s16, 3
	v_mul_lo_u32 v44, v10, s18
	v_or_b32_e32 v10, s19, v45
	s_bfe_i32 s16, s16, 0x1001c
	v_add_u32_e32 v10, s16, v10
	v_xor_b32_e32 v11, s16, v10
	v_mul_hi_u32 v12, v11, v18
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_add_u32_e32 v10, 4, v10
	v_xor_b32_e32 v10, s16, v10
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_accvgpr_write_b32 a11, 0
	v_accvgpr_write_b32 a10, 0
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_mul_hi_u32 v12, v10, v18
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v10, v10, v12
	v_subrev_u32_e32 v12, s17, v10
	v_cmp_le_u32_e32 vcc, s17, v10
	v_xor_b32_e32 v11, s16, v11
	v_subrev_u32_e32 v11, s16, v11
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_subrev_u32_e32 v12, s17, v10
	v_cmp_le_u32_e32 vcc, s17, v10
	v_accvgpr_write_b32 a9, 0
	v_accvgpr_write_b32 a8, 0
	v_cndmask_b32_e32 v10, v10, v12, vcc
	v_xor_b32_e32 v10, s16, v10
	v_subrev_u32_e32 v10, s16, v10
	v_mad_u64_u32 v[18:19], s[16:17], v11, s14, v[4:5]
	v_mad_u64_u32 v[20:21], s[16:17], v10, s14, v[4:5]
	s_lshl_b32 s16, s0, 2
	s_nop 0
	v_or_b32_e32 v10, s16, v45
	s_bfe_i32 s0, s0, 0x1001d
	v_add_u32_e32 v10, s0, v10
	v_xor_b32_e32 v10, s0, v10
	v_mul_hi_u32 v11, v10, v22
	v_mul_lo_u32 v11, v11, s1
	v_sub_u32_e32 v10, v10, v11
	v_subrev_u32_e32 v11, s1, v10
	v_cmp_le_u32_e32 vcc, s1, v10
	v_and_b32_e32 v19, 0x220, v7
	v_and_b32_e32 v21, 0x440, v9
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_subrev_u32_e32 v11, s1, v10
	v_cmp_le_u32_e32 vcc, s1, v10
	s_and_b32 s14, s14, 0x3fff
	s_and_b32 s16, s9, 0xffff
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_xor_b32_e32 v10, s0, v10
	v_subrev_u32_e32 v10, s0, v10
	v_mad_u64_u32 v[22:23], s[0:1], v10, s31, v[4:5]
	v_lshlrev_b32_e32 v23, 4, v6
	v_and_b32_e32 v5, 0x110, v5
	v_or3_b32 v6, v14, v3, v23
	v_bitop3_b32 v4, v19, v14, v5 bitop3:0x36
	v_sub_u32_e32 v6, v33, v6
	v_xad_u32 v4, v4, v21, v6
	v_or_b32_e32 v6, 0x1000, v14
	v_bitop3_b32 v7, v19, v6, v5 bitop3:0x36
	v_or3_b32 v6, v3, v6, v23
	v_sub_u32_e32 v6, v33, v6
	v_xad_u32 v6, v7, v21, v6
	v_ashrrev_i16_e32 v7, 15, v6
	v_lshrrev_b16_e32 v7, 12, v7
	v_add_u16_e32 v6, v6, v7
	v_ashrrev_i16_e32 v6, 4, v6
	v_bfe_i32 v8, v6, 0, 16
	v_or_b32_e32 v6, 0x2000, v14
	v_bitop3_b32 v7, v19, v6, v5 bitop3:0x36
	v_or3_b32 v6, v3, v6, v23
	v_sub_u32_e32 v6, v33, v6
	v_xad_u32 v6, v7, v21, v6
	v_ashrrev_i16_e32 v7, 15, v6
	v_lshrrev_b16_e32 v7, 12, v7
	v_add_u16_e32 v6, v6, v7
	v_ashrrev_i16_e32 v6, 4, v6
	v_bfe_i32 v10, v6, 0, 16
	v_or_b32_e32 v6, 0x3000, v14
	v_bitop3_b32 v7, v19, v6, v5 bitop3:0x36
	v_or3_b32 v6, v3, v6, v23
	v_sub_u32_e32 v6, v33, v6
	v_xad_u32 v6, v7, v21, v6
	v_readlane_b32 s0, v0, 0
	v_ashrrev_i16_e32 v7, 15, v6
	s_lshl_b32 s1, s0, 2
	v_lshrrev_b16_e32 v7, 12, v7
	s_and_b32 s19, s1, 0x300
	s_and_b32 s1, s31, 0x3fff
	v_ashrrev_i16_e32 v4, 4, v4
	v_add_u16_e32 v6, v6, v7
	s_bitset1_b32 s1, 14
	v_bfe_i32 v4, v4, 0, 16
	v_ashrrev_i16_e32 v6, 4, v6
	s_lshl_b32 s31, s1, 16
	s_bitset1_b32 s14, 14
	s_lshl_b32 s0, s0, 4
	v_bfe_i32 v12, v6, 0, 16
	v_add_u32_e32 v6, v2, v4
	s_add_i32 m0, s42, s19
	s_or_b32 s21, s16, s31
	s_add_i32 s1, s41, s19
	s_and_b32 s17, s11, 0xffff
	s_lshl_b32 s35, s14, 16
	s_and_b32 s39, s0, 0xc00
	s_and_b32 s0, s15, 0x3fff
	v_lshrrev_b64 v[6:7], v6, exec
	buffer_load_dword v22, s[20:23], 0 offen lds
	s_add_i32 s16, s1, 0x400
	s_or_b32 s21, s17, s35
	s_mov_b32 s20, s10
	s_mov_b32 m0, s1
	s_bitset1_b32 s0, 14
	v_and_b32_e32 v6, 1, v6
	v_add_u32_e32 v9, v2, v8
	buffer_load_dword v18, s[20:23], 0 offen sc0 nt lds
	s_mov_b32 m0, s16
	s_and_b32 s1, s3, 0xffff
	s_lshl_b32 s36, s0, 16
	v_lshl_add_u32 v4, v4, 4, v15
	v_bfrev_b32_e32 v7, 1
	v_cmp_eq_u32_e32 vcc, 1, v6
	v_lshl_add_u32 v6, v8, 4, v15
	v_lshrrev_b64 v[8:9], v9, exec
	buffer_load_dword v20, s[20:23], 0 offen sc0 nt lds
	s_or_b32 s21, s1, s36
	v_mad_u64_u32 v[24:25], s[0:1], v24, s15, v[4:5]
	v_mad_u64_u32 v[26:27], s[0:1], v16, s15, v[6:7]
	v_and_b32_e32 v8, 1, v8
	s_add_i32 s14, s40, s39
	v_cmp_eq_u32_e64 s[0:1], 1, v8
	v_add_u32_e32 v11, v2, v10
	s_add_i32 s16, s14, 0x1000
	s_mov_b32 s20, s2
	v_cndmask_b32_e32 v25, v7, v24, vcc
	s_mov_b32 m0, s14
	v_cndmask_b32_e64 v9, v7, v26, s[0:1]
	v_lshl_add_u32 v8, v10, 4, v15
	v_lshrrev_b64 v[10:11], v11, exec
	buffer_load_dwordx4 v25, s[20:23], 0 offen lds
	s_mov_b32 m0, s16
	v_mad_u64_u32 v[28:29], s[16:17], v17, s15, v[8:9]
	v_and_b32_e32 v10, 1, v10
	v_add_u32_e32 v13, v2, v12
	v_cmp_eq_u32_e64 s[16:17], 1, v10
	v_lshl_add_u32 v10, v12, 4, v15
	v_lshrrev_b64 v[12:13], v13, exec
	v_or_b32_e32 v13, 0x4000, v14
	v_bitop3_b32 v15, v19, v13, v5 bitop3:0x36
	v_or3_b32 v13, v3, v13, v23
	v_sub_u32_e32 v13, v33, v13
	v_xad_u32 v13, v15, v21, v13
	v_ashrrev_i16_e32 v15, 15, v13
	v_lshrrev_b16_e32 v15, 12, v15
	v_add_u16_e32 v13, v13, v15
	v_or_b32_e32 v15, 0x5000, v14
	v_bitop3_b32 v16, v19, v15, v5 bitop3:0x36
	v_or3_b32 v15, v3, v15, v23
	v_sub_u32_e32 v15, v33, v15
	v_xad_u32 v15, v16, v21, v15
	v_ashrrev_i16_e32 v16, 15, v15
	v_lshrrev_b16_e32 v16, 12, v16
	v_add_u16_e32 v15, v15, v16
	v_or_b32_e32 v16, 0x6000, v14
	v_bitop3_b32 v17, v19, v16, v5 bitop3:0x36
	v_or3_b32 v16, v3, v16, v23
	v_or_b32_e32 v14, 0x7000, v14
	v_sub_u32_e32 v16, v33, v16
	v_or3_b32 v3, v3, v14, v23
	v_xad_u32 v16, v17, v21, v16
	v_bitop3_b32 v5, v19, v14, v5 bitop3:0x36
	v_sub_u32_e32 v3, v33, v3
	v_cndmask_b32_e64 v11, v7, v28, s[16:17]
	v_ashrrev_i16_e32 v17, 15, v16
	v_xad_u32 v3, v5, v21, v3
	s_add_i32 s24, s14, 0x2000
	s_add_i32 s25, s14, 0x3000
	v_mad_u64_u32 v[30:31], s[14:15], v30, s15, v[10:11]
	v_and_b32_e32 v12, 1, v12
	v_lshrrev_b16_e32 v17, 12, v17
	v_ashrrev_i16_e32 v5, 15, v3
	buffer_load_dwordx4 v9, s[20:23], 0 offen lds
	s_mov_b32 m0, s24
	v_cmp_eq_u32_e64 s[14:15], 1, v12
	v_ashrrev_i16_e32 v13, 4, v13
	v_add_u16_e32 v16, v16, v17
	v_lshrrev_b16_e32 v5, 12, v5
	v_and_b32_e32 v17, 7, v0
	buffer_load_dwordx4 v11, s[20:23], 0 offen lds
	v_cndmask_b32_e64 v12, v7, v30, s[14:15]
	s_mov_b32 m0, s25
	v_add_u16_e32 v3, v3, v5
	v_mad_u64_u32 v[32:33], s[24:25], v32, s18, v[4:5]
	v_add_u32_sdwa v4, v2, sext(v13) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_add_u32_sdwa v5, v17, sext(v13) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	buffer_load_dwordx4 v12, s[20:23], 0 offen lds
	s_and_b32 s20, s18, 0x3fff
	v_lshl_add_u32 v33, v5, 4, v41
	v_lshrrev_b64 v[4:5], v4, exec
	v_ashrrev_i16_e32 v15, 4, v15
	s_bitset1_b32 s20, 14
	v_and_b32_e32 v4, 1, v4
	s_add_i32 s43, s39, 0
	s_and_b32 s21, s5, 0xffff
	s_lshl_b32 s38, s20, 16
	v_cndmask_b32_e32 v14, v7, v32, vcc
	v_mad_u64_u32 v[34:35], s[24:25], v34, s18, v[6:7]
	v_cmp_eq_u32_e32 vcc, 1, v4
	v_add_u32_sdwa v4, v2, sext(v15) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_add_u32_sdwa v5, v17, sext(v15) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	s_add_i32 s26, s43, 0x1000
	s_or_b32 s21, s21, s38
	s_mov_b32 s20, s4
	s_mov_b32 m0, s43
	v_lshl_add_u32 v35, v5, 4, v42
	v_lshrrev_b64 v[4:5], v4, exec
	s_add_i32 s27, s43, 0x2000
	v_ashrrev_i16_e32 v16, 4, v16
	buffer_load_dwordx4 v14, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e64 v6, v7, v34, s[0:1]
	s_mov_b32 m0, s26
	v_mad_u64_u32 v[36:37], s[0:1], v36, s18, v[8:9]
	v_and_b32_e32 v4, 1, v4
	s_add_i32 s33, s43, 0x3000
	v_ashrrev_i16_e32 v3, 4, v3
	buffer_load_dwordx4 v6, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e64 v8, v7, v36, s[16:17]
	s_mov_b32 m0, s27
	v_mad_u64_u32 v[38:39], s[0:1], v38, s18, v[10:11]
	v_cndmask_b32_e32 v13, v7, v33, vcc
	v_cmp_eq_u32_e32 vcc, 1, v4
	v_add_u32_sdwa v4, v2, sext(v16) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_add_u32_sdwa v5, v17, sext(v16) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	s_add_i32 s44, s43, 0x4000
	s_add_i32 s45, s43, 0x5000
	s_add_i32 s46, s43, 0x6000
	s_add_i32 s47, s43, 0x7000
	buffer_load_dwordx4 v8, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e64 v10, v7, v38, s[14:15]
	s_mov_b32 m0, s33
	v_lshl_add_u32 v37, v5, 4, v43
	v_lshrrev_b64 v[4:5], v4, exec
	v_add_u32_sdwa v2, v2, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_add_u32_sdwa v3, v17, sext(v3) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	buffer_load_dwordx4 v10, s[20:23], 0 offen sc0 nt lds
	s_mov_b32 m0, s44
	v_and_b32_e32 v4, 1, v4
	v_lshl_add_u32 v39, v3, 4, v44
	v_lshrrev_b64 v[2:3], v2, exec
	s_add_u32 s24, s2, 0x80
	buffer_load_dwordx4 v13, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v15, v7, v35, vcc
	s_mov_b32 m0, s45
	v_cmp_eq_u32_e32 vcc, 1, v4
	v_and_b32_e32 v2, 1, v2
	s_addc_u32 s17, s3, 0
	buffer_load_dwordx4 v15, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v4, v7, v37, vcc
	s_mov_b32 m0, s46
	v_cmp_eq_u32_e32 vcc, 1, v2
	s_add_u32 s16, s4, 0x80
	buffer_load_dwordx4 v4, s[20:23], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v2, v7, v39, vcc
	s_mov_b32 m0, s47
	s_addc_u32 s18, s5, 0
	buffer_load_dwordx4 v2, s[20:23], 0 offen sc0 nt lds
	s_add_u32 s20, s8, 0x100
	s_addc_u32 s14, s9, 0
	s_add_u32 s44, s10, 0x100
	s_addc_u32 s25, s11, 0
	s_add_i32 s33, 0, 0x25c00
	s_and_b32 s14, s14, 0xffff
	s_add_i32 m0, s33, s19
	s_or_b32 s21, s14, s31
	s_add_i32 s15, 0, 0x24800
	s_barrier
	buffer_load_dword v22, s[20:23], 0 offen lds
	s_add_i32 s14, s15, s19
	s_and_b32 s20, s25, 0xffff
	s_add_i32 s19, s14, 0x400
	s_or_b32 s45, s20, s35
	s_mov_b32 s46, s22
	s_mov_b32 s47, s23
	s_mov_b32 m0, s14
	s_add_i32 s14, 0, 0x1c000
	buffer_load_dword v18, s[44:47], 0 offen sc0 nt lds
	s_mov_b32 m0, s19
	s_add_i32 s19, s14, s39
	s_and_b32 s17, s17, 0xffff
	buffer_load_dword v20, s[44:47], 0 offen sc0 nt lds
	s_add_i32 s20, s19, 0x1000
	s_or_b32 s25, s17, s36
	s_mov_b32 s26, s22
	s_mov_b32 s27, s23
	s_mov_b32 m0, s19
	s_add_i32 s21, s19, 0x2000
	buffer_load_dwordx4 v25, s[24:27], 0 offen lds
	s_mov_b32 m0, s20
	s_add_i32 s44, s19, 0x3000
	buffer_load_dwordx4 v9, s[24:27], 0 offen lds
	s_mov_b32 m0, s21
	s_mov_b32 s19, s23
	buffer_load_dwordx4 v11, s[24:27], 0 offen lds
	s_mov_b32 m0, s44
	v_bfe_u32 v3, v0, 5, 1
	buffer_load_dwordx4 v12, s[24:27], 0 offen lds
	s_add_i32 s25, 0, 0x8000
	s_add_i32 s17, s25, s39
	s_add_i32 m0, s43, 0x8000
	s_add_i32 s20, s17, 0x1000
	s_add_i32 s21, s17, 0x2000
	s_add_i32 s24, s17, 0x3000
	s_add_i32 s26, s17, 0x4000
	s_add_i32 s27, s17, 0x5000
	s_add_i32 s39, s17, 0x6000
	s_add_i32 s43, s17, 0x7000
	s_and_b32 s17, s18, 0xffff
	s_or_b32 s17, s17, s38
	s_mov_b32 s18, s22
	buffer_load_dwordx4 v14, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s20
	s_mov_b64 s[0:1], 0x100
	buffer_load_dwordx4 v6, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s21
	v_lshlrev_b32_e32 v42, 8, v45
	buffer_load_dwordx4 v8, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s24
	s_add_u32 s24, s10, 0x200
	buffer_load_dwordx4 v10, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s26
	s_addc_u32 s26, s11, 0
	buffer_load_dwordx4 v13, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s27
	s_add_u32 s27, s8, 0x200
	buffer_load_dwordx4 v15, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s39
	v_lshlrev_b32_e32 v41, 7, v74
	buffer_load_dwordx4 v4, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s43
	v_and_b32_e32 v4, 48, v0
	buffer_load_dwordx4 v2, s[16:19], 0 offen sc0 nt lds
	v_lshlrev_b32_e32 v2, 1, v0
	v_and_or_b32 v19, v2, 62, v3
	v_lshlrev_b32_e32 v2, 3, v0
	v_and_b32_e32 v3, 48, v2
	v_and_b32_e32 v2, 64, v2
	v_bitop3_b32 v21, v3, v4, v2 bitop3:0x36
	v_or_b32_e32 v3, 64, v3
	v_bitop3_b32 v23, v2, v3, v4 bitop3:0x36
	v_lshlrev_b32_e32 v2, 7, v0
	v_and_b32_e32 v25, 0x780, v2
	v_or_b32_e32 v2, v40, v1
	v_or_b32_e32 v3, v2, v74
	v_or_b32_e32 v2, v2, v75
	v_lshlrev_b32_e32 v29, 7, v75
	v_lshlrev_b32_e32 v27, 7, v3
	v_lshlrev_b32_e32 v31, 7, v2
	s_addc_u32 s39, s9, 0
	v_accvgpr_write_b32 a15, 0
	v_accvgpr_write_b32 a14, 0
	v_accvgpr_write_b32 a13, 0
	v_accvgpr_write_b32 a12, 0
	v_accvgpr_write_b32 a19, 0
	v_accvgpr_write_b32 a18, 0
	v_accvgpr_write_b32 a17, 0
	v_accvgpr_write_b32 a16, 0
	v_accvgpr_write_b32 a23, 0
	v_accvgpr_write_b32 a22, 0
	v_accvgpr_write_b32 a21, 0
	v_accvgpr_write_b32 a20, 0
	v_accvgpr_write_b32 a27, 0
	v_accvgpr_write_b32 a26, 0
	v_accvgpr_write_b32 a25, 0
	v_accvgpr_write_b32 a24, 0
	v_accvgpr_write_b32 a63, 0
	v_accvgpr_write_b32 a62, 0
	v_accvgpr_write_b32 a61, 0
	v_accvgpr_write_b32 a60, 0
	v_accvgpr_write_b32 a79, 0
	v_accvgpr_write_b32 a78, 0
	v_accvgpr_write_b32 a77, 0
	v_accvgpr_write_b32 a76, 0
	v_accvgpr_write_b32 a107, 0
	v_accvgpr_write_b32 a106, 0
	v_accvgpr_write_b32 a105, 0
	v_accvgpr_write_b32 a104, 0
	v_accvgpr_write_b32 a31, 0
	v_accvgpr_write_b32 a30, 0
	v_accvgpr_write_b32 a29, 0
	v_accvgpr_write_b32 a28, 0
	v_accvgpr_write_b32 a35, 0
	v_accvgpr_write_b32 a34, 0
	v_accvgpr_write_b32 a33, 0
	v_accvgpr_write_b32 a32, 0
	v_accvgpr_write_b32 a39, 0
	v_accvgpr_write_b32 a38, 0
	v_accvgpr_write_b32 a37, 0
	v_accvgpr_write_b32 a36, 0
	v_accvgpr_write_b32 a43, 0
	v_accvgpr_write_b32 a42, 0
	v_accvgpr_write_b32 a41, 0
	v_accvgpr_write_b32 a40, 0
	v_accvgpr_write_b32 a47, 0
	v_accvgpr_write_b32 a46, 0
	v_accvgpr_write_b32 a45, 0
	v_accvgpr_write_b32 a44, 0
	v_accvgpr_write_b32 a55, 0
	v_accvgpr_write_b32 a54, 0
	v_accvgpr_write_b32 a53, 0
	v_accvgpr_write_b32 a52, 0
	v_accvgpr_write_b32 a75, 0
	v_accvgpr_write_b32 a74, 0
	v_accvgpr_write_b32 a73, 0
	v_accvgpr_write_b32 a72, 0
	v_accvgpr_write_b32 a111, 0
	v_accvgpr_write_b32 a110, 0
	v_accvgpr_write_b32 a109, 0
	v_accvgpr_write_b32 a108, 0
	v_accvgpr_write_b32 a103, 0
	v_accvgpr_write_b32 a102, 0
	v_accvgpr_write_b32 a101, 0
	v_accvgpr_write_b32 a100, 0
	v_accvgpr_write_b32 a91, 0
	v_accvgpr_write_b32 a90, 0
	v_accvgpr_write_b32 a89, 0
	v_accvgpr_write_b32 a88, 0
	v_accvgpr_write_b32 a71, 0
	v_accvgpr_write_b32 a70, 0
	v_accvgpr_write_b32 a69, 0
	v_accvgpr_write_b32 a68, 0
	v_accvgpr_write_b32 a67, 0
	v_accvgpr_write_b32 a66, 0
	v_accvgpr_write_b32 a65, 0
	v_accvgpr_write_b32 a64, 0
	v_accvgpr_write_b32 a51, 0
	v_accvgpr_write_b32 a50, 0
	v_accvgpr_write_b32 a49, 0
	v_accvgpr_write_b32 a48, 0
	v_accvgpr_write_b32 a59, 0
	v_accvgpr_write_b32 a58, 0
	v_accvgpr_write_b32 a57, 0
	v_accvgpr_write_b32 a56, 0
	v_accvgpr_write_b32 a87, 0
	v_accvgpr_write_b32 a86, 0
	v_accvgpr_write_b32 a85, 0
	v_accvgpr_write_b32 a84, 0
	v_accvgpr_write_b32 a99, 0
	v_accvgpr_write_b32 a98, 0
	v_accvgpr_write_b32 a97, 0
	v_accvgpr_write_b32 a96, 0
	v_accvgpr_write_b32 a83, 0
	v_accvgpr_write_b32 a82, 0
	v_accvgpr_write_b32 a81, 0
	v_accvgpr_write_b32 a80, 0
	v_accvgpr_write_b32 a95, 0
	v_accvgpr_write_b32 a94, 0
	v_accvgpr_write_b32 a93, 0
	v_accvgpr_write_b32 a92, 0
	v_accvgpr_write_b32 a115, 0
	v_accvgpr_write_b32 a114, 0
	v_accvgpr_write_b32 a113, 0
	v_accvgpr_write_b32 a112, 0
	v_accvgpr_write_b32 a119, 0
	v_accvgpr_write_b32 a118, 0
	v_accvgpr_write_b32 a117, 0
	v_accvgpr_write_b32 a116, 0
	v_accvgpr_write_b32 a123, 0
	v_accvgpr_write_b32 a122, 0
	v_accvgpr_write_b32 a121, 0
	v_accvgpr_write_b32 a120, 0
	v_accvgpr_write_b32 a127, 0
	v_accvgpr_write_b32 a126, 0
	v_accvgpr_write_b32 a125, 0
	v_accvgpr_write_b32 a124, 0
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	v_add_u32_e32 v43, s42, v19
	s_waitcnt vmcnt(15)
	s_barrier
	v_add3_u32 v2, s41, v19, v42
	ds_read_u8 v4, v43
	ds_read_u8 v5, v43 offset:64
	ds_read_u8 v10, v43 offset:128
	ds_read_u8 v11, v43 offset:192
	ds_read_u8 v84, v43 offset:256
	ds_read_u8 v85, v43 offset:320
	ds_read_u8 v86, v43 offset:384
	ds_read_u8 v87, v43 offset:448
	ds_read_u8 v12, v2
	ds_read_u8 v13, v2 offset:64
	ds_read_u8 v68, v2 offset:128
	ds_read_u8 v69, v2 offset:192
	ds_read_u8 v80, v2 offset:1024
	ds_read_u8 v81, v2 offset:1088
	ds_read_u8 v82, v2 offset:1152
	ds_read_u8 v83, v2 offset:1216
	v_add_u32_e32 v52, s40, v21
	v_add_u32_e32 v72, s40, v23
	v_add_u32_e32 v3, s37, v21
	v_add_u32_e32 v2, v52, v41
	v_add_u32_e32 v6, v72, v41
	v_add_u32_e32 v73, s37, v23
	v_add_u32_e32 v89, v3, v27
	ds_read_b128 v[60:63], v2
	ds_read_b128 v[6:9], v6
	ds_read_b128 v[64:67], v89
	ds_read_b128 v[14:17], v89 offset:16384
	s_waitcnt lgkmcnt(14)
	v_lshlrev_b16_e32 v2, 8, v5
	v_lshlrev_b16_e32 v5, 8, v11
	s_waitcnt lgkmcnt(10)
	v_lshlrev_b16_e32 v11, 8, v13
	s_waitcnt lgkmcnt(8)
	v_lshlrev_b16_e32 v13, 8, v69
	s_waitcnt lgkmcnt(6)
	v_lshlrev_b16_e32 v81, 8, v81
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v83, 8, v83
	v_add_u32_e32 v76, v52, v29
	v_add_u32_e32 v88, v72, v29
	v_add_u32_e32 v3, v3, v31
	v_add_u32_e32 v77, v73, v31
	v_or_b32_e32 v2, v4, v2
	v_or_b32_sdwa v4, v10, v5 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_e32 v5, v12, v11
	v_or_b32_sdwa v10, v68, v13 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_e32 v80, v80, v81
	v_or_b32_sdwa v81, v82, v83 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v90, v2, v4 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_or_b32_sdwa v91, v5, v10 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[68:71], v3
	ds_read_b128 v[2:5], v77
	ds_read_b128 v[76:79], v76
	ds_read_b128 v[10:13], v88
	v_or_b32_sdwa v88, v80, v81 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[80:83], v89 offset:18432
	v_accvgpr_read_b32 v59, a59
	v_accvgpr_read_b32 v51, a67
	v_accvgpr_read_b32 v50, a66
	v_accvgpr_read_b32 v49, a65
	v_accvgpr_read_b32 v48, a64
	v_accvgpr_read_b32 v58, a58
	v_accvgpr_read_b32 v57, a57
	v_accvgpr_read_b32 v56, a56
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[64:67], v[64:67], v[76:79], a[116:119], v91, v90 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v89, v52, v25
	v_lshlrev_b16_e32 v52, 8, v85
	v_lshlrev_b16_e32 v85, 8, v87
	v_accvgpr_write_b32 a119, v59
	v_accvgpr_write_b32 a118, v58
	v_accvgpr_write_b32 a117, v57
	v_accvgpr_write_b32 a116, v56
	ds_read_b128 v[56:59], v89 offset:4096
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[68:71], v[76:79], a[112:115], v91, v90 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v52, v84, v52
	v_accvgpr_read_b32 v55, a51
	v_accvgpr_read_b32 v47, a55
	v_mfma_scale_f32_16x16x128_f8f6f4 a[96:99], v[14:17], v[76:79], a[96:99], v88, v90 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v46, a54
	v_accvgpr_read_b32 v45, a53
	v_accvgpr_read_b32 v44, a52
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[84:87], v[80:83], v[76:79], a[84:87], v88, v90 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v76, v86, v85 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_accvgpr_read_b32 v54, a50
	v_or_b32_sdwa v76, v52, v76 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_accvgpr_read_b32 v53, a49
	v_mfma_scale_f32_16x16x128_f8f6f4 a[50:53], v[64:67], v[60:63], a[124:127], v91, v90 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v52, a48
	s_add_u32 s16, s2, s0
	s_mov_b32 s40, s14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[54:57], v[68:71], v[60:63], a[120:123], v91, v90 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s14, s3, s1
	s_add_u32 s8, s4, s0
	s_mov_b32 s41, s15
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[14:17], v[60:63], a[92:95], v88, v90 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_write_b32 a123, v51
	v_accvgpr_write_b32 a122, v50
	v_accvgpr_write_b32 a121, v49
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[80:83], v[60:63], a[80:83], v88, v90 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[60:63], v89 offset:6144
	v_accvgpr_write_b32 a120, v48
	s_addc_u32 s15, s5, s1
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[128:131], v[64:67], v[56:59], a[116:119], v91, v76 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s17, s29, 1
	s_cmp_lt_i32 s17, 3
	v_readlane_b32 s9, v0, 0
	v_accvgpr_write_b32 a119, v55
	v_accvgpr_write_b32 a118, v54
	v_accvgpr_write_b32 a117, v53
	v_accvgpr_write_b32 a116, v52
	ds_read_u8 v52, v43 offset:512
	ds_read_u8 v53, v43 offset:576
	ds_read_u8 v54, v43 offset:640
	v_mfma_scale_f32_16x16x128_f8f6f4 a[132:135], v[68:71], v[56:59], a[116:119], v91, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v55, v43 offset:704
	ds_read_u8 v77, v43 offset:768
	ds_read_u8 v78, v43 offset:832
	v_accvgpr_write_b32 a119, v47
	v_accvgpr_write_b32 a118, v46
	v_accvgpr_write_b32 a117, v45
	v_accvgpr_write_b32 a116, v44
	v_mfma_scale_f32_16x16x128_f8f6f4 a[88:91], v[14:17], v[56:59], a[88:91], v88, v76 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v53, 8, v53
	s_waitcnt lgkmcnt(2)
	v_lshlrev_b16_e32 v55, 8, v55
	v_or_b32_e32 v52, v52, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 a[100:103], v[80:83], v[56:59], a[100:103], v88, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v56, v43 offset:896
	ds_read_u8 v43, v43 offset:960
	ds_read_b128 v[44:47], v89 offset:8192
	ds_read_b128 v[48:51], v89 offset:10240
	v_or_b32_sdwa v53, v54, v55 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v57, 8, v78
	v_or_b32_sdwa v79, v52, v53 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[52:55], v89 offset:14336
	s_waitcnt lgkmcnt(3)
	v_lshlrev_b16_e32 v43, 8, v43
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[140:143], v[64:67], v[44:47], a[116:119], v91, v79 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v43, v56, v43 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_cselect_b32 s29, s17, 0
	s_mov_b32 s42, s33
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[68:71], v[44:47], a[44:47], v91, v79 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_mov_b32 s37, s25
	s_lshl_b32 s17, s9, 2
	s_lshl_b32 s9, s9, 4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[14:17], v[44:47], a[32:35], v88, v79 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b32 s15, s15, 0xffff
	s_lshl_b32 s25, s29, 10
	s_lshl_b32 s33, s29, 11
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[80:83], v[44:47], a[28:31], v88, v79 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[44:47], v89 offset:12288
	s_and_b32 s46, s9, 0xc00
	s_or_b32 s9, s15, s38
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[64:67], v[48:51], a[40:43], v91, v79 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s15, s25, 0
	s_add_i32 s47, s33, 0
	s_and_b32 s21, s39, 0xffff
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[68:71], v[48:51], a[36:39], v91, v79 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b32 s14, s14, 0xffff
	s_and_b32 s44, s17, 0x300
	s_lshl_b32 s45, s29, 14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[104:107], v[14:17], v[48:51], a[104:107], v88, v79 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s33, s15, 0x25800
	s_add_i32 s15, s47, 0x24000
	s_mov_b32 s20, s27
	v_mfma_scale_f32_16x16x128_f8f6f4 a[76:79], v[80:83], v[48:51], a[76:79], v88, v79 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v48, v77, v57
	v_or_b32_sdwa v43, v48, v43 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u32_e32 v48, v73, v27
	v_mfma_scale_f32_16x16x128_f8f6f4 a[108:111], v[14:17], v[60:63], a[108:111], v88, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b32 s43, s26, 0xffff
	s_or_b32 s21, s21, s31
	s_or_b32 s17, s14, s36
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[64:67], v[44:47], a[60:63], v91, v43 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_lshl_b32 s14, s29, 15
	s_add_i32 s45, s45, 0
	s_add_i32 m0, s33, s44
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[68:71], v[44:47], a[24:27], v91, v43 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s44, s15, s44
	s_add_i32 s25, s14, 0
	s_add_i32 s14, s45, 0x18000
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[14:17], v[44:47], a[12:15], v88, v43 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s54, s44, 0x400
	s_add_i32 s45, s25, s46
	s_add_i32 s46, s14, s46
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[80:83], v[44:47], a[8:11], v88, v43 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[44:47], v48 offset:16384
	s_mov_b32 s18, s22
	s_mov_b32 s19, s23
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[14:17], v[52:55], a[4:7], v88, v43 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[14:17], v48
	ds_read_b128 v[48:51], v48 offset:18432
	s_add_i32 s55, s46, 0x2000
	v_mfma_scale_f32_16x16x128_f8f6f4 a[136:139], v[64:67], v[60:63], a[120:123], v91, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s56, s46, 0x3000
	s_mov_b32 s10, s22
	s_mov_b32 s11, s23
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[64:67], v[52:55], a[20:23], v91, v43 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v64, v72, v25
	s_add_i32 s47, s45, 0x1000
	s_add_i32 s48, s45, 0x2000
	v_mfma_scale_f32_16x16x128_f8f6f4 a[68:71], v[68:71], v[60:63], a[68:71], v91, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s49, s45, 0x3000
	s_add_i32 s50, s45, 0x4000
	s_add_i32 s51, s45, 0x5000
	v_mfma_scale_f32_16x16x128_f8f6f4 a[72:75], v[80:83], v[60:63], a[72:75], v88, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s52, s45, 0x6000
	s_add_i32 s53, s45, 0x7000
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[68:71], v[52:55], a[16:19], v91, v43 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[80:83], v[52:55], a[0:3], v88, v43 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[124:127], v[14:17], v[6:9], a[50:53], v91, v90 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[120:123], v[2:5], v[6:9], a[54:57], v91, v90 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[116:119], v[14:17], v[10:13], a[64:67], v91, v90 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[2:5], v[10:13], a[112:115], v91, v90 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[44:47], v[6:9], a[92:95], v88, v90 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[48:51], v[6:9], a[80:83], v88, v90 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[96:99], v[44:47], v[10:13], a[96:99], v88, v90 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[84:87], v[48:51], v[10:13], a[84:87], v88, v90 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[6:9], v64 offset:4096
	ds_read_b128 v[10:13], v64 offset:6144
	ds_read_b128 v[52:55], v64 offset:8192
	ds_read_b128 v[56:59], v64 offset:10240
	ds_read_b128 v[60:63], v64 offset:12288
	ds_read_b128 v[64:67], v64 offset:14336
	buffer_load_dword v22, s[20:23], 0 offen lds
	s_or_b32 s21, s43, s35
	s_mov_b32 s20, s24
	s_mov_b32 m0, s44
	s_add_i32 s43, s46, 0x1000
	buffer_load_dword v18, s[20:23], 0 offen sc0 nt lds
	s_mov_b32 m0, s54
	s_add_u32 s24, s24, 0x100
	buffer_load_dword v20, s[20:23], 0 offen sc0 nt lds
	s_mov_b32 m0, s46
	s_addc_u32 s26, s26, 0
	buffer_load_dwordx4 v24, s[16:19], 0 offen lds
	s_mov_b32 m0, s43
	s_add_u32 s0, s0, 0x80
	buffer_load_dwordx4 v26, s[16:19], 0 offen lds
	s_mov_b32 m0, s55
	s_waitcnt lgkmcnt(5)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[56:59], v[14:17], v[6:9], a[128:131], v91, v76 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_load_dwordx4 v28, s[16:19], 0 offen lds
	s_mov_b32 m0, s56
	s_addc_u32 s1, s1, 0
	buffer_load_dwordx4 v30, s[16:19], 0 offen lds
	s_mov_b32 m0, s45
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[2:5], v[6:9], a[132:135], v91, v76 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_load_dwordx4 v32, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s47
	s_add_u32 s27, s27, 0x100
	buffer_load_dwordx4 v34, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s48
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[64:67], v[14:17], v[10:13], a[136:139], v91, v76 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_load_dwordx4 v36, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s49
	s_addc_u32 s39, s39, 0
	buffer_load_dwordx4 v38, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s50
	v_mfma_scale_f32_16x16x128_f8f6f4 a[68:71], v[2:5], v[10:13], a[68:71], v91, v76 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_load_dwordx4 v33, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s51
	s_cmpk_lg_i32 s0, 0x2000
	buffer_load_dwordx4 v35, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s52
	v_mfma_scale_f32_16x16x128_f8f6f4 a[88:91], v[44:47], v[6:9], a[88:91], v88, v76 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_load_dwordx4 v37, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s53
	s_nop 0
	buffer_load_dwordx4 v39, s[8:11], 0 offen sc0 nt lds
	v_mfma_scale_f32_16x16x128_f8f6f4 a[100:103], v[48:51], v[6:9], a[100:103], v88, v76 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[108:111], v[44:47], v[10:13], a[108:111], v88, v76 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[72:75], v[48:51], v[10:13], a[72:75], v88, v76 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[52:55], v[14:17], v[52:55], a[140:143], v91, v79 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[2:5], v[52:55], a[44:47], v91, v79 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[14:17], v[56:59], a[40:43], v91, v79 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[2:5], v[56:59], a[36:39], v91, v79 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[44:47], v[52:55], a[32:35], v88, v79 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[48:51], v[52:55], a[28:31], v88, v79 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[104:107], v[44:47], v[56:59], a[104:107], v88, v79 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[76:79], v[48:51], v[56:59], a[76:79], v88, v79 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[14:17], v[60:63], a[60:63], v91, v43 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[2:5], v[60:63], a[24:27], v91, v43 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[14:17], v[64:67], a[20:23], v91, v43 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[2:5], v[64:67], a[16:19], v91, v43 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[44:47], v[60:63], a[12:15], v88, v43 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[48:51], v[60:63], a[8:11], v88, v43 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[44:47], v[64:67], a[4:7], v88, v43 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[48:51], v[64:67], a[0:3], v88, v43 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_2
; %bb.3:
	v_add_u32_e32 v18, s42, v19
	s_waitcnt vmcnt(0)
	s_barrier
	ds_read_u8 v20, v18
	ds_read_u8 v22, v18 offset:64
	ds_read_u8 v24, v18 offset:128
	ds_read_u8 v26, v18 offset:192
	ds_read_u8 v46, v18 offset:256
	ds_read_u8 v47, v18 offset:320
	ds_read_u8 v48, v18 offset:384
	ds_read_u8 v49, v18 offset:448
	v_or_b32_e32 v50, v19, v42
	v_add_u32_e32 v51, v19, v42
	s_waitcnt lgkmcnt(6)
	v_lshlrev_b16_e32 v22, 8, v22
	v_add_u32_e32 v2, s41, v50
	v_add_u32_e32 v52, 0x400, v51
	v_or_b32_e32 v20, v20, v22
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v22, 8, v26
	v_add_u32_e32 v3, s41, v51
	v_add_u32_e32 v4, s41, v52
	ds_read_u8 v28, v2
	ds_read_u8 v30, v3 offset:64
	ds_read_u8 v32, v3 offset:128
	ds_read_u8 v33, v3 offset:192
	ds_read_u8 v53, v3 offset:1024
	ds_read_u8 v54, v4 offset:64
	ds_read_u8 v55, v4 offset:128
	ds_read_u8 v56, v4 offset:192
	v_or_b32_sdwa v22, v24, v22 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v24, 8, v33
	v_or_b32_sdwa v20, v20, v22 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshlrev_b16_e32 v22, 8, v30
	v_or_b32_e32 v57, v21, v41
	v_or_b32_e32 v41, v23, v41
	v_or_b32_e32 v73, v27, v21
	v_or_b32_e32 v116, v23, v27
	v_or_b32_e32 v117, v31, v21
	v_or_b32_e32 v22, v28, v22
	v_or_b32_sdwa v24, v32, v24 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_e32 v118, v23, v31
	v_add_u32_e32 v2, s40, v57
	v_add_u32_e32 v6, s40, v41
	v_add_u32_e32 v10, s37, v73
	v_add_u32_e32 v14, s37, v116
	v_add_u32_e32 v34, s37, v117
	v_or_b32_sdwa v58, v22, v24 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u32_e32 v22, s37, v118
	v_or_b32_e32 v59, v21, v29
	ds_read_b128 v[2:5], v2
	ds_read_b128 v[6:9], v6
	ds_read_b128 v[10:13], v10
	ds_read_b128 v[14:17], v14
	ds_read_b128 v[32:35], v34
	ds_read_b128 v[36:39], v22
	v_add_u32_e32 v22, s40, v59
	v_or_b32_e32 v64, v23, v29
	ds_read_b128 v[42:45], v22
	v_add_u32_e32 v22, s40, v64
	v_add_u32_e32 v119, v27, v21
	ds_read_b128 v[28:31], v22
	v_add_u32_e32 v22, s37, v119
	ds_read_b128 v[60:63], v22 offset:16384
	ds_read_b128 v[80:83], v22 offset:18432
	v_add_u32_e32 v120, v23, v27
	s_waitcnt lgkmcnt(12)
	v_lshlrev_b16_e32 v22, 8, v54
	s_waitcnt lgkmcnt(10)
	v_lshlrev_b16_e32 v26, 8, v56
	v_add_u32_e32 v24, s37, v120
	v_or_b32_e32 v22, v53, v22
	v_or_b32_sdwa v26, v55, v26 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	ds_read_b128 v[84:87], v24 offset:16384
	ds_read_b128 v[88:91], v24 offset:18432
	v_or_b32_sdwa v121, v22, v26 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[124:127], v[10:13], v[2:5], a[124:127], v58, v20 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v53, v21, v25
	v_add_u32_e32 v54, s40, v53
	v_lshlrev_b16_e32 v21, 8, v47
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[80:83], v[2:5], a[80:83], v121, v20 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v55, v23, v25
	v_or_b32_e32 v21, v46, v21
	v_add_u32_e32 v56, s40, v55
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[128:131], v[88:91], v[6:9], a[80:83], v121, v20 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_lshrrev_b32_e32 v0, 2, v0
	v_and_b32_e32 v0, 12, v0
	v_or3_b32 v79, v1, v0, v40
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[60:63], v[42:45], a[96:99], v121, v20 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v0, s33, v19
	v_add_u32_e32 v1, s15, v51
	v_or_b32_e32 v72, s13, v74
	v_mfma_scale_f32_16x16x128_f8f6f4 a[120:123], v[32:35], v[2:5], a[120:123], v58, v20 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mul_lo_u32 v74, s30, v74
	s_lshl_b32 s2, s30, 4
	s_ashr_i32 s0, s13, 31
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[60:63], v[2:5], a[92:95], v121, v20 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_mul_hi_i32 s1, s13, s30
	s_ashr_i32 s35, s34, 31
	v_or_b32_e32 v78, 16, v79
	v_mfma_scale_f32_16x16x128_f8f6f4 a[136:139], v[14:17], v[6:9], a[124:127], v58, v20 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_or_b32_e32 v77, 0x80, v79
	v_mfma_scale_f32_16x16x128_f8f6f4 a[116:119], v[10:13], v[42:45], a[116:119], v58, v20 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v76, 0x90, v79
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[32:35], v[42:45], a[112:115], v58, v20 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[124:127], v[84:87], v[28:31], a[80:83], v121, v20 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[80:83], v[42:45], a[84:87], v121, v20 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[140:143], v[36:39], v[6:9], a[120:123], v58, v20 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[132:135], v[84:87], v[6:9], a[92:95], v121, v20 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[2:5], v54 offset:4096
	ds_read_b128 v[6:9], v54 offset:6144
	v_mfma_scale_f32_16x16x128_f8f6f4 a[144:147], v[14:17], v[28:31], a[116:119], v58, v20 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[148:151], v[36:39], v[28:31], a[112:115], v58, v20 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[120:123], v[88:91], v[28:31], a[80:83], v121, v20 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_lshlrev_b16_e32 v20, 8, v49
	v_or_b32_sdwa v20, v48, v20 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_nop 0
	v_or_b32_sdwa v28, v21, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[20:23], v56 offset:4096
	ds_read_b128 v[24:27], v56 offset:6144
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[32:35], v[2:5], a[48:51], v58, v28 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[36:39], v[20:23], a[48:51], v58, v28 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[10:13], v[6:9], a[64:67], v58, v28 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[96:99], v[14:17], v[24:27], a[48:51], v58, v28 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[32:35], v[6:9], a[68:71], v58, v28 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[36:39], v[24:27], a[48:51], v58, v28 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[60:63], v[2:5], a[88:91], v121, v28 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[88:91], v[84:87], v[20:23], a[48:51], v121, v28 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[80:83], v[2:5], a[100:103], v121, v28 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[56:59], v[10:13], v[2:5], a[56:59], v58, v28 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[84:87], v[88:91], v[20:23], a[48:51], v121, v28 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[60:63], v[6:9], a[108:111], v121, v28 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[116:119], v[14:17], v[20:23], a[56:59], v58, v28 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_u8 v20, v18 offset:512
	ds_read_u8 v21, v18 offset:576
	ds_read_u8 v22, v18 offset:640
	ds_read_u8 v23, v18 offset:704
	ds_read_u8 v29, v18 offset:768
	ds_read_u8 v30, v18 offset:832
	ds_read_u8 v31, v18 offset:896
	ds_read_u8 v18, v18 offset:960
	s_waitcnt lgkmcnt(6)
	v_lshlrev_b16_e32 v21, 8, v21
	v_or_b32_e32 v20, v20, v21
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[84:87], v[24:27], a[48:51], v121, v28 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(4)
	v_lshlrev_b16_e32 v21, 8, v23
	v_or_b32_sdwa v21, v22, v21 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[80:83], v[6:9], a[72:75], v121, v28 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[2:5], v54 offset:8192
	ds_read_b128 v[6:9], v54 offset:10240
	v_mfma_scale_f32_16x16x128_f8f6f4 a[68:71], v[88:91], v[24:27], a[48:51], v121, v28 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_sdwa v28, v20, v21 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[20:23], v56 offset:8192
	ds_read_b128 v[24:27], v56 offset:10240
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[10:13], v[6:9], a[40:43], v58, v28 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[80:83], v[2:5], a[28:31], v121, v28 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[10:13], v[2:5], a[52:55], v58, v28 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[32:35], v[2:5], a[44:47], v58, v28 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[52:55], v[14:17], v[24:27], a[40:43], v58, v28 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[32:35], v[6:9], a[36:39], v58, v28 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[60:63], v[2:5], a[32:35], v121, v28 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[88:91], v[20:23], a[28:31], v121, v28 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[60:63], v[6:9], a[104:107], v121, v28 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[64:67], v[14:17], v[20:23], a[48:51], v58, v28 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[56:59], v[36:39], v[20:23], a[44:47], v58, v28 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[36:39], v[24:27], a[36:39], v58, v28 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[84:87], v[20:23], a[32:35], v121, v28 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[2:5], v54 offset:12288
	ds_read_b128 v[20:23], v54 offset:14336
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[84:87], v[24:27], a[28:31], v121, v28 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[80:83], v[6:9], a[76:79], v121, v28 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_lshlrev_b16_e32 v6, 8, v30
	v_lshlrev_b16_e32 v7, 8, v18
	v_or_b32_e32 v6, v29, v6
	v_or_b32_sdwa v7, v31, v7 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[88:91], v[24:27], a[28:31], v121, v28 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_sdwa v42, v6, v7 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	ds_read_b128 v[6:9], v56 offset:12288
	ds_read_b128 v[24:27], v56 offset:14336
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[10:13], v[2:5], a[60:63], v58, v42 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v40, v0
	ds_read_u8 v43, v0 offset:64
	ds_read_u8 v44, v0 offset:128
	ds_read_u8 v45, v0 offset:192
	ds_read_u8 v122, v0 offset:256
	ds_read_u8 v123, v0 offset:320
	ds_read_u8 v124, v0 offset:384
	ds_read_u8 v125, v0 offset:448
	ds_read_u8 v126, v0 offset:512
	ds_read_u8 v127, v0 offset:576
	ds_read_u8 v128, v0 offset:640
	ds_read_u8 v129, v0 offset:704
	ds_read_u8 v130, v0 offset:768
	ds_read_u8 v131, v0 offset:832
	ds_read_u8 v132, v0 offset:896
	ds_read_u8 v133, v0 offset:960
	v_add_u32_e32 v0, s15, v50
	s_waitcnt lgkmcnt(14)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[10:13], v[20:23], a[20:23], v58, v42 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v10, s15, v52
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[32:35], v[2:5], a[24:27], v58, v42 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[32:35], v[20:23], a[16:19], v58, v42 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[60:63], v[2:5], a[12:15], v121, v42 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[80:83], v[2:5], a[8:11], v121, v42 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[14:17], v[6:9], a[28:31], v58, v42 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[14:17], v[24:27], a[20:23], v58, v42 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_u8 v11, v0
	ds_read_u8 v12, v1 offset:64
	ds_read_u8 v13, v1 offset:128
	ds_read_u8 v14, v1 offset:192
	ds_read_u8 v134, v1 offset:1024
	ds_read_u8 v135, v10 offset:64
	ds_read_u8 v136, v10 offset:128
	ds_read_u8 v137, v10 offset:192
	v_add_u32_e32 v0, s14, v57
	v_add_u32_e32 v1, s14, v41
	ds_read_b128 v[92:95], v0
	ds_read_b128 v[96:99], v1
	v_add_u32_e32 v0, s14, v59
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[36:39], v[6:9], a[24:27], v58, v42 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_add_u32_e32 v1, s14, v64
	ds_read_b128 v[100:103], v0
	ds_read_b128 v[104:107], v1
	v_add_u32_e32 v10, s14, v53
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[36:39], v[24:27], a[16:19], v58, v42 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_add_u32_e32 v36, s14, v55
	v_add_u32_e32 v0, 0, v73
	ds_read_b128 v[108:111], v10 offset:4096
	ds_read_b128 v[68:71], v10 offset:6144
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[84:87], v[6:9], a[12:15], v121, v42 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[112:115], v36 offset:4096
	ds_read_b128 v[64:67], v36 offset:6144
	ds_read_b128 v[52:55], v10 offset:8192
	ds_read_b128 v[48:51], v10 offset:10240
	ds_read_b128 v[56:59], v36 offset:8192
	ds_read_b128 v[28:31], v36 offset:10240
	v_add_u32_e32 v1, 0, v116
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[88:91], v[6:9], a[8:11], v121, v42 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[16:19], v0
	ds_read_b128 v[4:7], v1
	v_add_u32_e32 v0, 0, v117
	v_lshlrev_b16_e32 v8, 8, v43
	s_waitcnt lgkmcnt(14)
	v_lshlrev_b16_e32 v9, 8, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[60:63], v[20:23], a[4:7], v121, v42 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[0:3], v0
	v_or_b32_e32 v8, v40, v8
	v_or_b32_sdwa v9, v44, v9 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[80:83], v[20:23], a[0:3], v121, v42 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v116, v8, v9 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshlrev_b16_e32 v8, 8, v12
	v_lshlrev_b16_e32 v9, 8, v14
	v_or_b32_e32 v8, v11, v8
	v_or_b32_sdwa v9, v13, v9 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[84:87], v[24:27], a[4:7], v121, v42 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_sdwa v117, v8, v9 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u32_e32 v8, 0, v118
	v_add_u32_e32 v20, 0, v119
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[88:91], v[24:27], a[0:3], v121, v42 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	ds_read_b128 v[40:43], v10 offset:12288
	ds_read_b128 v[12:15], v10 offset:14336
	ds_read_b128 v[60:63], v8
	ds_read_b128 v[32:35], v36 offset:12288
	ds_read_b128 v[8:11], v36 offset:14336
	s_waitcnt lgkmcnt(7)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[16:19], v[92:95], a[136:139], v117, v116 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[44:47], v20 offset:16384
	ds_read_b128 v[24:27], v20 offset:18432
	v_lshlrev_b16_e32 v73, 8, v123
	v_lshlrev_b16_e32 v80, 8, v125
	s_waitcnt lgkmcnt(8)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[72:75], v[4:7], v[96:99], a[60:63], v117, v116 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_e32 v73, v122, v73
	v_or_b32_sdwa v80, v124, v80 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_lshlrev_b16_e32 v81, 8, v135
	s_waitcnt lgkmcnt(7)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[0:3], v[92:95], a[140:143], v117, v116 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v118, v73, v80 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshlrev_b16_e32 v73, 8, v127
	v_lshlrev_b16_e32 v80, 8, v129
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[76:79], v[60:63], v[96:99], a[60:63], v117, v116 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_lshlrev_b16_e32 v82, 8, v137
	v_add_u32_e32 v21, 0, v120
	v_or_b32_e32 v73, v126, v73
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[16:19], v[100:103], a[144:147], v117, v116 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v80, v128, v80 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_e32 v81, v134, v81
	v_or_b32_sdwa v82, v136, v82 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	ds_read_b128 v[36:39], v21 offset:16384
	ds_read_b128 v[20:23], v21 offset:18432
	v_or_b32_sdwa v119, v81, v82 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_or_b32_sdwa v120, v73, v80 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_lshlrev_b16_e32 v73, 8, v131
	v_lshlrev_b16_e32 v80, 8, v133
	v_mfma_scale_f32_16x16x128_f8f6f4 a[100:103], v[4:7], v[104:107], a[60:63], v117, v116 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_e32 v73, v130, v73
	v_or_b32_sdwa v80, v132, v80 dst_sel:WORD_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mov_b32_e32 v81, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[0:3], v[100:103], a[148:151], v117, v116 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_sdwa v121, v73, v80 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_or_b32_e32 v80, s13, v75
	v_add_u32_e32 v75, s2, v74
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[124:127], v[44:47], v[100:103], a[124:127], v119, v116 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v73, s0
	v_mov_b32_e32 v83, s0
	v_mov_b32_e32 v85, s0
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[120:123], v[24:27], v[100:103], a[120:123], v119, v116 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v102, s2, v75
	v_add_u32_e32 v103, s2, v102
	v_mov_b32_e32 v87, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[104:107], v[60:63], v[104:107], a[60:63], v117, v116 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mov_b32_e32 v89, s0
	v_mov_b32_e32 v91, s0
	v_or_b32_e32 v82, 32, v72
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[124:127], v[36:39], v[104:107], a[124:127], v119, v116 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_e32 v84, 48, v72
	v_or_b32_e32 v86, 64, v72
	v_or_b32_e32 v88, 0x50, v72
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[120:123], v[20:23], v[104:107], a[120:123], v119, v116 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_add_u32_e32 v104, s2, v103
	v_add_u32_e32 v105, s2, v104
	v_add_u32_e32 v106, s2, v105
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[44:47], v[92:95], a[132:135], v119, v116 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v107, s2, v106
	v_or_b32_e32 v90, 0x60, v72
	v_or_b32_e32 v100, s34, v76
	v_mfma_scale_f32_16x16x128_f8f6f4 a[108:111], v[24:27], v[92:95], a[128:131], v119, v116 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v93, s0
	s_mul_i32 s0, s13, s30
	s_lshl_b64 s[0:1], s[0:1], 1
	s_add_u32 s2, s6, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[96:99], v[16:19], v[68:71], a[96:99], v117, v118 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s3, s7, s1
	s_lshl_b64 s[0:1], s[34:35], 1
	s_add_u32 s24, s2, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[0:3], v[68:71], a[92:95], v117, v118 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v94, s34, v79
	v_mov_b32_e32 v95, s35
	s_addc_u32 s25, s3, s1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[44:47], v[68:71], a[80:83], v119, v118 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_ashr_i32 s13, s12, 31
	s_ashr_i32 s29, s28, 31
	v_or_b32_e32 v92, 0x70, v72
	v_mfma_scale_f32_16x16x128_f8f6f4 a[68:71], v[24:27], v[68:71], a[68:71], v119, v118 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cmp_gt_i64_e64 s[22:23], s[12:13], v[72:73]
	v_cmp_gt_i64_e64 s[8:9], s[28:29], v[94:95]
	v_cmp_gt_i64_e64 s[20:21], s[12:13], v[80:81]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[96:99], v[4:7], v[64:67], a[96:99], v117, v118 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_cmp_gt_i64_e64 s[18:19], s[12:13], v[82:83]
	v_cmp_gt_i64_e64 s[16:17], s[12:13], v[84:85]
	v_cmp_gt_i64_e64 s[14:15], s[12:13], v[86:87]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[92:95], v[60:63], v[64:67], a[92:95], v117, v118 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_cmp_gt_i64_e64 s[10:11], s[12:13], v[88:89]
	v_cmp_gt_i64_e64 s[4:5], s[12:13], v[90:91]
	v_cmp_gt_i64_e32 vcc, s[12:13], v[92:93]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[80:83], v[36:39], v[64:67], a[80:83], v119, v118 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v72, a75
	v_accvgpr_read_b32 v73, a74
	v_accvgpr_read_b32 v68, a73
	v_accvgpr_read_b32 v70, a72
	v_mfma_scale_f32_16x16x128_f8f6f4 a[68:71], v[20:23], v[64:67], a[68:71], v119, v118 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_add_lshl_u32 v64, v74, v79, 1
	v_bfrev_b32_e32 v66, 1
	s_and_b64 s[12:13], s[8:9], s[22:23]
	s_and_b32 s25, s25, 0xffff
	v_cvt_pk_bf16_f32 v69, v73, v72
	v_cvt_pk_bf16_f32 v68, v70, v68
	v_cndmask_b32_e64 v64, v66, v64, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[60:63], v[36:39], v[96:99], a[60:63], v119, v116 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[68:69], v64, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v64, a79
	v_accvgpr_read_b32 v65, a78
	v_mfma_scale_f32_16x16x128_f8f6f4 a[108:111], v[20:23], v[96:99], a[108:111], v119, v116 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_or_b32_e32 v96, s34, v78
	v_mov_b32_e32 v97, s35
	v_cmp_gt_i64_e64 s[6:7], s[28:29], v[96:97]
	v_cvt_pk_bf16_f32 v65, v65, v64
	v_accvgpr_read_b32 v64, a77
	v_accvgpr_read_b32 v67, a76
	v_cvt_pk_bf16_f32 v64, v67, v64
	v_add_lshl_u32 v67, v74, v78, 1
	s_and_b64 s[12:13], s[6:7], s[22:23]
	v_cndmask_b32_e64 v67, v66, v67, s[12:13]
	buffer_store_dwordx2 v[64:65], v67, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v64, a103
	v_accvgpr_read_b32 v65, a102
	v_cvt_pk_bf16_f32 v65, v65, v64
	v_accvgpr_read_b32 v64, a101
	v_accvgpr_read_b32 v67, a100
	v_cvt_pk_bf16_f32 v64, v67, v64
	v_add_lshl_u32 v67, v75, v79, 1
	s_and_b64 s[12:13], s[8:9], s[20:21]
	v_cndmask_b32_e64 v67, v66, v67, s[12:13]
	buffer_store_dwordx2 v[64:65], v67, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v64, a107
	v_accvgpr_read_b32 v65, a106
	v_cvt_pk_bf16_f32 v65, v65, v64
	v_accvgpr_read_b32 v64, a105
	v_accvgpr_read_b32 v67, a104
	v_cvt_pk_bf16_f32 v64, v67, v64
	v_add_lshl_u32 v67, v75, v78, 1
	s_and_b64 s[12:13], s[6:7], s[20:21]
	v_cndmask_b32_e64 v67, v66, v67, s[12:13]
	v_or_b32_e32 v98, s34, v77
	v_mov_b32_e32 v99, s35
	v_mfma_scale_f32_16x16x128_f8f6f4 a[64:67], v[16:19], v[52:55], a[64:67], v117, v120 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[64:65], v67, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v64, a63
	v_cmp_gt_i64_e64 s[2:3], s[28:29], v[98:99]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[56:59], v[0:3], v[52:55], a[56:59], v117, v120 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b64 s[12:13], s[2:3], s[22:23]
	v_mov_b32_e32 v101, s35
	v_cmp_gt_i64_e64 s[0:1], s[28:29], v[100:101]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[44:47], v[52:55], a[44:47], v119, v120 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[24:27], v[52:55], a[40:43], v119, v120 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v52, a62
	v_cvt_pk_bf16_f32 v53, v52, v64
	v_accvgpr_read_b32 v52, a61
	v_accvgpr_read_b32 v54, a60
	v_cvt_pk_bf16_f32 v52, v54, v52
	v_add_lshl_u32 v54, v74, v77, 1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[52:55], v[16:19], v[48:51], a[52:55], v117, v120 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cndmask_b32_e64 v54, v66, v54, s[12:13]
	buffer_store_dwordx2 v[52:53], v54, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v52, a111
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[0:3], v[48:51], a[48:51], v117, v120 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v53, a110
	v_cvt_pk_bf16_f32 v53, v53, v52
	v_accvgpr_read_b32 v52, a109
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[44:47], v[48:51], a[36:39], v119, v120 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b64 s[12:13], s[0:1], s[22:23]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[24:27], v[48:51], a[32:35], v119, v120 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v48, a108
	v_cvt_pk_bf16_f32 v52, v48, v52
	v_add_lshl_u32 v48, v74, v76, 1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[52:55], v[4:7], v[28:31], a[52:55], v117, v120 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[48:51], v[60:63], v[28:31], a[48:51], v117, v120 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[36:39], v[36:39], v[28:31], a[36:39], v119, v120 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[32:35], v[20:23], v[28:31], a[32:35], v119, v120 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_cndmask_b32_e64 v28, v66, v48, s[12:13]
	buffer_store_dwordx2 v[52:53], v28, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v28, a127
	v_mfma_scale_f32_16x16x128_f8f6f4 a[116:119], v[16:19], v[108:111], a[116:119], v117, v118 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v29, a126
	v_cvt_pk_bf16_f32 v29, v29, v28
	v_accvgpr_read_b32 v28, a125
	v_accvgpr_read_b32 v30, a124
	v_cvt_pk_bf16_f32 v28, v30, v28
	v_add_lshl_u32 v30, v75, v77, 1
	s_and_b64 s[12:13], s[2:3], s[20:21]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[16:19], v[40:43], a[28:31], v117, v121 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cndmask_b32_e64 v30, v66, v30, s[12:13]
	buffer_store_dwordx2 v[28:29], v30, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v28, a123
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[16:19], v[12:15], a[20:23], v117, v121 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v29, a122
	v_cvt_pk_bf16_f32 v29, v29, v28
	v_accvgpr_read_b32 v28, a121
	v_mfma_scale_f32_16x16x128_f8f6f4 a[116:119], v[4:7], v[112:115], a[116:119], v117, v118 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v16, a120
	v_cvt_pk_bf16_f32 v28, v16, v28
	v_add_lshl_u32 v16, v75, v76, 1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[0:3], v[108:111], a[112:115], v117, v118 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_and_b64 s[12:13], s[0:1], s[20:21]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[64:67], v[4:7], v[56:59], a[64:67], v117, v120 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[28:31], v[4:7], v[32:35], a[28:31], v117, v121 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[20:23], v[4:7], v[8:11], a[20:23], v117, v121 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	v_cndmask_b32_e64 v4, v66, v16, s[12:13]
	buffer_store_dwordx2 v[28:29], v4, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v4, a119
	v_mfma_scale_f32_16x16x128_f8f6f4 a[112:115], v[60:63], v[112:115], a[112:115], v117, v118 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	s_and_b64 s[12:13], s[8:9], s[18:19]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[0:3], v[40:43], a[24:27], v117, v121 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[0:3], v[12:15], a[16:19], v117, v121 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_accvgpr_read_b32 v0, a118
	v_cvt_pk_bf16_f32 v1, v0, v4
	v_accvgpr_read_b32 v0, a117
	v_accvgpr_read_b32 v2, a116
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v102, v79, 1
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a115
	v_accvgpr_read_b32 v1, a114
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a113
	v_accvgpr_read_b32 v2, a112
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v102, v78, 1
	s_and_b64 s[12:13], s[6:7], s[18:19]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[88:91], v[44:47], v[108:111], a[88:91], v119, v118 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a99
	v_accvgpr_read_b32 v1, a98
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a97
	v_accvgpr_read_b32 v2, a96
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v103, v79, 1
	s_and_b64 s[12:13], s[8:9], s[16:17]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[88:91], v[36:39], v[112:115], a[88:91], v119, v118 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a95
	v_accvgpr_read_b32 v1, a94
	v_mfma_scale_f32_16x16x128_f8f6f4 a[84:87], v[24:27], v[108:111], a[84:87], v119, v118 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a93
	v_accvgpr_read_b32 v2, a92
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v103, v78, 1
	s_and_b64 s[12:13], s[6:7], s[16:17]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[84:87], v[20:23], v[112:115], a[84:87], v119, v118 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a91
	v_accvgpr_read_b32 v1, a90
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a89
	v_accvgpr_read_b32 v2, a88
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v102, v77, 1
	s_and_b64 s[12:13], s[2:3], s[18:19]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a87
	v_accvgpr_read_b32 v1, a86
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a85
	v_accvgpr_read_b32 v2, a84
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v102, v76, 1
	s_and_b64 s[12:13], s[0:1], s[18:19]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a83
	v_accvgpr_read_b32 v1, a82
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a81
	v_accvgpr_read_b32 v2, a80
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v103, v77, 1
	s_and_b64 s[12:13], s[2:3], s[16:17]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a71
	v_accvgpr_read_b32 v1, a70
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a69
	v_accvgpr_read_b32 v2, a68
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v103, v76, 1
	s_and_b64 s[12:13], s[0:1], s[16:17]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[56:59], v[60:63], v[56:59], a[56:59], v117, v120 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a67
	v_accvgpr_read_b32 v1, a66
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a65
	v_accvgpr_read_b32 v2, a64
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v104, v79, 1
	s_and_b64 s[12:13], s[8:9], s[14:15]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a59
	v_accvgpr_read_b32 v1, a58
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a57
	v_accvgpr_read_b32 v2, a56
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v104, v78, 1
	s_and_b64 s[12:13], s[6:7], s[14:15]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a55
	v_accvgpr_read_b32 v1, a54
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a53
	v_accvgpr_read_b32 v2, a52
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v105, v79, 1
	s_and_b64 s[12:13], s[8:9], s[10:11]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[44:47], v[36:39], v[56:59], a[44:47], v119, v120 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a51
	v_accvgpr_read_b32 v1, a50
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a49
	v_accvgpr_read_b32 v2, a48
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v105, v78, 1
	s_and_b64 s[12:13], s[6:7], s[10:11]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[40:43], v[20:23], v[56:59], a[40:43], v119, v120 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a47
	v_accvgpr_read_b32 v1, a46
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a45
	v_accvgpr_read_b32 v2, a44
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v104, v77, 1
	s_and_b64 s[12:13], s[2:3], s[14:15]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a43
	v_accvgpr_read_b32 v1, a42
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a41
	v_accvgpr_read_b32 v2, a40
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v104, v76, 1
	s_and_b64 s[12:13], s[0:1], s[14:15]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a39
	v_accvgpr_read_b32 v1, a38
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a37
	v_accvgpr_read_b32 v2, a36
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v105, v77, 1
	s_and_b64 s[12:13], s[2:3], s[10:11]
	v_cndmask_b32_e64 v2, v66, v2, s[12:13]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a35
	v_accvgpr_read_b32 v1, a34
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a33
	v_accvgpr_read_b32 v2, a32
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v105, v76, 1
	s_and_b64 s[10:11], s[0:1], s[10:11]
	v_cndmask_b32_e64 v2, v66, v2, s[10:11]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[24:27], v[60:63], v[32:35], a[24:27], v117, v121 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a31
	v_accvgpr_read_b32 v1, a30
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a29
	v_accvgpr_read_b32 v2, a28
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v106, v79, 1
	s_and_b64 s[10:11], s[8:9], s[4:5]
	v_cndmask_b32_e64 v2, v66, v2, s[10:11]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a27
	v_accvgpr_read_b32 v1, a26
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a25
	v_accvgpr_read_b32 v2, a24
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v106, v78, 1
	s_and_b64 s[10:11], s[6:7], s[4:5]
	v_cndmask_b32_e64 v2, v66, v2, s[10:11]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[16:19], v[60:63], v[8:11], a[16:19], v117, v121 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a23
	v_accvgpr_read_b32 v1, a22
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[44:47], v[40:43], a[12:15], v119, v121 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a21
	v_accvgpr_read_b32 v2, a20
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v107, v79, 1
	s_and_b64 s[8:9], s[8:9], vcc
	v_cndmask_b32_e64 v2, v66, v2, s[8:9]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[36:39], v[32:35], a[12:15], v119, v121 op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a19
	v_accvgpr_read_b32 v1, a18
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[24:27], v[40:43], a[8:11], v119, v121 op_sel:[1,0,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a17
	v_accvgpr_read_b32 v2, a16
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v107, v78, 1
	s_and_b64 s[6:7], s[6:7], vcc
	v_cndmask_b32_e64 v2, v66, v2, s[6:7]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[20:23], v[32:35], a[8:11], v119, v121 op_sel:[1,0,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a15
	v_accvgpr_read_b32 v1, a14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[44:47], v[12:15], a[4:7], v119, v121 op_sel:[0,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a13
	v_accvgpr_read_b32 v2, a12
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v106, v77, 1
	s_and_b64 s[6:7], s[2:3], s[4:5]
	v_cndmask_b32_e64 v2, v66, v2, s[6:7]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[8:11], a[4:7], v119, v121 op_sel:[0,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a11
	v_accvgpr_read_b32 v1, a10
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[24:27], v[12:15], a[0:3], v119, v121 op_sel:[1,1,0] op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a9
	v_accvgpr_read_b32 v2, a8
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v106, v76, 1
	s_and_b64 s[4:5], s[0:1], s[4:5]
	v_cndmask_b32_e64 v2, v66, v2, s[4:5]
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[20:23], v[8:11], a[0:3], v119, v121 op_sel:[1,1,0] op_sel_hi:[1,1,0] cbsz:4 blgp:4
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a7
	v_accvgpr_read_b32 v1, a6
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a5
	v_accvgpr_read_b32 v2, a4
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v107, v77, 1
	s_and_b64 s[2:3], s[2:3], vcc
	v_cndmask_b32_e64 v2, v66, v2, s[2:3]
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
	v_accvgpr_read_b32 v0, a3
	v_accvgpr_read_b32 v1, a2
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a1
	v_accvgpr_read_b32 v2, a0
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_add_lshl_u32 v2, v107, v76, 1
	s_and_b64 vcc, s[0:1], vcc
	v_cndmask_b32_e32 v2, v66, v2, vcc
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen sc0 sc1
.LBB0_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _gemm_afp4_wfp4_kernel_preshuffled_scales
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 88
		.amdhsa_user_sgpr_count 16
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 14
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 292
		.amdhsa_next_free_sgpr 57
		.amdhsa_accum_offset 140
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_xnack_mask 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end0:
	.size	_gemm_afp4_wfp4_kernel_preshuffled_scales, .Lfunc_end0-_gemm_afp4_wfp4_kernel_preshuffled_scales
	.cfi_endproc
                                        ; -- End function
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.num_vgpr, 138
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.num_agpr, 152
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.numbered_sgpr, 57
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel_preshuffled_scales.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 13460
; TotalNumSgprs: 63
; NumVgprs: 138
; NumAgprs: 152
; TotalNumVgprs: 292
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 7
; VGPRBlocks: 36
; NumSGPRsForWavesPerEU: 63
; NumVGPRsForWavesPerEU: 292
; AccumOffset: 140
; Occupancy: 1
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 34
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.text
	.p2alignl 6, 3212836864
	.fill 256, 4, 3212836864
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	2                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	1                               ; DW_CHILDREN_yes
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	4                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	5                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	87                              ; DW_AT_call_column
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0x58 DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	2                               ; DW_AT_language
	.long	.Linfo_string1                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string2                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.byte	2                               ; Abbrev [2] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0x32 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
	.long	42                              ; DW_AT_abstract_origin
	.byte	4                               ; Abbrev [4] 0x41:0x14 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp2                          ; DW_AT_low_pc
	.long	.Ltmp3-.Ltmp2                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	232                             ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x55:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	237                             ; DW_AT_call_line
	.byte	48                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"triton"                        ; string offset=0
.Linfo_string1:
	.asciz	"gemm_afp4wfp4.py"              ; string offset=7
.Linfo_string2:
	.asciz	"/app/aiter/aiter/ops/triton"   ; string offset=24
.Linfo_string3:
	.asciz	"_gemm_afp4_wfp4_kernel_preshuffled_scales" ; string offset=52
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     152
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         24
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         32
        .size:           8
        .value_kind:     global_buffer
      - .offset:         40
        .size:           4
        .value_kind:     by_value
      - .offset:         44
        .size:           4
        .value_kind:     by_value
      - .offset:         48
        .size:           4
        .value_kind:     by_value
      - .offset:         52
        .size:           4
        .value_kind:     by_value
      - .offset:         56
        .size:           4
        .value_kind:     by_value
      - .offset:         60
        .size:           4
        .value_kind:     by_value
      - .offset:         64
        .size:           4
        .value_kind:     by_value
      - .offset:         68
        .size:           4
        .value_kind:     by_value
      - .offset:         72
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         80
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 88
    .max_flat_workgroup_size: 256
    .name:           _gemm_afp4_wfp4_kernel_preshuffled_scales
    .private_segment_fixed_size: 0
    .sgpr_count:     63
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel_preshuffled_scales.kd
    .uses_dynamic_stack: false
    .vgpr_count:     292
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.section	.debug_line,"",@progbits
.Lline_table_start0:
