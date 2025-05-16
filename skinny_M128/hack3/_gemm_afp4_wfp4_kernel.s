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
	s_add_u32 s4, s4, 0x100
	v_and_b32_e32 v68, 3, v3
	v_and_b32_e32 v45, 16, v42
	v_and_b32_e32 v44, 32, v42
	v_and_b32_e32 v3, 48, v4
	v_and_b32_e32 v6, 0x70, v4
	v_or_b32_e32 v9, v2, v8
	v_or_b32_e32 v11, 64, v8
	s_addc_u32 s5, s5, 0
	v_and_b32_e32 v7, 0x80, v4
	v_lshlrev_b32_e32 v72, 4, v9
	v_or_b32_e32 v10, 32, v9
	v_or_b32_e32 v2, v11, v2
	v_or_b32_e32 v12, 0x60, v9
	v_and_or_b32 v8, v42, 48, v8
	v_or3_b32 v11, v11, v45, v44
	v_lshlrev_b32_e32 v55, 8, v9
	v_bitop3_b32 v9, v3, v4, 64 bitop3:0x72
	v_or_b32_e32 v6, 0x80, v6
	v_or_b32_e32 v3, 0xc0, v3
	v_and_b32_e32 v4, 0xc0, v4
	s_add_u32 s2, s2, 0x100
	v_mov_b32_e32 v30, 0
	v_lshlrev_b32_e32 v71, 4, v10
	v_lshlrev_b32_e32 v41, 4, v2
	v_lshlrev_b32_e32 v46, 4, v12
	v_lshlrev_b32_e32 v70, 4, v8
	v_lshlrev_b32_e32 v69, 4, v11
	v_bitop3_b32 v63, v9, v5, v7 bitop3:0x36
	v_bitop3_b32 v61, v7, v6, v5 bitop3:0x36
	v_bitop3_b32 v62, v4, v3, v5 bitop3:0x36
	v_lshlrev_b32_e32 v52, 8, v10
	v_lshlrev_b32_e32 v39, 8, v2
	v_lshlrev_b32_e32 v37, 8, v12
	v_lshlrev_b32_e32 v60, 8, v8
	v_lshlrev_b32_e32 v56, 8, v11
	s_addc_u32 s3, s3, 0
	s_mov_b32 s24, 0
	s_mov_b64 s[0:1], 16
	v_mov_b32_e32 v31, v30
	v_mov_b32_e32 v32, v30
	v_mov_b32_e32 v33, v30
	v_mov_b32_e32 v22, v30
	v_mov_b32_e32 v23, v30
	v_mov_b32_e32 v24, v30
	v_mov_b32_e32 v25, v30
	v_mov_b32_e32 v26, v30
	v_mov_b32_e32 v27, v30
	v_mov_b32_e32 v28, v30
	v_mov_b32_e32 v29, v30
	v_mov_b32_e32 v18, v30
	v_mov_b32_e32 v19, v30
	v_mov_b32_e32 v20, v30
	v_mov_b32_e32 v21, v30
	v_mov_b32_e32 v14, v30
	v_mov_b32_e32 v15, v30
	v_mov_b32_e32 v16, v30
	v_mov_b32_e32 v17, v30
	v_mov_b32_e32 v6, v30
	v_mov_b32_e32 v7, v30
	v_mov_b32_e32 v8, v30
	v_mov_b32_e32 v9, v30
	v_mov_b32_e32 v2, v30
	v_mov_b32_e32 v3, v30
	v_mov_b32_e32 v4, v30
	v_mov_b32_e32 v5, v30
	v_mov_b32_e32 v10, v30
	v_mov_b32_e32 v11, v30
	v_mov_b32_e32 v12, v30
	v_mov_b32_e32 v13, v30
