	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 5
	.text
	.globl	_gemm_afp4_wfp4_kernel          ; -- Begin function _gemm_afp4_wfp4_kernel
	.p2align	8
	.type	_gemm_afp4_wfp4_kernel,@function
_gemm_afp4_wfp4_kernel:                 ; @_gemm_afp4_wfp4_kernel
.Lfunc_begin0:
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.7:
	.file	1 "/app/aiter/aiter/ops/triton" "gemm_afp4wfp4.py"
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.p2align	8
; %bb.8:
.LBB0_0:
	.file	2 "/app/OAI-triton/python/triton/language" "standard.py"
	s_add_i32 s0, s13, 0x7f
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 25
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 7
	.file	3 "/app/aiter/aiter/ops/triton/utils" "pid_preprocessing.py"
	s_abs_i32 s1, s0
	v_cvt_f32_u32_e32 v1, s1
	s_sub_i32 s17, 0, s1
	s_abs_i32 s15, s16
	s_mov_b32 s14, s13
	v_rcp_iflag_f32_e32 v1, v1
	s_xor_b32 s13, s16, s0
	s_ashr_i32 s13, s13, 31
	v_lshrrev_b32_e32 v3, 4, v0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_lshrrev_b32_e32 v42, 2, v0
	v_and_b32_e32 v6, 63, v0
	v_mov_b32_e32 v17, 4
	v_readfirstlane_b32 s18, v1
	s_mul_i32 s17, s17, s18
	s_mul_hi_u32 s17, s18, s17
	s_add_i32 s18, s18, s17
	s_mul_hi_u32 s17, s15, s18
	s_mul_i32 s18, s17, s1
	s_sub_i32 s15, s15, s18
	s_add_i32 s18, s17, 1
	s_sub_i32 s19, s15, s1
	s_cmp_ge_u32 s15, s1
	s_cselect_b32 s17, s18, s17
	s_cselect_b32 s15, s19, s15
	s_add_i32 s18, s17, 1
	s_cmp_ge_u32 s15, s1
	s_cselect_b32 s1, s18, s17
	s_abs_i32 s15, s12
	v_cvt_f32_u32_e32 v8, s15
	s_xor_b32 s1, s1, s13
	s_sub_i32 s1, s1, s13
	v_and_b32_e32 v1, 0x100, v0
	v_rcp_iflag_f32_e32 v8, v8
	s_mul_i32 s0, s1, s0
	v_lshrrev_b32_e32 v2, 4, v1
	s_sub_i32 s0, s16, s0
	v_mul_f32_e32 v8, 0x4f7ffffe, v8
	v_cvt_u32_f32_e32 v8, v8
	s_lshl_b32 s13, s1, 7
	v_and_or_b32 v43, v3, 15, v2
	s_sub_i32 s16, 0, s15
	v_or_b32_e32 v38, s13, v43
	s_bfe_i32 s1, s1, 0x10018
	v_mul_lo_u32 v11, s16, v8
	v_add_u32_e32 v10, s1, v38
	v_mul_hi_u32 v11, v8, v11
	v_xor_b32_e32 v10, s1, v10
	v_add_u32_e32 v8, v8, v11
	v_mul_hi_u32 v11, v10, v8
	v_mul_lo_u32 v11, v11, s15
	v_sub_u32_e32 v10, v10, v11
	v_subrev_u32_e32 v11, s15, v10
	v_cmp_le_u32_e32 vcc, s15, v10
	v_or_b32_e32 v4, 32, v43
	v_or_b32_e32 v36, s13, v4
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_subrev_u32_e32 v11, s15, v10
	v_cmp_le_u32_e32 vcc, s15, v10
	v_or_b32_e32 v5, 64, v43
	v_or_b32_e32 v34, s13, v5
	v_cndmask_b32_e32 v10, v10, v11, vcc
	v_add_u32_e32 v11, s1, v36
	v_xor_b32_e32 v11, s1, v11
	v_mul_hi_u32 v12, v11, v8
	v_mul_lo_u32 v12, v12, s15
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s15, v11
	v_cmp_le_u32_e32 vcc, s15, v11
	v_or_b32_e32 v7, 0x60, v43
	v_or_b32_e32 v40, s13, v7
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s15, v11
	v_cmp_le_u32_e32 vcc, s15, v11
	v_or_b32_e32 v9, s13, v42
	v_add_u32_e32 v9, s1, v9
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_add_u32_e32 v12, s1, v34
	v_xor_b32_e32 v12, s1, v12
	v_mul_hi_u32 v13, v12, v8
	v_mul_lo_u32 v13, v13, s15
	v_sub_u32_e32 v12, v12, v13
	v_subrev_u32_e32 v13, s15, v12
	v_cmp_le_u32_e32 vcc, s15, v12
	v_xor_b32_e32 v9, s1, v9
	v_xor_b32_e32 v10, s1, v10
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_subrev_u32_e32 v13, s15, v12
	v_cmp_le_u32_e32 vcc, s15, v12
	v_xor_b32_e32 v11, s1, v11
	v_subrev_u32_e32 v10, s1, v10
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_add_u32_e32 v13, s1, v40
	v_xor_b32_e32 v13, s1, v13
	v_mul_hi_u32 v14, v13, v8
	v_mul_lo_u32 v14, v14, s15
	v_sub_u32_e32 v13, v13, v14
	v_subrev_u32_e32 v14, s15, v13
	v_cmp_le_u32_e32 vcc, s15, v13
	v_mul_hi_u32 v8, v9, v8
	v_mul_lo_u32 v8, v8, s15
	v_cndmask_b32_e32 v13, v13, v14, vcc
	v_subrev_u32_e32 v14, s15, v13
	v_cmp_le_u32_e32 vcc, s15, v13
	v_sub_u32_e32 v8, v9, v8
	v_subrev_u32_e32 v9, s15, v8
	v_cndmask_b32_e32 v13, v13, v14, vcc
	v_cmp_le_u32_e32 vcc, s15, v8
	v_xor_b32_e32 v12, s1, v12
	v_xor_b32_e32 v13, s1, v13
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_subrev_u32_e32 v9, s15, v8
	v_cmp_le_u32_e32 vcc, s15, v8
	v_subrev_u32_e32 v11, s1, v11
	v_subrev_u32_e32 v12, s1, v12
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_xor_b32_e32 v8, s1, v8
	v_subrev_u32_e32 v13, s1, v13
	v_subrev_u32_e32 v8, s1, v8
	s_abs_i32 s1, s14
	v_cvt_f32_u32_e32 v9, s1
	s_lshl_b32 s20, s0, 7
	s_sub_i32 s15, 0, s1
	v_or_b32_e32 v14, s20, v43
	v_rcp_iflag_f32_e32 v9, v9
	s_bfe_i32 s0, s0, 0x10018
	v_add_u32_e32 v14, s0, v14
	v_xor_b32_e32 v14, s0, v14
	v_mul_f32_e32 v9, 0x4f7ffffe, v9
	v_cvt_u32_f32_e32 v9, v9
	v_or_b32_e32 v4, s20, v4
	v_add_u32_e32 v4, s0, v4
	v_xor_b32_e32 v4, s0, v4
	v_mul_lo_u32 v16, s15, v9
	v_mul_hi_u32 v16, v9, v16
	v_add_u32_e32 v9, v9, v16
	v_mul_hi_u32 v16, v14, v9
	v_mul_lo_u32 v16, v16, s1
	v_sub_u32_e32 v14, v14, v16
	v_subrev_u32_e32 v16, s1, v14
	v_cmp_le_u32_e32 vcc, s1, v14
	v_or_b32_e32 v5, s20, v5
	v_or_b32_e32 v7, s20, v7
	v_cndmask_b32_e32 v14, v14, v16, vcc
	v_subrev_u32_e32 v16, s1, v14
	v_cmp_le_u32_e32 vcc, s1, v14
	v_or_b32_e32 v15, s20, v42
	s_add_i32 s21, 0, 0x20000
	v_cndmask_b32_e32 v14, v14, v16, vcc
	v_mul_hi_u32 v16, v4, v9
	v_mul_lo_u32 v16, v16, s1
	v_sub_u32_e32 v4, v4, v16
	v_subrev_u32_e32 v16, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_add_i32 s15, 0, 0x21000
	v_xor_b32_e32 v14, s0, v14
	v_cndmask_b32_e32 v4, v4, v16, vcc
	v_subrev_u32_e32 v16, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	v_subrev_u32_e32 v14, s0, v14
	v_lshlrev_b32_e32 v58, 8, v43
	v_cndmask_b32_e32 v4, v4, v16, vcc
	v_xor_b32_e32 v4, s0, v4
	v_subrev_u32_e32 v16, s0, v4
	v_add_u32_e32 v4, s0, v5
	v_xor_b32_e32 v4, s0, v4
	v_mul_hi_u32 v5, v4, v9
	v_mul_lo_u32 v5, v5, s1
	v_sub_u32_e32 v4, v4, v5
	v_subrev_u32_e32 v5, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_and_b32 s17, s9, 0xffff
	s_mov_b32 s19, 0x27000
	v_cndmask_b32_e32 v4, v4, v5, vcc
	v_subrev_u32_e32 v5, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_mov_b32 s18, 0x7ffffffe
	s_mov_b32 s16, s8
	v_cndmask_b32_e32 v4, v4, v5, vcc
	v_xor_b32_e32 v4, s0, v4
	v_subrev_u32_e32 v5, s0, v4
	v_add_u32_e32 v4, s0, v7
	v_xor_b32_e32 v4, s0, v4
	v_mul_hi_u32 v7, v4, v9
	v_mul_lo_u32 v7, v7, s1
	v_sub_u32_e32 v4, v4, v7
	v_subrev_u32_e32 v7, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_add_i32 s22, 0, 0x10000
	s_mov_b32 s23, 0
	v_cndmask_b32_e32 v4, v4, v7, vcc
	v_subrev_u32_e32 v7, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v7, vcc
	v_xor_b32_e32 v4, s0, v4
	v_subrev_u32_e32 v7, s0, v4
	v_add_u32_e32 v4, s0, v15
	v_xor_b32_e32 v4, s0, v4
	v_mul_hi_u32 v9, v4, v9
	v_mul_lo_u32 v9, v9, s1
	v_sub_u32_e32 v4, v4, v9
	v_subrev_u32_e32 v9, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v9, vcc
	v_subrev_u32_e32 v9, s1, v4
	v_cmp_le_u32_e32 vcc, s1, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v9, vcc
	v_xor_b32_e32 v4, s0, v4
	v_subrev_u32_e32 v9, s0, v4
	v_lshlrev_b32_e32 v4, 4, v0
	v_and_b32_e32 v15, 0xf0, v4
	v_lshl_or_b32 v49, v5, 13, v15
	v_lshlrev_b32_e32 v5, 2, v0
	v_and_b32_e32 v5, 12, v5
	v_lshl_or_b32 v54, v42, 4, v5
	v_lshl_or_b32 v51, v8, 9, v5
	v_lshl_or_b32 v53, v9, 9, v5
	v_add_u32_e32 v5, s21, v54
	s_movk_i32 s0, 0xf0
	v_readfirstlane_b32 s1, v5
	v_add_u32_e32 v5, s15, v54
	s_mov_b32 m0, s1
	v_readfirstlane_b32 s1, v5
	v_and_b32_e32 v5, 48, v0
	v_lshl_or_b32 v50, v7, 13, v15
	v_bitop3_b32 v35, v4, v5, s0 bitop3:0x6c
	v_and_b32_e32 v7, 0xc0, v0
	v_xor_b32_e32 v57, v35, v7
	v_sub_u32_e32 v7, v57, v15
	v_ashrrev_i16_e32 v7, 4, v7
	v_add_u32_sdwa v6, v6, sext(v7) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_or_b32_e32 v59, v58, v15
	v_lshlrev_b32_sdwa v17, v17, sext(v7) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshrrev_b64 v[6:7], v6, exec
	v_lshl_or_b32 v47, v14, 13, v15
	v_lshl_or_b32 v48, v16, 13, v15
	v_add_u32_e32 v8, 0, v59
	v_add_u32_e32 v15, v17, v15
	v_and_b32_e32 v6, 1, v6
	buffer_load_dword v51, s[16:19], 0 offen lds
	s_and_b32 s17, s11, 0xffff
	s_mov_b32 s16, s10
	s_mov_b32 m0, s1
	v_add_u32_e32 v9, 0x2000, v8
	v_lshl_add_u32 v64, v10, 13, v15
	v_bfrev_b32_e32 v7, 1
	v_cmp_eq_u32_e32 vcc, 1, v6
	v_readfirstlane_b32 s0, v8
	buffer_load_dword v53, s[16:19], 0 offen lds
	v_add_u32_e32 v14, 0x4000, v8
	s_and_b32 s17, s3, 0xffff
	s_mov_b32 s16, s2
	v_cndmask_b32_e32 v6, v7, v64, vcc
	s_mov_b32 m0, s0
	v_lshl_add_u32 v65, v11, 13, v15
	v_readfirstlane_b32 s0, v9
	v_add_u32_e32 v16, 0x6000, v8
	buffer_load_dwordx4 v6, s[16:19], 0 offen lds
	v_cndmask_b32_e32 v6, v7, v65, vcc
	s_mov_b32 m0, s0
	v_lshl_add_u32 v66, v12, 13, v15
	v_readfirstlane_b32 s0, v14
	buffer_load_dwordx4 v6, s[16:19], 0 offen lds
	v_cndmask_b32_e32 v6, v7, v66, vcc
	s_mov_b32 m0, s0
	v_lshl_add_u32 v67, v13, 13, v15
	v_readfirstlane_b32 s0, v16
	buffer_load_dwordx4 v6, s[16:19], 0 offen lds
	v_cndmask_b32_e32 v6, v7, v67, vcc
	s_mov_b32 m0, s0
	v_add_u32_e32 v11, v47, v17
	buffer_load_dwordx4 v6, s[16:19], 0 offen lds
	v_add_u32_e32 v6, s22, v59
	v_add_u32_e32 v8, 0x2000, v6
	v_readfirstlane_b32 s0, v6
	v_add_u32_e32 v9, 0x4000, v6
	v_add_u32_e32 v10, 0x6000, v6
	s_and_b32 s17, s5, 0xffff
	s_mov_b32 s16, s4
	v_cndmask_b32_e32 v11, v7, v11, vcc
	s_mov_b32 m0, s0
	v_add_u32_e32 v6, v48, v17
	v_readfirstlane_b32 s0, v8
	buffer_load_dwordx4 v11, s[16:19], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v6, v7, v6, vcc
	s_mov_b32 m0, s0
	v_readfirstlane_b32 s0, v9
	buffer_load_dwordx4 v6, s[16:19], 0 offen sc0 nt lds
	v_add_u32_e32 v6, v49, v17
	v_cndmask_b32_e32 v6, v7, v6, vcc
	s_mov_b32 m0, s0
	v_readfirstlane_b32 s0, v10
	buffer_load_dwordx4 v6, s[16:19], 0 offen sc0 nt lds
	v_add_u32_e32 v6, v50, v17
	v_cndmask_b32_e32 v6, v7, v6, vcc
	s_mov_b32 m0, s0
	s_movk_i32 s0, 0x1ff
	buffer_load_dwordx4 v6, s[16:19], 0 offen sc0 nt lds
	v_add_u32_e32 v6, 0xff, v0
	v_cmp_gt_u32_e32 vcc, s0, v6
	s_movk_i32 s0, 0x1fe
	v_cmp_lt_u32_e64 s[0:1], s0, v6
	s_and_saveexec_b64 s[16:17], s[0:1]
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_barrier
.LBB0_2:
	s_or_b64 exec, exec, s[16:17]
	v_and_b32_e32 v8, 15, v0
	v_or_b32_e32 v11, 64, v8
	s_add_u32 s24, s4, 0x100
	v_and_b32_e32 v68, 3, v3
	v_and_b32_e32 v45, 16, v42
	v_and_b32_e32 v44, 32, v42
	v_and_b32_e32 v3, 48, v4
	v_and_b32_e32 v6, 0x70, v4
	v_or_b32_e32 v9, v2, v8
	v_or_b32_e32 v2, v11, v2
	s_addc_u32 s25, s5, 0
	v_and_b32_e32 v7, 0x80, v4
	v_lshlrev_b32_e32 v72, 4, v9
	v_or_b32_e32 v10, 32, v9
	v_lshlrev_b32_e32 v41, 4, v2
	v_or_b32_e32 v12, 0x60, v9
	v_and_or_b32 v8, v42, 48, v8
	v_or3_b32 v11, v11, v45, v44
	v_lshlrev_b32_e32 v55, 8, v9
	v_bitop3_b32 v9, v3, v4, 64 bitop3:0x72
	v_or_b32_e32 v6, 0x80, v6
	v_or_b32_e32 v3, 0xc0, v3
	v_and_b32_e32 v4, 0xc0, v4
	v_lshlrev_b32_e32 v39, 8, v2
	s_add_u32 s26, s2, 0x100
	v_mov_b32_e32 v2, 0
	v_lshlrev_b32_e32 v71, 4, v10
	v_lshlrev_b32_e32 v46, 4, v12
	v_lshlrev_b32_e32 v70, 4, v8
	v_lshlrev_b32_e32 v69, 4, v11
	v_bitop3_b32 v63, v9, v5, v7 bitop3:0x36
	v_bitop3_b32 v61, v7, v6, v5 bitop3:0x36
	v_bitop3_b32 v62, v4, v3, v5 bitop3:0x36
	v_lshlrev_b32_e32 v52, 8, v10
	v_lshlrev_b32_e32 v37, 8, v12
	v_lshlrev_b32_e32 v60, 8, v8
	v_lshlrev_b32_e32 v56, 8, v11
	s_addc_u32 s27, s3, 0
	s_mov_b32 s28, 0
	s_mov_b64 s[4:5], 16
	v_mov_b32_e32 v3, v2
	v_mov_b32_e32 v4, v2
	v_mov_b32_e32 v5, v2
	v_mov_b32_e32 v18, v2
	v_mov_b32_e32 v19, v2
	v_mov_b32_e32 v20, v2
	v_mov_b32_e32 v21, v2
	v_mov_b32_e32 v14, v2
	v_mov_b32_e32 v15, v2
	v_mov_b32_e32 v16, v2
	v_mov_b32_e32 v17, v2
	v_mov_b32_e32 v10, v2
	v_mov_b32_e32 v11, v2
	v_mov_b32_e32 v12, v2
	v_mov_b32_e32 v13, v2
	v_mov_b32_e32 v6, v2
	v_mov_b32_e32 v7, v2
	v_mov_b32_e32 v8, v2
	v_mov_b32_e32 v9, v2
	v_mov_b32_e32 v22, v2
	v_mov_b32_e32 v23, v2
	v_mov_b32_e32 v24, v2
	v_mov_b32_e32 v25, v2
	v_mov_b32_e32 v30, v2
	v_mov_b32_e32 v31, v2
	v_mov_b32_e32 v32, v2
	v_mov_b32_e32 v33, v2
	v_mov_b32_e32 v26, v2
	v_mov_b32_e32 v27, v2
	v_mov_b32_e32 v28, v2
	v_mov_b32_e32 v29, v2
.LBB0_3:                                ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s33, s21
	s_mov_b32 s31, s15
	s_mov_b32 s30, s23
	s_mov_b32 s29, s22
	s_waitcnt vmcnt(0)
	s_barrier
	s_waitcnt lgkmcnt(0)
	; sched_barrier mask(0x00000000)
	s_add_u32 s16, s8, s4
	s_addc_u32 s1, s9, s5
	s_add_u32 s0, s10, s4
	s_addc_u32 s15, s11, s5
	s_add_i32 s17, s28, 1
	s_cmp_lt_i32 s17, 2
	s_cselect_b32 s28, s17, 0
	s_and_b32 s17, s1, 0xffff
	s_and_b32 s1, s15, 0xffff
	s_lshl_b32 s15, s28, 11
	s_lshl_b32 s21, s28, 15
	s_add_i32 s15, s15, 0
	s_add_i32 s23, s21, 0
	s_add_i32 s21, s15, 0x20000
	s_add_i32 s15, s15, 0x21000
	v_add_u32_e32 v73, s23, v59
	s_add_i32 s22, s23, 0x10000
	v_add_u32_e32 v74, s21, v54
	v_add_u32_e32 v75, s15, v54
	v_add_u32_e32 v76, 0x2000, v73
	v_add_u32_e32 v77, 0x4000, v73
	v_add_u32_e32 v78, 0x6000, v73
	v_readfirstlane_b32 s34, v73
	v_add3_u32 v73, s22, v57, v58
	v_add_u32_e32 v79, s22, v59
	v_readfirstlane_b32 s35, v74
	v_readfirstlane_b32 s36, v75
	v_readfirstlane_b32 s38, v77
	v_add_u32_e32 v74, 0x2000, v79
	v_sub_u32_e32 v77, v73, v79
	s_mov_b32 m0, s35
	s_mov_b32 s2, s18
	s_mov_b32 s3, s19
	v_readfirstlane_b32 s37, v76
	v_readfirstlane_b32 s39, v78
	v_add_u32_e32 v75, 0x4000, v79
	v_add_u32_e32 v76, 0x6000, v79
	v_readfirstlane_b32 s40, v79
	v_ashrrev_i32_e32 v78, 31, v77
	v_sub_u32_e32 v79, v73, v74
	buffer_load_dword v51, s[16:19], 0 offen lds
	s_mov_b32 m0, s36
	v_readfirstlane_b32 s41, v74
	v_sub_u32_e32 v74, v73, v75
	v_readfirstlane_b32 s42, v75
	v_sub_u32_e32 v73, v73, v76
	v_readfirstlane_b32 s43, v76
	s_and_b32 s17, s27, 0xffff
	s_mov_b32 s16, s26
	v_lshrrev_b32_e32 v75, 28, v78
	v_add_u32_e32 v76, 0x2000, v79
	buffer_load_dword v53, s[0:3], 0 offen lds
	s_mov_b32 m0, s34
	v_add_u32_e32 v74, 0x4000, v74
	v_add_u32_e32 v75, v77, v75
	v_ashrrev_i32_e32 v77, 31, v76
	buffer_load_dwordx4 v64, s[16:19], 0 offen lds
	s_mov_b32 m0, s37
	v_add_u32_e32 v73, 0x6000, v73
	v_ashrrev_i32_e32 v78, 31, v74
	v_lshrrev_b32_e32 v77, 28, v77
	buffer_load_dwordx4 v65, s[16:19], 0 offen lds
	s_mov_b32 m0, s38
	v_ashrrev_i32_e32 v79, 31, v73
	v_and_b32_e32 v75, -16, v75
	v_lshrrev_b32_e32 v78, 28, v78
	v_add_u32_e32 v76, v76, v77
	buffer_load_dwordx4 v66, s[16:19], 0 offen lds
	s_mov_b32 m0, s39
	v_lshrrev_b32_e32 v79, 28, v79
	v_add_u32_e32 v75, v75, v47
	v_add_u32_e32 v74, v74, v78
	v_and_b32_e32 v76, -16, v76
	buffer_load_dwordx4 v67, s[16:19], 0 offen lds
	s_and_b32 s17, s25, 0xffff
	s_mov_b32 s16, s24
	s_mov_b32 m0, s40
	v_add_u32_e32 v73, v73, v79
	v_and_b32_e32 v74, -16, v74
	v_add_u32_e32 v76, v76, v48
	buffer_load_dwordx4 v75, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s41
	v_and_b32_e32 v73, -16, v73
	v_add_u32_e32 v74, v74, v49
	buffer_load_dwordx4 v76, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s42
	v_add_u32_e32 v73, v73, v50
	buffer_load_dwordx4 v74, s[16:19], 0 offen sc0 nt lds
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v73, s[16:19], 0 offen sc0 nt lds
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v74, s31, v68
	v_add_u32_e32 v86, s30, v35
	v_add_u32_e32 v75, s29, v35
	v_add_u32_e32 v73, s33, v68
	v_add_u32_e32 v76, s29, v63
	v_add_u32_e32 v96, v74, v70
	v_add_u32_e32 v97, v74, v69
	v_add_u32_e32 v78, v86, v55
	v_add_u32_e32 v74, v75, v60
	v_add_u32_e32 v82, v75, v56
	s_barrier
	v_add_u32_e32 v94, v73, v72
	v_add_u32_e32 v88, v76, v60
	v_add_u32_e32 v99, v76, v56
	ds_read_b128 v[74:77], v74
	ds_read_u8 v104, v94
	ds_read_u8 v105, v96
	ds_read_b128 v[78:81], v78
	ds_read_b128 v[82:85], v82
	v_add_u32_e32 v95, v73, v71
	ds_read_u8 v106, v97
	ds_read_u8 v107, v95
	v_add_u32_e32 v89, v86, v52
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[74:77], v[78:81], v[2:5], v105, v104 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v87, s30, v63
	v_add_u32_e32 v101, v73, v41
	v_add_u32_e32 v102, v86, v39
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[82:85], v[78:81], v[18:21], v106, v104 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v89
	v_add_u32_e32 v98, v87, v55
	v_add_u32_e32 v100, v87, v52
	v_add_u32_e32 v103, v87, v39
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[74:77], v[78:81], v[14:17], v105, v107 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v104, v87, v37
	ds_read_u8 v87, v101
	v_add_u32_e32 v73, v73, v46
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[82:85], v[78:81], v[10:13], v106, v107 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v102
	v_add_u32_e32 v86, v86, v37
	ds_read_u8 v108, v73
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[74:77], v[78:81], v[6:9], v105, v87 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v92, s29, v61
	v_add_u32_e32 v90, s30, v61
	v_add_u32_e32 v102, v90, v55
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[82:85], v[78:81], v[22:25], v106, v87 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v86
	ds_read_b128 v[86:89], v88
	v_add_u32_e32 v93, s29, v62
	v_add_u32_e32 v91, s30, v62
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[74:77], v[78:81], v[30:33], v105, v108 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v105, v94 offset:4
	ds_read_u8 v109, v96 offset:4
	ds_read_b128 v[74:77], v98
	v_add_u32_e32 v107, v91, v55
	s_add_u32 s24, s24, 0x100
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[82:85], v[78:81], v[26:29], v106, v108 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v99
	ds_read_u8 v98, v97 offset:4
	ds_read_u8 v82, v95 offset:4
	ds_read_u8 v84, v101 offset:4
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[86:89], v[74:77], v[2:5], v109, v105 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v83, v92, v60
	v_add_u32_e32 v92, v92, v56
	v_add_u32_e32 v99, v93, v60
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[78:81], v[74:77], v[18:21], v98, v105 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[74:77], v100
	v_add_u32_e32 v100, v90, v52
	v_add_u32_e32 v93, v93, v56
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[86:89], v[74:77], v[14:17], v109, v82 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s25, s25, 0
	s_add_u32 s26, s26, 0x100
	s_addc_u32 s27, s27, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[78:81], v[74:77], v[10:13], v98, v82 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[74:77], v103
	ds_read_u8 v103, v73 offset:4
	s_add_u32 s4, s4, 16
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[86:89], v[74:77], v[6:9], v109, v84 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s5, s5, 0
	s_cmpk_lg_i32 s4, 0x200
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[78:81], v[74:77], v[22:25], v98, v84 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[74:77], v104
	ds_read_b128 v[82:85], v83
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[86:89], v[74:77], v[30:33], v109, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v104, v94 offset:8
	ds_read_u8 v105, v96 offset:8
	ds_read_b128 v[86:89], v102
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[78:81], v[74:77], v[26:29], v98, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[74:77], v92
	ds_read_u8 v92, v97 offset:8
	ds_read_u8 v98, v95 offset:8
	ds_read_b128 v[78:81], v100
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[82:85], v[86:89], v[2:5], v105, v104 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[74:77], v[86:89], v[18:21], v92, v104 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v86, v90, v39
	ds_read_u8 v87, v101 offset:8
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[82:85], v[78:81], v[14:17], v105, v98 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[74:77], v[78:81], v[10:13], v92, v98 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v86
	v_add_u32_e32 v86, v90, v37
	ds_read_u8 v90, v73 offset:8
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[82:85], v[78:81], v[6:9], v105, v87 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v98, v91, v52
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[74:77], v[78:81], v[22:25], v92, v87 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v86
	ds_read_b128 v[86:89], v99
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[82:85], v[78:81], v[30:33], v105, v90 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v94, v94 offset:12
	ds_read_u8 v96, v96 offset:12
	ds_read_b128 v[82:85], v107
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[74:77], v[78:81], v[26:29], v92, v90 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[74:77], v93
	ds_read_u8 v90, v97 offset:12
	ds_read_u8 v92, v95 offset:12
	ds_read_b128 v[78:81], v98
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[86:89], v[82:85], v[2:5], v96, v94 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v73, v73 offset:12
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[74:77], v[82:85], v[18:21], v90, v94 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v82, v91, v39
	ds_read_u8 v83, v101 offset:12
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[86:89], v[78:81], v[14:17], v96, v92 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[74:77], v[78:81], v[10:13], v90, v92 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v82
	v_add_u32_e32 v82, v91, v37
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[86:89], v[78:81], v[6:9], v96, v83 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[74:77], v[78:81], v[22:25], v90, v83 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[78:81], v82
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[86:89], v[78:81], v[30:33], v96, v73 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[74:77], v[78:81], v[26:29], v90, v73 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_3
; %bb.4:
	s_and_saveexec_b64 s[0:1], vcc
	s_cbranch_execz .LBB0_6