.LBB0_3:                                ; =>This Inner Loop Header: Depth=1
	s_add_u32 s16, s8, s0
	s_mov_b32 s27, s15
	s_addc_u32 s15, s9, s1
	s_add_u32 s28, s10, s0
	s_mov_b32 s25, s22
	s_addc_u32 s22, s11, s1
	s_add_i32 s17, s24, 1
	s_cmp_lt_i32 s17, 2
	s_cselect_b32 s24, s17, 0
	s_mov_b32 s26, s21
	s_mov_b32 s33, s23
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(0)
	s_barrier
	s_waitcnt lgkmcnt(0)
	; sched_barrier mask(0x00000000)
	s_lshl_b32 s17, s24, 11
	s_add_i32 s23, s17, 0
	s_add_i32 s21, s23, 0x20000
	v_add_u32_e32 v73, s21, v54
	s_and_b32 s17, s15, 0xffff
	v_readfirstlane_b32 s15, v73
	s_mov_b32 m0, s15
	s_add_i32 s15, s23, 0x21000
	v_add_u32_e32 v73, s15, v54
	buffer_load_dword v51, s[16:19], 0 offen lds
	v_readfirstlane_b32 s16, v73
	s_mov_b32 m0, s16
	s_lshl_b32 s16, s24, 15
	s_add_i32 s23, s16, 0
	v_add_u32_e32 v73, s23, v59
	s_and_b32 s29, s22, 0xffff
	s_mov_b32 s30, s18
	s_mov_b32 s31, s19
	v_add_u32_e32 v74, 0x2000, v73
	v_readfirstlane_b32 s22, v73
	buffer_load_dword v53, s[28:31], 0 offen lds
	v_add_u32_e32 v75, 0x4000, v73
	s_and_b32 s17, s3, 0xffff
	s_mov_b32 s16, s2
	s_mov_b32 m0, s22
	v_readfirstlane_b32 s22, v74
	v_add_u32_e32 v76, 0x6000, v73
	buffer_load_dwordx4 v64, s[16:19], 0 offen lds
	s_mov_b32 m0, s22
	v_readfirstlane_b32 s22, v75
	buffer_load_dwordx4 v65, s[16:19], 0 offen lds
	s_mov_b32 m0, s22
	v_readfirstlane_b32 s22, v76
	buffer_load_dwordx4 v66, s[16:19], 0 offen lds
	s_mov_b32 m0, s22
	s_add_i32 s22, s23, 0x10000
	v_add3_u32 v73, s22, v57, v58
	v_add_u32_e32 v74, s22, v59
	v_sub_u32_e32 v78, v73, v74
	v_ashrrev_i32_e32 v79, 31, v78
	v_lshrrev_b32_e32 v79, 28, v79
	v_add_u32_e32 v75, 0x2000, v74
	v_add_u32_e32 v78, v78, v79
	v_add_u32_e32 v76, 0x4000, v74
	v_add_u32_e32 v77, 0x6000, v74
	v_and_b32_e32 v78, -16, v78
	v_readfirstlane_b32 s28, v74
	v_sub_u32_e32 v74, v73, v75
	buffer_load_dwordx4 v67, s[16:19], 0 offen lds
	s_and_b32 s17, s5, 0xffff
	s_mov_b32 s16, s4
	v_add_u32_e32 v78, v78, v47
	s_mov_b32 m0, s28
	v_add_u32_e32 v74, 0x2000, v74
	buffer_load_dwordx4 v78, s[16:19], 0 offen sc0 nt lds
	v_ashrrev_i32_e32 v78, 31, v74
	v_lshrrev_b32_e32 v78, 28, v78
	v_add_u32_e32 v74, v74, v78
	v_and_b32_e32 v74, -16, v74
	v_readfirstlane_b32 s28, v75
	v_add_u32_e32 v74, v74, v48
	s_mov_b32 m0, s28
	v_readfirstlane_b32 s28, v76
	buffer_load_dwordx4 v74, s[16:19], 0 offen sc0 nt lds
	v_sub_u32_e32 v74, v73, v76
	v_add_u32_e32 v74, 0x4000, v74
	v_ashrrev_i32_e32 v75, 31, v74
	v_lshrrev_b32_e32 v75, 28, v75
	v_add_u32_e32 v74, v74, v75
	v_and_b32_e32 v74, -16, v74
	v_sub_u32_e32 v73, v73, v77
	v_add_u32_e32 v74, v74, v49
	s_mov_b32 m0, s28
	v_add_u32_e32 v73, 0x6000, v73
	buffer_load_dwordx4 v74, s[16:19], 0 offen sc0 nt lds
	v_ashrrev_i32_e32 v74, 31, v73
	v_lshrrev_b32_e32 v74, 28, v74
	v_add_u32_e32 v73, v73, v74
	v_and_b32_e32 v73, -16, v73
	v_readfirstlane_b32 s28, v77
	v_add_u32_e32 v73, v73, v50
	s_mov_b32 m0, s28
	s_nop 0
	buffer_load_dwordx4 v73, s[16:19], 0 offen sc0 nt lds
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v73, s26, v68
	v_add_u32_e32 v74, v73, v72
	s_barrier
	v_add_u32_e32 v75, v73, v71
	ds_read_u8 v170, v74
	ds_read_u8 v171, v74 offset:4
	ds_read_u8 v172, v74 offset:8
	ds_read_u8 v173, v74 offset:12
	ds_read_u8 v174, v75
	ds_read_u8 v175, v75 offset:4
	ds_read_u8 v176, v75 offset:8
	ds_read_u8 v177, v75 offset:12
	v_add_u32_e32 v74, v73, v41
	v_add_u32_e32 v73, v73, v46
	ds_read_u8 v178, v74
	ds_read_u8 v179, v74 offset:4
	ds_read_u8 v180, v74 offset:8
	ds_read_u8 v181, v74 offset:12
	ds_read_u8 v182, v73
	ds_read_u8 v183, v73 offset:4
	ds_read_u8 v184, v73 offset:8
	ds_read_u8 v73, v73 offset:12
	v_add_u32_e32 v74, s27, v68
	v_add_u32_e32 v75, v74, v70
	v_add_u32_e32 v74, v74, v69
	ds_read_u8 v185, v75
	ds_read_u8 v186, v75 offset:4
	ds_read_u8 v187, v75 offset:8
	ds_read_u8 v188, v75 offset:12
	ds_read_u8 v189, v74
	ds_read_u8 v190, v74 offset:4
	ds_read_u8 v191, v74 offset:8
	ds_read_u8 v192, v74 offset:12
	v_add_u32_e32 v122, s33, v35
	v_add_u32_e32 v123, s33, v63
	v_add_u32_e32 v130, s33, v61
	v_add_u32_e32 v131, s33, v62
	v_add_u32_e32 v154, s25, v35
	v_add_u32_e32 v155, s25, v63
	v_add_u32_e32 v162, s25, v61
	v_add_u32_e32 v163, s25, v62
	v_add_u32_e32 v74, v122, v55
	v_add_u32_e32 v78, v123, v55
	v_add_u32_e32 v82, v130, v55
	v_add_u32_e32 v86, v131, v55
	v_add_u32_e32 v90, v122, v52
	v_add_u32_e32 v94, v123, v52
	v_add_u32_e32 v98, v130, v52
	v_add_u32_e32 v102, v131, v52
	v_add_u32_e32 v106, v122, v39
	v_add_u32_e32 v110, v123, v39
	v_add_u32_e32 v114, v130, v39
	v_add_u32_e32 v118, v131, v39
	v_add_u32_e32 v122, v122, v37
	v_add_u32_e32 v126, v123, v37
	v_add_u32_e32 v130, v130, v37
	v_add_u32_e32 v134, v131, v37
	v_add_u32_e32 v138, v154, v60
	v_add_u32_e32 v142, v155, v60
	v_add_u32_e32 v146, v162, v60
	v_add_u32_e32 v150, v163, v60
	v_add_u32_e32 v154, v154, v56
	v_add_u32_e32 v158, v155, v56
	v_add_u32_e32 v162, v162, v56
	v_add_u32_e32 v166, v163, v56
	ds_read_b128 v[74:77], v74
	ds_read_b128 v[78:81], v78
	ds_read_b128 v[82:85], v82
	ds_read_b128 v[86:89], v86
	ds_read_b128 v[90:93], v90
	ds_read_b128 v[94:97], v94
	ds_read_b128 v[98:101], v98
	ds_read_b128 v[102:105], v102
	ds_read_b128 v[106:109], v106
	ds_read_b128 v[110:113], v110
	ds_read_b128 v[114:117], v114
	ds_read_b128 v[118:121], v118
	ds_read_b128 v[122:125], v122
	ds_read_b128 v[126:129], v126
	ds_read_b128 v[130:133], v130
	ds_read_b128 v[134:137], v134
	ds_read_b128 v[138:141], v138
	ds_read_b128 v[142:145], v142
	ds_read_b128 v[146:149], v146
	ds_read_b128 v[150:153], v150
	ds_read_b128 v[154:157], v154
	ds_read_b128 v[158:161], v158
	ds_read_b128 v[162:165], v162
	ds_read_b128 v[166:169], v166
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(7)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[138:141], v[74:77], v[30:33], v185, v170 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_u32 s4, s4, 0x100
	s_addc_u32 s5, s5, 0
	s_add_u32 s2, s2, 0x100
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[154:157], v[74:77], v[22:25], v189, v170 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s3, s3, 0
	s_add_u32 s0, s0, 16
	s_addc_u32 s1, s1, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[138:141], v[90:93], v[26:29], v185, v174 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cmpk_lg_i32 s0, 0x200
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[154:157], v[90:93], v[18:21], v189, v174 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[138:141], v[106:109], v[14:17], v185, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[154:157], v[106:109], v[6:9], v189, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[138:141], v[122:125], v[2:5], v185, v182 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[154:157], v[122:125], v[10:13], v189, v182 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[142:145], v[78:81], v[30:33], v186, v171 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[158:161], v[78:81], v[22:25], v190, v171 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[142:145], v[94:97], v[26:29], v186, v175 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[158:161], v[94:97], v[18:21], v190, v175 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[142:145], v[110:113], v[14:17], v186, v179 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[158:161], v[110:113], v[6:9], v190, v179 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[142:145], v[126:129], v[2:5], v186, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[158:161], v[126:129], v[10:13], v190, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[146:149], v[82:85], v[30:33], v187, v172 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:165], v[82:85], v[22:25], v191, v172 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[146:149], v[98:101], v[26:29], v187, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[162:165], v[98:101], v[18:21], v191, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[146:149], v[114:117], v[14:17], v187, v180 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:165], v[114:117], v[6:9], v191, v180 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[146:149], v[130:133], v[2:5], v187, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[162:165], v[130:133], v[10:13], v191, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[150:153], v[86:89], v[30:33], v188, v173 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[166:169], v[86:89], v[22:25], v192, v173 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[150:153], v[102:105], v[26:29], v188, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[166:169], v[102:105], v[18:21], v192, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[150:153], v[118:121], v[14:17], v188, v181 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[166:169], v[118:121], v[6:9], v192, v181 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[150:153], v[134:137], v[2:5], v188, v73 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[166:169], v[134:137], v[10:13], v192, v73 op_sel_hi:[0,0,0] cbsz:4 blgp:4
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
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[68:71], v[48:51], v[30:33], v104, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_ashr_i32 s0, s13, 31
	s_ashr_i32 s21, s20, 31
	s_movk_i32 s10, 0x78c
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[88:91], v[48:51], v[22:25], v108, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[48:51], v35
	v_add_u32_e32 v35, v62, v56
	v_lshlrev_b32_e32 v1, 3, v1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[72:75], v[64:67], v[30:33], v105, v54 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mul_u32_u24_e32 v43, 0x1a000, v43
	s_mov_b32 s11, 0x27000
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[92:95], v[64:67], v[22:25], v109, v54 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[54:57], v35
	v_add_u32_e32 v35, v112, v52
	ds_read_b128 v[62:65], v35
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[76:79], v[80:83], v[30:33], v106, v96 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v35, v113, v52
	v_add_u32_e32 v66, v113, v39
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[48:51], v[80:83], v[22:25], v110, v96 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[80:83], v35
	v_add_u32_e32 v35, v114, v52
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[58:61], v[84:87], v[30:33], v107, v97 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[54:57], v[84:87], v[22:25], v111, v97 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[84:87], v35
	v_add_u32_e32 v35, v115, v52
	ds_read_b128 v[96:99], v35
	v_add_u32_e32 v35, v47, v41
	v_add_u32_e32 v41, v47, v46
	v_add_u32_e32 v46, v112, v39
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[68:71], v[62:65], v[26:29], v104, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v25, v24, v25
	v_cvt_pk_bf16_f32 v24, v22, v23
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[88:91], v[62:65], v[18:21], v108, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[62:65], v46
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[72:75], v[80:83], v[26:29], v105, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[92:95], v[80:83], v[18:21], v109, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
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
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[68:71], v[62:65], v[14:17], v104, v46 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v39, v115, v39
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[88:91], v[62:65], v[6:9], v108, v46 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[76:79], v[84:87], v[26:29], v106, v102 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[48:51], v[84:87], v[18:21], v110, v102 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[84:87], v66
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[72:75], v[80:83], v[14:17], v105, v47 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[92:95], v[80:83], v[6:9], v109, v47 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v47, s21
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[58:61], v[96:99], v[26:29], v107, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[54:57], v[96:99], v[18:21], v111, v103 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[96:99], v39
	v_add_u32_e32 v39, v112, v37
	ds_read_b128 v[62:65], v39
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[76:79], v[84:87], v[14:17], v106, v52 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[48:51], v[84:87], v[6:9], v110, v52 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_nop 1
	v_cvt_pk_bf16_f32 v21, v20, v21
	v_cvt_pk_bf16_f32 v20, v18, v19
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[58:61], v[96:99], v[14:17], v107, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[54:57], v[96:99], v[6:9], v111, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v35, v113, v37
	ds_read_b128 v[80:83], v35
	v_add_u32_e32 v35, v114, v37
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[68:71], v[62:65], v[2:5], v104, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[66:69], v35
	v_add_u32_e32 v35, v115, v37
	v_mov_b32_e32 v39, s0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[88:91], v[62:65], v[10:13], v108, v53 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v37, s0
	v_cvt_pk_bf16_f32 v9, v8, v9
	v_cvt_pk_bf16_f32 v8, v6, v7
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[72:75], v[80:83], v[2:5], v105, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[70:73], v35
	v_mov_b32_e32 v35, s0
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[92:95], v[80:83], v[10:13], v109, v100 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_barrier
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[76:79], v[66:69], v[2:5], v106, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[48:51], v[66:69], v[10:13], v110, v101 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_lshlrev_b32_e32 v48, 3, v0
	v_lshl_or_b32 v0, v0, 7, v42
	v_and_or_b32 v0, v0, s10, v45
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[58:61], v[70:73], v[2:5], v107, v41 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or3_b32 v0, v0, v44, v1
	s_movk_i32 s10, 0x7f8
	v_and_b32_e32 v49, 0x78, v48
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[54:57], v[70:73], v[10:13], v111, v41 op_sel_hi:[0,0,0] cbsz:4 blgp:4
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
	v_cvt_pk_bf16_f32 v1, v32, v33
	v_cvt_pk_bf16_f32 v0, v30, v31
	ds_write2_b64 v35, v[0:1], v[24:25] offset1:16
	v_lshrrev_b32_e32 v0, 3, v34
	v_and_b32_e32 v0, 0x1f0, v0
	v_lshlrev_b32_e32 v1, 1, v34
	v_add3_u32 v30, 0, v0, v1
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[22:25], v30
	v_or_b32_e32 v46, s20, v49
	s_ashr_i32 s15, s14, 31
	v_cvt_pk_bf16_f32 v1, v28, v29
	v_cvt_pk_bf16_f32 v0, v26, v27
	v_or_b32_e32 v43, v43, v49
	v_cmp_gt_i64_e64 s[6:7], s[12:13], v[38:39]
	v_cmp_gt_i64_e64 s[2:3], s[14:15], v[46:47]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[0:1], v[20:21] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[18:21], v30
	v_cvt_pk_bf16_f32 v1, v16, v17
	v_cvt_pk_bf16_f32 v0, v14, v15
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[0:1], v[8:9] offset1:16
	v_cvt_pk_bf16_f32 v1, v4, v5
	v_cvt_pk_bf16_f32 v0, v2, v3
	v_cvt_pk_bf16_f32 v3, v12, v13
	v_cvt_pk_bf16_f32 v2, v10, v11
	v_lshlrev_b32_e32 v4, 1, v43
	v_bfrev_b32_e32 v5, 1
	s_and_b64 s[6:7], s[6:7], s[2:3]
	v_cmp_gt_i64_e64 s[4:5], s[12:13], v[36:37]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[6:9], v30
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v35, v[0:1], v[2:3] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[0:3], v30
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s10, 0x7ffffffe
	v_cndmask_b32_e64 v10, v5, v4, s[6:7]
	buffer_store_dwordx4 v[22:25], v10, s[8:11], 0 offen
	v_add_u32_e32 v10, 0x680000, v4
	s_and_b64 s[4:5], s[4:5], s[2:3]
	v_cmp_gt_i64_e32 vcc, s[12:13], v[40:41]
	v_cndmask_b32_e64 v10, v5, v10, s[4:5]
	buffer_store_dwordx4 v[18:21], v10, s[8:11], 0 offen
	v_add_u32_e32 v10, 0xd00000, v4
	s_and_b64 s[0:1], s[0:1], s[2:3]
	v_add_u32_e32 v4, 0x1380000, v4
	s_and_b64 vcc, vcc, s[2:3]
	v_cndmask_b32_e64 v10, v5, v10, s[0:1]
	v_cndmask_b32_e32 v4, v5, v4, vcc
	buffer_store_dwordx4 v[6:9], v10, s[8:11], 0 offen
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[0:3], v4, s[8:11], 0 offen
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
		.amdhsa_next_free_vgpr 193
		.amdhsa_next_free_sgpr 34
		.amdhsa_accum_offset 196
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
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 193
	.set _gemm_afp4_wfp4_kernel.num_agpr, 0
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 34
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5544
; TotalNumSgprs: 40
; NumVgprs: 193
; NumAgprs: 0
; TotalNumVgprs: 193
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 4
; VGPRBlocks: 24
; NumSGPRsForWavesPerEU: 40
; NumVGPRsForWavesPerEU: 193
; AccumOffset: 196
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 48
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
    .sgpr_count:     40
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     193
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