; %bb.5:
	s_barrier
.LBB0_6:
	s_or_b64 exec, exec, s[0:1]
	v_add_u32_e32 v47, s21, v68
	v_add_u32_e32 v48, v47, v72
	s_waitcnt vmcnt(0)
	s_barrier
	v_add_u32_e32 v49, v47, v71
	ds_read_u8 v53, v48
	ds_read_u8 v54, v48 offset:4
	ds_read_u8 v96, v48 offset:8
	ds_read_u8 v97, v48 offset:12
	ds_read_u8 v100, v49
	ds_read_u8 v101, v49 offset:4
	ds_read_u8 v102, v49 offset:8
	ds_read_u8 v103, v49 offset:12
	v_add_u32_e32 v48, s15, v68
	v_add_u32_e32 v49, v48, v70
	v_add_u32_e32 v48, v48, v69
	v_add_u32_e32 v112, s23, v35
	v_add_u32_e32 v35, s22, v35
	ds_read_u8 v104, v49
	ds_read_u8 v105, v49 offset:4
	ds_read_u8 v106, v49 offset:8
	ds_read_u8 v107, v49 offset:12
	ds_read_u8 v108, v48
	ds_read_u8 v109, v48 offset:4
	ds_read_u8 v110, v48 offset:8
	ds_read_u8 v111, v48 offset:12
	v_add_u32_e32 v48, v112, v55
	v_add_u32_e32 v113, s23, v63
	v_add_u32_e32 v58, v35, v60
	v_add_u32_e32 v63, s22, v63
	v_add_u32_e32 v57, v113, v55
	ds_read_b128 v[48:51], v48
	ds_read_b128 v[64:67], v57
	ds_read_b128 v[68:71], v58
	v_add_u32_e32 v58, v63, v60
	v_add_u32_e32 v98, s22, v61
	v_add_u32_e32 v114, s23, v61
	v_add_u32_e32 v115, s23, v62
	ds_read_b128 v[72:75], v58
	v_add_u32_e32 v58, v98, v60
	v_add_u32_e32 v62, s22, v62
	v_add_u32_e32 v57, v114, v55
	ds_read_b128 v[76:79], v58
	v_add_u32_e32 v58, v62, v60
	v_add_u32_e32 v55, v115, v55
	v_add_u32_e32 v35, v35, v56
	ds_read_b128 v[58:61], v58
	ds_read_b128 v[80:83], v57
	ds_read_b128 v[84:87], v55
	ds_read_b128 v[88:91], v35
	v_add_u32_e32 v35, v63, v56
	ds_read_b128 v[92:95], v35
	v_add_u32_e32 v35, v98, v56
	s_waitcnt lgkmcnt(7)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[68:71], v[48:51], v[2:5], v104, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_ashr_i32 s0, s13, 31
	s_ashr_i32 s21, s20, 31
	s_movk_i32 s10, 0x78c
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[88:91], v[48:51], v[18:21], v108, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[48:51], v35
	v_add_u32_e32 v35, v62, v56
	v_lshlrev_b32_e32 v1, 3, v1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[72:75], v[64:67], v[2:5], v105, v54 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mul_u32_u24_e32 v43, 0x1a000, v43
	s_mov_b32 s11, 0x27000
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[92:95], v[64:67], v[18:21], v109, v54 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[54:57], v35
	v_add_u32_e32 v35, v112, v52
	ds_read_b128 v[62:65], v35
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[76:79], v[80:83], v[2:5], v106, v96 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v35, v113, v52
	v_add_u32_e32 v66, v113, v39
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[48:51], v[80:83], v[18:21], v110, v96 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[80:83], v35
	v_add_u32_e32 v35, v114, v52
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[58:61], v[84:87], v[2:5], v107, v97 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[54:57], v[84:87], v[18:21], v111, v97 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[84:87], v35
	v_add_u32_e32 v35, v115, v52
	ds_read_b128 v[96:99], v35
	v_add_u32_e32 v35, v47, v41
	v_add_u32_e32 v41, v47, v46
	v_add_u32_e32 v46, v112, v39
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[68:71], v[62:65], v[14:17], v104, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[88:91], v[62:65], v[10:13], v108, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[62:65], v46
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[72:75], v[80:83], v[14:17], v105, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[92:95], v[80:83], v[10:13], v109, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v46, v35
	ds_read_u8 v47, v35 offset:4
	ds_read_u8 v52, v35 offset:8
	ds_read_u8 v35, v35 offset:12
	ds_read_u8 v53, v41
	ds_read_u8 v100, v41 offset:4
	ds_read_u8 v101, v41 offset:8
	ds_read_u8 v41, v41 offset:12
	ds_read_b128 v[80:83], v66
	v_add_u32_e32 v66, v114, v39
	s_waitcnt lgkmcnt(8)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[68:71], v[62:65], v[6:9], v104, v46 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v39, v115, v39
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[88:91], v[62:65], v[22:25], v108, v46 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[76:79], v[84:87], v[14:17], v106, v102 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[48:51], v[84:87], v[10:13], v110, v102 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[84:87], v66
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[72:75], v[80:83], v[6:9], v105, v47 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[92:95], v[80:83], v[22:25], v109, v47 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v47, s21
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[58:61], v[96:99], v[14:17], v107, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[54:57], v[96:99], v[10:13], v111, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[96:99], v39
	v_add_u32_e32 v39, v112, v37
	ds_read_b128 v[62:65], v39
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[76:79], v[84:87], v[6:9], v106, v52 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[48:51], v[84:87], v[22:25], v110, v52 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_nop 1
	v_cvt_pk_bf16_f32 v13, v12, v13
	v_cvt_pk_bf16_f32 v12, v10, v11
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[58:61], v[96:99], v[6:9], v107, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[54:57], v[96:99], v[22:25], v111, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v35, v113, v37
	ds_read_b128 v[80:83], v35
	v_add_u32_e32 v35, v114, v37
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[68:71], v[62:65], v[30:33], v104, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[66:69], v35
	v_add_u32_e32 v35, v115, v37
	v_mov_b32_e32 v39, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[88:91], v[62:65], v[26:29], v108, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v37, s0
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[72:75], v[80:83], v[30:33], v105, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[70:73], v35
	v_mov_b32_e32 v35, s0
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[92:95], v[80:83], v[26:29], v109, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_barrier
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[76:79], v[66:69], v[30:33], v106, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[48:51], v[66:69], v[26:29], v110, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_lshlrev_b32_e32 v48, 3, v0
	v_lshl_or_b32 v0, v0, 7, v42
	v_and_or_b32 v0, v0, s10, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[58:61], v[70:73], v[30:33], v107, v41 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or3_b32 v0, v0, v44, v1
	s_movk_i32 s10, 0x7f8
	v_and_b32_e32 v49, 0x78, v48
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[54:57], v[70:73], v[26:29], v111, v41 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v41, s0
	s_mul_hi_i32 s0, s13, 0x34000
	s_mul_i32 s13, s13, 0x34000
	s_add_u32 s2, s6, s13
	s_addc_u32 s3, s7, s0
	s_lshl_b64 s[0:1], s[20:21], 1
	s_add_u32 s8, s2, s0
	s_addc_u32 s9, s3, s1
	s_ashr_i32 s13, s12, 31
	v_cmp_gt_i64_e64 s[0:1], s[12:13], v[34:35]
	v_and_or_b32 v34, v48, s10, v1
	v_lshrrev_b32_e32 v1, 3, v0
	v_and_b32_e32 v1, 0x1f0, v1
	v_lshlrev_b32_e32 v0, 1, v0
	v_add3_u32 v35, 0, v1, v0
	v_cvt_pk_bf16_f32 v1, v4, v5
	v_cvt_pk_bf16_f32 v0, v2, v3
	v_cvt_pk_bf16_f32 v3, v20, v21
	v_cvt_pk_bf16_f32 v2, v18, v19
	ds_write2_b64 v35, v[0:1], v[2:3] offset1:16
	v_lshrrev_b32_e32 v0, 3, v34
	v_and_b32_e32 v0, 0x1f0, v0
	v_lshlrev_b32_e32 v1, 1, v34
	v_add3_u32 v18, 0, v0, v1
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[0:3], v18
	v_or_b32_e32 v46, s20, v49
	s_ashr_i32 s15, s14, 31
	v_cvt_pk_bf16_f32 v5, v16, v17
	v_cvt_pk_bf16_f32 v4, v14, v15
	v_or_b32_e32 v43, v43, v49
	v_cmp_gt_i64_e64 s[6:7], s[12:13], v[38:39]
	v_cmp_gt_i64_e64 s[2:3], s[14:15], v[46:47]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[4:5], v[12:13] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[10:13], v18
	v_cvt_pk_bf16_f32 v5, v8, v9
	v_cvt_pk_bf16_f32 v4, v6, v7
	v_cvt_pk_bf16_f32 v7, v24, v25
	v_cvt_pk_bf16_f32 v6, v22, v23
	v_cvt_pk_bf16_f32 v9, v32, v33
	v_cvt_pk_bf16_f32 v8, v30, v31
	v_cvt_pk_bf16_f32 v15, v28, v29
	v_cvt_pk_bf16_f32 v14, v26, v27
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[4:5], v[6:7] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[4:7], v18
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[8:9], v[14:15] offset1:16
	v_lshlrev_b32_e32 v8, 1, v43
	v_bfrev_b32_e32 v9, 1
	s_and_b64 s[6:7], s[6:7], s[2:3]
	v_cmp_gt_i64_e64 s[4:5], s[12:13], v[36:37]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[14:17], v18
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, 0x7ffffffe
	v_cndmask_b32_e64 v18, v9, v8, s[6:7]
	buffer_store_dwordx4 v[0:3], v18, s[8:11], 0 offen
	s_and_b64 s[4:5], s[4:5], s[2:3]
	s_and_b64 s[0:1], s[0:1], s[2:3]
	v_add_u32_e32 v0, 0x680000, v8
	v_cndmask_b32_e64 v0, v9, v0, s[4:5]
	buffer_store_dwordx4 v[10:13], v0, s[8:11], 0 offen
	v_add_u32_e32 v0, 0xd00000, v8
	v_cmp_gt_i64_e32 vcc, s[12:13], v[40:41]
	v_cndmask_b32_e64 v0, v9, v0, s[0:1]
	buffer_store_dwordx4 v[4:7], v0, s[8:11], 0 offen
	v_add_u32_e32 v0, 0x1380000, v8
	s_and_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e32 v0, v9, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[14:17], v0, s[8:11], 0 offen
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _gemm_afp4_wfp4_kernel
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 56
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
		.amdhsa_next_free_vgpr 116
		.amdhsa_next_free_sgpr 44
		.amdhsa_accum_offset 116
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
	.size	_gemm_afp4_wfp4_kernel, .Lfunc_end0-_gemm_afp4_wfp4_kernel
	.cfi_endproc
                                        ; -- End function
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 116
	.set _gemm_afp4_wfp4_kernel.num_agpr, 0
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 44
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5604
; TotalNumSgprs: 50
; NumVgprs: 116
; NumAgprs: 0
; TotalNumVgprs: 116
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 6
; VGPRBlocks: 14
; NumSGPRsForWavesPerEU: 50
; NumVGPRsForWavesPerEU: 116
; AccumOffset: 116
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 28
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
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	63                              ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x55:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	67                              ; DW_AT_call_line
	.byte	44                              ; DW_AT_call_column
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp2-.Lfunc_begin0
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	.Ltmp9-.Lfunc_begin0
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp13-.Lfunc_begin0
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
	.asciz	"_gemm_afp4_wfp4_kernel"        ; string offset=52
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
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
      - .address_space:  global
        .offset:         48
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 56
    .max_flat_workgroup_size: 512
    .name:           _gemm_afp4_wfp4_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     50
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     116
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
