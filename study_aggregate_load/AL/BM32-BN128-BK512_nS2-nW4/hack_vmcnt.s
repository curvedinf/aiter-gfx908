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
; %bb.3:
	.file	1 "/app/aiter/aiter/ops/triton" "gemm_afp4wfp4.py"
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.p2align	8
; %bb.4:
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
	s_mov_b32 s14, s13
	s_sub_i32 s13, 0, s1
	s_mov_b64 s[20:21], s[10:11]
	v_rcp_iflag_f32_e32 v1, v1
	s_abs_i32 s11, s16
	s_xor_b32 s10, s16, s0
	s_ashr_i32 s10, s10, 31
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_lshlrev_b32_e32 v20, 4, v0
	v_and_b32_e32 v30, 0xfe0, v20
	v_and_b32_e32 v25, 0x70, v20
	v_readfirstlane_b32 s15, v1
	s_mul_i32 s13, s13, s15
	s_mul_hi_u32 s13, s15, s13
	s_add_i32 s15, s15, s13
	s_mul_hi_u32 s13, s11, s15
	s_mul_i32 s15, s13, s1
	s_sub_i32 s11, s11, s15
	s_add_i32 s15, s13, 1
	s_sub_i32 s17, s11, s1
	s_cmp_ge_u32 s11, s1
	s_cselect_b32 s13, s15, s13
	s_cselect_b32 s11, s17, s11
	s_add_i32 s15, s13, 1
	s_cmp_ge_u32 s11, s1
	s_cselect_b32 s1, s15, s13
	s_xor_b32 s1, s1, s10
	s_sub_i32 s1, s1, s10
	s_mul_i32 s0, s1, s0
	s_sub_i32 s10, s16, s0
	s_abs_i32 s0, s12
	v_cvt_f32_u32_e32 v3, s0
	s_lshl_b32 s13, s1, 5
	v_lshrrev_b32_e32 v1, 4, v0
	s_bfe_i32 s15, s1, 0x1001a
	v_rcp_iflag_f32_e32 v3, v3
	s_sub_i32 s1, 0, s0
	v_or_b32_e32 v2, s13, v1
	v_add_u32_e32 v7, s15, v2
	v_mul_f32_e32 v3, 0x4f7ffffe, v3
	v_cvt_u32_f32_e32 v3, v3
	v_xor_b32_e32 v7, s15, v7
	v_or_b32_e32 v5, 16, v1
	v_or_b32_e32 v4, s13, v5
	v_mul_lo_u32 v8, s1, v3
	v_mul_hi_u32 v8, v3, v8
	v_add_u32_e32 v3, v3, v8
	v_mul_hi_u32 v8, v7, v3
	v_mul_lo_u32 v8, v8, s0
	v_sub_u32_e32 v7, v7, v8
	v_subrev_u32_e32 v8, s0, v7
	v_cmp_le_u32_e32 vcc, s0, v7
	s_abs_i32 s16, s14
	v_and_or_b32 v6, v20, 16, s13
	v_cndmask_b32_e32 v7, v7, v8, vcc
	v_subrev_u32_e32 v8, s0, v7
	v_cmp_le_u32_e32 vcc, s0, v7
	v_add_u32_e32 v6, s15, v6
	v_xor_b32_e32 v6, s15, v6
	v_cndmask_b32_e32 v7, v7, v8, vcc
	v_add_u32_e32 v8, s15, v4
	v_xor_b32_e32 v8, s15, v8
	v_mul_hi_u32 v9, v8, v3
	v_mul_lo_u32 v9, v9, s0
	v_sub_u32_e32 v8, v8, v9
	v_subrev_u32_e32 v9, s0, v8
	v_cmp_le_u32_e32 vcc, s0, v8
	v_mul_hi_u32 v3, v6, v3
	v_mul_lo_u32 v3, v3, s0
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_subrev_u32_e32 v9, s0, v8
	v_cmp_le_u32_e32 vcc, s0, v8
	v_sub_u32_e32 v3, v6, v3
	v_subrev_u32_e32 v6, s0, v3
	v_cndmask_b32_e32 v21, v8, v9, vcc
	v_cvt_f32_u32_e32 v8, s16
	v_cmp_le_u32_e32 vcc, s0, v3
	s_sub_i32 s1, 0, s16
	s_bfe_i32 s17, s10, 0x10018
	v_rcp_iflag_f32_e32 v8, v8
	v_cndmask_b32_e32 v3, v3, v6, vcc
	v_subrev_u32_e32 v6, s0, v3
	v_cmp_le_u32_e32 vcc, s0, v3
	v_mul_f32_e32 v8, 0x4f7ffffe, v8
	v_cvt_u32_f32_e32 v8, v8
	s_lshl_b32 s0, s10, 7
	v_or_b32_e32 v9, s0, v1
	v_add_u32_e32 v23, s17, v9
	v_mul_lo_u32 v10, s1, v8
	v_mul_hi_u32 v10, v8, v10
	v_xor_b32_e32 v9, s17, v23
	v_add_u32_e32 v24, v8, v10
	v_mul_hi_u32 v8, v9, v24
	v_mul_lo_u32 v8, v8, s16
	v_cndmask_b32_e32 v3, v3, v6, vcc
	v_sub_u32_e32 v8, v9, v8
	v_xor_b32_e32 v3, s15, v3
	v_or_b32_e32 v5, s0, v5
	v_subrev_u32_e32 v9, s16, v8
	v_cmp_le_u32_e32 vcc, s16, v8
	v_subrev_u32_e32 v3, s15, v3
	v_add_u32_e32 v5, s17, v5
	v_cndmask_b32_e32 v12, v8, v9, vcc
	v_subrev_u32_e32 v13, s16, v12
	v_add_u32_e32 v3, v3, v30
	v_cmp_le_u32_e32 vcc, s16, v12
	v_xor_b32_e32 v5, s17, v5
	s_and_b32 s9, s9, 0xffff
	s_mov_b32 s11, 0x27000
	s_mov_b32 s10, 0x7ffffffe
	v_cndmask_b32_e32 v58, v12, v13, vcc
	v_mul_hi_u32 v12, v5, v24
	v_add_u32_e32 v27, 0x1000, v3
	buffer_load_dwordx4 v[8:11], v3, s[8:11], 0 offen
	v_mul_lo_u32 v26, v12, s16
	v_add_u32_e32 v28, 0x2000, v3
	buffer_load_dwordx4 v[12:15], v27, s[8:11], 0 offen
	buffer_load_dwordx4 v[16:19], v28, s[8:11], 0 offen
	v_sub_u32_e32 v5, v5, v26
	v_subrev_u32_e32 v26, s16, v5
	v_cmp_le_u32_e32 vcc, s16, v5
	v_or_b32_e32 v22, s0, v25
	v_add_u32_e32 v22, s17, v22
	v_cndmask_b32_e32 v5, v5, v26, vcc
	v_subrev_u32_e32 v26, s16, v5
	v_cmp_le_u32_e32 vcc, s16, v5
	v_xor_b32_e32 v22, s17, v22
	v_lshlrev_b32_e32 v6, 3, v0
	v_cndmask_b32_e32 v5, v5, v26, vcc
	v_add_u32_e32 v26, 32, v23
	v_xor_b32_e32 v26, s17, v26
	v_mul_hi_u32 v27, v26, v24
	v_mul_lo_u32 v27, v27, s16
	v_sub_u32_e32 v26, v26, v27
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_add_u32_e32 v3, 0x3000, v3
	s_add_i32 s1, 0, 0x20000
	v_cndmask_b32_e32 v26, v26, v27, vcc
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_lshrrev_b32_e32 v64, 3, v0
	s_and_b32 s21, s21, 0xffff
	v_cndmask_b32_e32 v59, v26, v27, vcc
	v_add_u32_e32 v26, 48, v23
	v_xor_b32_e32 v26, s17, v26
	v_mul_hi_u32 v27, v26, v24
	v_mul_lo_u32 v27, v27, s16
	v_sub_u32_e32 v26, v26, v27
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	s_mov_b32 s22, s10
	s_mov_b32 s23, s11
	v_cndmask_b32_e32 v26, v26, v27, vcc
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_add_u32_e32 v63, 0x60, v23
	v_xor_b32_e32 v5, s17, v5
	v_cndmask_b32_e32 v60, v26, v27, vcc
	v_add_u32_e32 v26, 64, v23
	v_xor_b32_e32 v26, s17, v26
	v_mul_hi_u32 v27, v26, v24
	v_mul_lo_u32 v27, v27, s16
	v_sub_u32_e32 v26, v26, v27
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_xor_b32_e32 v7, s15, v7
	s_add_i32 s18, 0, 0x24000
	v_cndmask_b32_e32 v26, v26, v27, vcc
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	s_add_i32 s19, 0, 0x10000
	v_or_b32_e32 v25, 0x80, v25
	v_cndmask_b32_e32 v61, v26, v27, vcc
	v_add_u32_e32 v26, 0x50, v23
	v_xor_b32_e32 v26, s17, v26
	v_mul_hi_u32 v27, v26, v24
	v_mul_lo_u32 v27, v27, s16
	v_sub_u32_e32 v26, v26, v27
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_accvgpr_write_b32 a3, 0
	v_accvgpr_write_b32 a2, 0
	v_cndmask_b32_e32 v26, v26, v27, vcc
	v_subrev_u32_e32 v27, s16, v26
	v_cmp_le_u32_e32 vcc, s16, v26
	v_accvgpr_write_b32 a1, 0
	v_accvgpr_write_b32 a0, 0
	v_cndmask_b32_e32 v62, v26, v27, vcc
	v_mul_hi_u32 v26, v22, v24
	v_mul_lo_u32 v26, v26, s16
	v_sub_u32_e32 v22, v22, v26
	v_subrev_u32_e32 v26, s16, v22
	v_cmp_le_u32_e32 vcc, s16, v22
	v_accvgpr_write_b32 a7, 0
	v_accvgpr_write_b32 a6, 0
	v_cndmask_b32_e32 v22, v22, v26, vcc
	v_subrev_u32_e32 v26, s16, v22
	v_cmp_le_u32_e32 vcc, s16, v22
	v_accvgpr_write_b32 a5, 0
	v_accvgpr_write_b32 a4, 0
	v_cndmask_b32_e32 v22, v22, v26, vcc
	v_xor_b32_e32 v22, s17, v22
	v_subrev_u32_e32 v22, s17, v22
	buffer_load_dwordx4 v[26:29], v3, s[8:11], 0 offen
	v_bitop3_b32 v3, v20, 16, v6 bitop3:0x48
	s_mov_b32 s8, 0xd000
	v_add3_u32 v3, s1, v3, v30
	v_mad_u32_u24 v22, v64, s8, v22
	s_waitcnt vmcnt(3)
	ds_write_b128 v3, v[8:11]
	buffer_load_dwordx4 v[30:33], v22, s[20:23], 0 offen
	s_waitcnt vmcnt(3)
	ds_write_b128 v3, v[12:15] offset:4096
	s_waitcnt vmcnt(2)
	ds_write_b128 v3, v[16:19] offset:8192
	v_add_u32_e32 v8, 0x1a0000, v22
	buffer_load_dwordx4 v[14:17], v8, s[20:23], 0 offen
	v_add_u32_e32 v8, 0x340000, v22
	v_add_u32_e32 v9, 0x4e0000, v22
	buffer_load_dwordx4 v[34:37], v8, s[20:23], 0 offen
	buffer_load_dwordx4 v[38:41], v9, s[20:23], 0 offen
	v_add_u32_e32 v8, 0x680000, v22
	v_add_u32_e32 v9, 0x820000, v22
	buffer_load_dwordx4 v[42:45], v8, s[20:23], 0 offen
	v_add_u32_e32 v8, 0x9c0000, v22
	v_add_u32_e32 v10, 0xb60000, v22
	buffer_load_dwordx4 v[46:49], v9, s[20:23], 0 offen
	buffer_load_dwordx4 v[50:53], v8, s[20:23], 0 offen
	buffer_load_dwordx4 v[54:57], v10, s[20:23], 0 offen
	v_xor_b32_e32 v8, s17, v63
	v_mul_hi_u32 v9, v8, v24
	v_mul_lo_u32 v9, v9, s16
	v_sub_u32_e32 v8, v8, v9
	v_subrev_u32_e32 v9, s16, v8
	v_cmp_le_u32_e32 vcc, s16, v8
	v_subrev_u32_e32 v19, s15, v7
	v_xor_b32_e32 v7, s15, v21
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_subrev_u32_e32 v9, s16, v8
	v_cmp_le_u32_e32 vcc, s16, v8
	s_movk_i32 s8, 0x70
	v_subrev_u32_e32 v63, s15, v7
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_subrev_u32_e32 v9, s17, v5
	v_xor_b32_e32 v5, s17, v59
	v_subrev_u32_e32 v10, s17, v5
	v_xor_b32_e32 v5, s17, v60
	v_subrev_u32_e32 v11, s17, v5
	v_xor_b32_e32 v5, s17, v61
	v_subrev_u32_e32 v12, s17, v5
	v_xor_b32_e32 v5, s17, v62
	v_subrev_u32_e32 v13, s17, v5
	v_xor_b32_e32 v5, s17, v8
	v_subrev_u32_e32 v21, s17, v5
	v_add_u32_e32 v5, 0x70, v23
	v_xor_b32_e32 v5, s17, v5
	v_mul_hi_u32 v8, v5, v24
	v_mul_lo_u32 v8, v8, s16
	v_sub_u32_e32 v5, v5, v8
	v_subrev_u32_e32 v8, s16, v5
	v_cmp_le_u32_e32 vcc, s16, v5
	v_xor_b32_e32 v7, s17, v58
	v_subrev_u32_e32 v7, s17, v7
	v_cndmask_b32_e32 v5, v5, v8, vcc
	v_subrev_u32_e32 v8, s16, v5
	v_cmp_le_u32_e32 vcc, s16, v5
	v_and_b32_e32 v24, 0xf0, v20
	v_add_u32_e32 v58, 0x11e0000, v22
	v_cndmask_b32_e32 v5, v5, v8, vcc
	v_xor_b32_e32 v5, s17, v5
	v_subrev_u32_e32 v23, s17, v5
	v_lshl_or_b32 v5, v7, 13, v24
	v_lshl_or_b32 v7, v9, 13, v24
	v_lshl_or_b32 v8, v10, 13, v24
	v_lshl_or_b32 v9, v11, 13, v24
	v_lshl_or_b32 v10, v12, 13, v24
	v_lshl_or_b32 v11, v13, 13, v24
	v_lshl_or_b32 v12, v21, 13, v24
	v_lshl_or_b32 v13, v23, 13, v24
	v_add_u32_e32 v21, 0xea0000, v22
	v_add_u32_e32 v23, 0x1040000, v22
	s_movk_i32 s9, 0xf0
	v_add_u32_e32 v65, 0x1520000, v22
	v_and_b32_e32 v18, 63, v0
	v_add_u32_e32 v66, 0x16c0000, v22
	v_accvgpr_write_b32 a11, 0
	v_accvgpr_write_b32 a10, 0
	v_accvgpr_write_b32 a9, 0
	v_accvgpr_write_b32 a8, 0
	v_accvgpr_write_b32 a15, 0
	s_waitcnt vmcnt(8)
	ds_write_b128 v3, v[26:29] offset:12288
	v_lshlrev_b32_e32 v26, 1, v0
	v_bitop3_b32 v26, v20, s8, v26 bitop3:0x48
	v_lshlrev_b32_e32 v27, 7, v64
	v_add3_u32 v62, 0, v26, v27
	v_add_u32_e32 v3, 0xd00000, v22
	s_waitcnt vmcnt(7)
	ds_write_b128 v62, v[30:33]
	v_add_u32_e32 v64, 0x1380000, v22
	s_mov_b32 s8, s2
	s_waitcnt vmcnt(6)
	ds_write_b128 v62, v[14:17] offset:4096
	buffer_load_dwordx4 v[26:29], v3, s[20:23], 0 offen
	buffer_load_dwordx4 v[30:33], v21, s[20:23], 0 offen
	s_waitcnt vmcnt(7)
	ds_write_b128 v62, v[34:37] offset:8192
	s_waitcnt vmcnt(6)
	ds_write_b128 v62, v[38:41] offset:12288
	buffer_load_dwordx4 v[34:37], v23, s[20:23], 0 offen
	buffer_load_dwordx4 v[38:41], v58, s[20:23], 0 offen
	v_and_b32_e32 v14, 0xc0, v0
	s_waitcnt vmcnt(7)
	ds_write_b128 v62, v[42:45] offset:16384
	buffer_load_dwordx4 v[42:45], v64, s[20:23], 0 offen
	buffer_load_dwordx4 v[58:61], v65, s[20:23], 0 offen
	s_waitcnt vmcnt(8)
	ds_write_b128 v62, v[46:49] offset:20480
	s_waitcnt vmcnt(7)
	ds_write_b128 v62, v[50:53] offset:24576
	s_waitcnt vmcnt(6)
	ds_write_b128 v62, v[54:57] offset:28672
	v_and_b32_e32 v54, 48, v0
	v_bitop3_b32 v3, v20, v54, s9 bitop3:0x6c
	v_xor_b32_e32 v15, v3, v14
	v_sub_u32_e32 v21, v15, v24
	v_ashrrev_i16_e32 v21, 4, v21
	v_mov_b32_e32 v23, 4
	v_lshlrev_b32_sdwa v55, v23, sext(v21) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshlrev_b32_e32 v16, 8, v1
	v_add_u32_sdwa v18, v18, sext(v21) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_add_u32_e32 v23, v55, v24
	v_or_b32_e32 v17, v24, v16
	v_lshl_add_u32 v21, v19, 13, v23
	v_lshrrev_b64 v[18:19], v18, exec
	v_add_u32_e32 v14, s18, v17
	v_and_b32_e32 v18, 1, v18
	v_add_u32_e32 v46, 0x1000, v14
	v_bfrev_b32_e32 v19, 1
	v_cmp_eq_u32_e32 vcc, 1, v18
	v_readfirstlane_b32 s15, v14
	s_and_b32 s9, s3, 0xffff
	v_cndmask_b32_e32 v18, v19, v21, vcc
	s_mov_b32 m0, s15
	v_lshl_add_u32 v23, v63, 13, v23
	v_readfirstlane_b32 s15, v46
	buffer_load_dwordx4 v18, s[8:11], 0 offen lds
	v_cndmask_b32_e32 v14, v19, v23, vcc
	s_mov_b32 m0, s15
	v_add_u32_e32 v49, v5, v55
	buffer_load_dwordx4 v14, s[8:11], 0 offen lds
	v_add_u32_e32 v14, s19, v17
	v_add_u32_e32 v18, 0x1000, v14
	v_readfirstlane_b32 s15, v14
	s_and_b32 s9, s5, 0xffff
	s_mov_b32 s8, s4
	v_cndmask_b32_e32 v49, v19, v49, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v18
	v_add_u32_e32 v18, v7, v55
	v_add_u32_e32 v24, 0x2000, v14
	buffer_load_dwordx4 v49, s[8:11], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v24
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v18, v8, v55
	v_add_u32_e32 v46, 0x3000, v14
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v46
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v18, v9, v55
	v_add_u32_e32 v47, 0x4000, v14
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v47
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v18, v10, v55
	v_add_u32_e32 v48, 0x5000, v14
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v48
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v18, v11, v55
	v_add_u32_e32 v49, 0x6000, v14
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_readfirstlane_b32 s15, v49
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v18, v12, v55
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_add_u32_e32 v22, 0x1860000, v22
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	buffer_load_dwordx4 v[46:49], v66, s[20:23], 0 offen
	buffer_load_dwordx4 v[50:53], v22, s[20:23], 0 offen
	v_add_u32_e32 v14, 0x7000, v14
	v_add_u32_e32 v18, v13, v55
	v_readfirstlane_b32 s15, v14
	v_cndmask_b32_e32 v18, v19, v18, vcc
	s_mov_b32 m0, s15
	v_bfe_i32 v22, v0, 4, 1
	buffer_load_dwordx4 v18, s[8:11], 0 offen sc0 nt lds
	v_and_b32_e32 v14, 32, v0
	s_waitcnt vmcnt(0)
	ds_write_b128 v62, v[26:29] offset:32768
	v_and_b32_e32 v28, 15, v0
	ds_write_b128 v62, v[30:33] offset:36864
	ds_write_b128 v62, v[34:37] offset:40960
	ds_write_b128 v62, v[38:41] offset:45056
	ds_write_b128 v62, v[42:45] offset:49152
	ds_write_b128 v62, v[58:61] offset:53248
	ds_write_b128 v62, v[46:49] offset:57344
	ds_write_b128 v62, v[50:53] offset:61440
	v_and_b32_e32 v30, 48, v22
	v_lshlrev_b32_e32 v18, 1, v14
	v_or_b32_e32 v14, 16, v28
	v_bfe_i32 v24, v0, 5, 1
	v_bitop3_b32 v19, v22, v14, 48 bitop3:0x6c
	v_bitop3_b32 v32, v18, v30, v14 bitop3:0xf6
	v_lshrrev_b32_e32 v14, 2, v0
	v_and_or_b32 v34, v14, 48, v28
	v_and_b32_e32 v22, 0x90, v22
	v_and_b32_e32 v24, 0x120, v24
	v_and_b32_e32 v55, 48, v20
	v_or_b32_e32 v26, v24, v22
	v_or_b32_e32 v27, 64, v34
	s_movk_i32 s8, 0x400
	v_and_b32_e32 v56, 0x80, v20
	v_bitop3_b32 v33, v26, s8, v27 bitop3:0xde
	v_bitop3_b32 v26, v55, v20, 64 bitop3:0x72
	s_add_u32 s4, s4, 0x100
	v_bitop3_b32 v29, v24, v34, v22 bitop3:0x36
	v_bitop3_b32 v22, v24, v27, v22 bitop3:0x36
	v_bitop3_b32 v27, v26, v54, v56 bitop3:0x36
	v_bitop3_b32 v26, v56, v25, v54 bitop3:0x36
	v_or_b32_e32 v25, 0xc0, v55
	v_and_or_b32 v20, v20, 64, v54
	s_addc_u32 s5, s5, 0
	v_bitop3_b32 v25, v20, v25, v56 bitop3:0x36
	v_lshlrev_b32_e32 v20, 8, v0
	s_add_u32 s2, s2, 0x100
	s_mov_b32 s22, 0
	v_or3_b32 v31, v18, v28, v30
	v_lshlrev_b32_e32 v24, 8, v28
	v_and_b32_e32 v20, 0xf00, v20
	v_lshlrev_b32_e32 v34, 8, v34
	s_addc_u32 s3, s3, 0
	v_accvgpr_write_b32 a14, 0
	v_accvgpr_write_b32 a13, 0
	v_accvgpr_write_b32 a12, 0
	s_movk_i32 s15, 0x240
	s_movk_i32 s16, 0x640
	s_mov_b32 s17, 0
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_add_i32 s9, s22, 1
	s_cmp_lt_i32 s9, 2
	s_cselect_b32 s22, s9, 0
	s_mov_b32 s21, s18
	s_mov_b32 s20, s19
	s_lshl_b32 s18, s22, 13
	s_lshl_b32 s19, s22, 15
	s_add_i32 s18, s18, 0
	s_add_i32 s19, s19, 0
	s_and_b32 s23, s17, 1
	s_add_i32 s18, s18, 0x24000
	s_add_i32 s19, s19, 0x10000
	s_lshl_b32 s27, s23, 9
	v_add_u32_e32 v40, s18, v17
	v_add3_u32 v41, s19, v15, v16
	v_add_u32_e32 v42, s19, v17
	v_or_b32_e32 v37, s27, v31
	v_or_b32_e32 v38, s27, v32
	v_add_u32_e32 v45, 0x1000, v40
	v_readfirstlane_b32 s27, v40
	v_add_u32_e32 v40, 0x1000, v42
	v_sub_u32_e32 v54, v41, v42
	v_add_u32_e32 v46, 0x2000, v42
	v_add_u32_e32 v47, 0x3000, v42
	v_add_u32_e32 v49, 0x4000, v42
	v_add_u32_e32 v50, 0x5000, v42
	v_add_u32_e32 v51, 0x6000, v42
	v_add_u32_e32 v53, 0x7000, v42
	v_readfirstlane_b32 s31, v42
	v_readfirstlane_b32 s33, v45
	v_ashrrev_i32_e32 v42, 31, v54
	v_sub_u32_e32 v45, v41, v40
	v_readfirstlane_b32 s34, v40
	v_sub_u32_e32 v40, v41, v46
	v_lshrrev_b32_e32 v42, 28, v42
	v_add_u32_e32 v45, 0x1000, v45
	s_mov_b32 s8, s2
	s_and_b32 s9, s3, 0xffff
	v_readfirstlane_b32 s35, v46
	v_sub_u32_e32 v46, v41, v47
	v_readfirstlane_b32 s36, v47
	v_sub_u32_e32 v47, v41, v49
	v_readfirstlane_b32 s37, v49
	v_sub_u32_e32 v49, v41, v50
	v_readfirstlane_b32 s38, v50
	v_sub_u32_e32 v50, v41, v51
	v_readfirstlane_b32 s39, v51
	s_mov_b32 m0, s27
	v_add_u32_e32 v40, 0x2000, v40
	v_add_u32_e32 v42, v54, v42
	v_ashrrev_i32_e32 v51, 31, v45
                                ; s_waitcnt vmcnt(0) lgkmcnt(0)
        ;; breakdown vmcnt
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_sub_u32_e32 v41, v41, v53
	v_readfirstlane_b32 s40, v53
        s_waitcnt vmcnt(9)
	buffer_load_dwordx4 v21, s[8:11], 0 offen lds
	v_add_u32_e32 v46, 0x3000, v46
	s_mov_b32 m0, s33
	v_ashrrev_i32_e32 v53, 31, v40
	v_and_b32_e32 v42, -16, v42
	v_lshrrev_b32_e32 v51, 28, v51
	v_add_u32_e32 v47, 0x4000, v47
        s_waitcnt vmcnt(9)
	buffer_load_dwordx4 v23, s[8:11], 0 offen lds
	s_and_b32 s9, s5, 0xffff
	s_mov_b32 s8, s4
	v_ashrrev_i32_e32 v54, 31, v46
	v_lshrrev_b32_e32 v53, 28, v53
	v_add_u32_e32 v42, v42, v5
	v_add_u32_e32 v45, v45, v51
	s_mov_b32 m0, s31
	v_add_u32_e32 v49, 0x5000, v49
	v_ashrrev_i32_e32 v55, 31, v47
	v_lshrrev_b32_e32 v54, 28, v54
	v_add_u32_e32 v40, v40, v53
        s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v42, s[8:11], 0 offen sc0 nt lds
	v_and_b32_e32 v42, -16, v45
	v_add_u32_e32 v50, 0x6000, v50
	v_ashrrev_i32_e32 v57, 31, v49
	v_lshrrev_b32_e32 v55, 28, v55
	v_add_u32_e32 v46, v46, v54
	v_and_b32_e32 v40, -16, v40
	v_add_u32_e32 v42, v42, v7
	s_mov_b32 m0, s34
	v_add_u32_e32 v41, 0x7000, v41
	v_ashrrev_i32_e32 v58, 31, v50
	v_lshrrev_b32_e32 v57, 28, v57
	v_add_u32_e32 v47, v47, v55
	v_and_b32_e32 v45, -16, v46
	v_add_u32_e32 v40, v40, v8
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v42, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s35
	v_ashrrev_i32_e32 v59, 31, v41
	v_lshrrev_b32_e32 v58, 28, v58
	v_add_u32_e32 v49, v49, v57
	v_and_b32_e32 v46, -16, v47
	v_add_u32_e32 v45, v45, v9
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v40, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s36
	v_lshrrev_b32_e32 v59, 28, v59
	v_add_u32_e32 v50, v50, v58
	v_and_b32_e32 v47, -16, v49
	v_add_u32_e32 v46, v46, v10
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v45, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s37
	v_add_u32_e32 v41, v41, v59
	v_and_b32_e32 v49, -16, v50
	v_add_u32_e32 v47, v47, v11
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v46, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s38
	v_and_b32_e32 v41, -16, v41
	v_add_u32_e32 v49, v49, v12
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v47, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s39
	v_add_u32_e32 v41, v41, v13
	s_waitcnt vmcnt(9)
        buffer_load_dwordx4 v49, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s40
	s_and_b32 s24, s17, 2
	s_waitcnt vmcnt(9)
        s_barrier
        buffer_load_dwordx4 v41, s[8:11], 0 offen sc0 nt lds
	s_and_b32 s25, s17, 4
	s_and_b32 s26, s17, 8
	s_lshl_b32 s28, s24, 9
	s_lshl_b32 s29, s25, 9
	s_lshl_b32 s30, s26, 9
	s_cmp_lt_u32 s17, 16
	v_or_b32_e32 v37, s28, v37
	s_cselect_b32 s27, 0, 0x2000
	s_cselect_b32 s33, 0, 0x8000
	s_lshl_b32 s23, s23, 11
	v_or_b32_e32 v43, s29, v37
	s_lshl_b32 s25, s25, 11
	s_or_b32 s27, s27, s30
	v_or_b32_e32 v50, s23, v29
	s_lshl_b32 s24, s24, 11
	s_lshl_b32 s26, s26, 11
	v_or_b32_e32 v51, s23, v22
	v_or_b32_e32 v54, s25, v33
	v_or_b32_e32 v43, s27, v43
	v_or_b32_e32 v50, s25, v50
	v_or_b32_e32 v51, s25, v51
	v_or_b32_e32 v54, s26, v54
	v_add_u32_e32 v42, s1, v43
	v_or_b32_e32 v43, s24, v50
	v_or_b32_e32 v50, s26, v50
	v_or_b32_e32 v39, s28, v38
	v_or_b32_e32 v38, s27, v38
	v_or_b32_e32 v51, s26, v51
	v_or_b32_e32 v54, s23, v54
	v_or_b32_e32 v40, s26, v43
	v_or_b32_e32 v43, s24, v50
	v_mov_b32_e32 v53, s33
	s_or_b32 s30, s27, s29
	v_or_b32_e32 v38, s28, v38
	v_or_b32_e32 v50, s24, v51
	v_or_b32_e32 v51, s24, v54
	v_or_b32_e32 v40, s33, v40
	v_or_b32_e32 v43, s33, v43
	v_add_u32_e32 v35, s21, v3
	v_add_u32_e32 v52, s21, v27
	v_or_b32_e32 v37, s30, v37
	v_or_b32_e32 v39, s30, v39
	v_or_b32_e32 v38, s29, v38
	v_or_b32_e32 v45, s33, v50
	v_bitop3_b32 v54, v50, s15, v53 bitop3:0x36
	v_or_b32_e32 v51, s33, v51
	v_bitop3_b32 v50, v50, s16, v53 bitop3:0x36
	v_add_u32_e32 v53, 0, v40
	v_or_b32_e32 v40, 0x240, v43
	v_add_u32_e32 v55, 0, v43
	v_or_b32_e32 v43, 0x640, v43
	v_add3_u32 v44, s20, v3, v34
	v_add_u32_e32 v36, v35, v24
	v_add_u32_e32 v48, v52, v24
	v_add_u32_e32 v37, s1, v37
	v_add_u32_e32 v39, s1, v39
	v_add_u32_e32 v38, s1, v38
	v_add_u32_e32 v57, 0, v45
	v_add_u32_e32 v51, 0, v51
	v_add_u32_e32 v50, 0, v50
	v_add_u32_e32 v58, 0, v40
	v_add_u32_e32 v59, 0, v43
	v_add_u32_e32 v54, 0, v54
	; sched_barrier mask(0x00000006)
	ds_read_u8 v60, v42
	ds_read_u8 v61, v37 offset:128
	ds_read_u8 v62, v37 offset:256
	ds_read_u8 v63, v37 offset:384
	ds_read_u8 v64, v39
	ds_read_u8 v65, v38 offset:128
	ds_read_u8 v66, v38 offset:256
	ds_read_u8 v67, v38 offset:384
	ds_read_b128 v[36:39], v36
	ds_read_b128 v[40:43], v44
	ds_read_b128 v[44:47], v44 offset:16384
	ds_read_u8 v68, v53
	ds_read_u8 v58, v58
	ds_read_u8 v69, v55 offset:1024
	ds_read_u8 v59, v59
	ds_read_u8 v57, v57
	ds_read_u8 v70, v54
	ds_read_u8 v71, v51
	ds_read_u8 v72, v50
	ds_read_b128 v[48:51], v48
	v_add_u32_e32 v35, v35, v20
	v_add_u32_e32 v52, v52, v20
	s_waitcnt lgkmcnt(8)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[36:39], a[12:15], v68, v60 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add3_u32 v56, s20, v27, v34
	s_add_i32 s17, s17, 1
	s_add_u32 s4, s4, 0x100
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[44:47], v[36:39], a[8:11], v57, v60 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v35 offset:4096
	ds_read_b128 v[52:55], v52 offset:4096
	v_add_u32_e32 v35, s21, v26
	s_addc_u32 s5, s5, 0
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[40:43], v[36:39], a[4:7], v68, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[40:43], v56
	s_add_u32 s2, s2, 0x100
	s_addc_u32 s3, s3, 0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[44:47], v[36:39], a[0:3], v57, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v56 offset:16384
	v_add_u32_e32 v56, s21, v25
	v_add3_u32 v44, s20, v26, v34
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[48:51], a[12:15], v58, v61 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add3_u32 v57, s20, v25, v34
	s_cmp_lg_u32 s17, 31
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[36:39], v[48:51], a[8:11], v70, v61 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v48, v35, v24
	v_add_u32_e32 v49, v56, v24
	v_add_u32_e32 v35, v35, v20
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[40:43], v[52:55], a[4:7], v58, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[40:43], v44
	ds_read_b128 v[44:47], v44 offset:16384
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[52:55], a[0:3], v70, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v48
	ds_read_b128 v[48:51], v49
	v_add_u32_e32 v52, v56, v20
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[36:39], a[12:15], v69, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[44:47], v[36:39], a[8:11], v71, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v35 offset:4096
	ds_read_b128 v[52:55], v52 offset:4096
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[40:43], v[36:39], a[4:7], v69, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[40:43], v57
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[44:47], v[36:39], a[0:3], v71, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v57 offset:16384
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[48:51], a[12:15], v59, v63 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[36:39], v[48:51], a[8:11], v72, v63 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[40:43], v[52:55], a[4:7], v59, v67 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[52:55], a[0:3], v72, v67 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_1
; %bb.2:
	s_add_i32 s1, 0, 0x23e00
	v_and_b32_e32 v15, 16, v14
	v_and_b32_e32 v21, 32, v14
	v_add_u32_e32 v5, s1, v28
	v_or3_b32 v16, v15, v28, v21
	v_add3_u32 v5, v5, v30, v18
	v_add_u32_e32 v8, 0, v29
	v_add_u32_e32 v17, s18, v3
	v_add_u32_e32 v67, s18, v27
	v_lshlrev_b32_e32 v16, 8, v16
	v_add_u32_e32 v68, s18, v26
	s_waitcnt vmcnt(0)
	s_barrier
	ds_read_u8 v7, v5
	ds_read_u8 v12, v5 offset:128
	ds_read_u8 v13, v5 offset:256
	ds_read_u8 v5, v5 offset:384
	ds_read_u8 v23, v8 offset:63488
	ds_read_u8 v64, v8 offset:64064
	ds_read_u8 v65, v8 offset:64512
	ds_read_u8 v66, v8 offset:65088
	v_add_u32_e32 v8, v17, v24
	v_add_u32_e32 v32, v67, v24
	v_add3_u32 v3, s19, v3, v16
	v_add3_u32 v56, s19, v27, v16
	v_add_u32_e32 v27, v68, v24
	ds_read_b128 v[8:11], v8
	ds_read_b128 v[28:31], v3
	ds_read_b128 v[32:35], v32
	ds_read_b128 v[44:47], v27
	ds_read_b128 v[52:55], v3 offset:16384
	v_add_u32_e32 v69, s18, v25
	v_add3_u32 v60, s19, v26, v16
	v_add3_u32 v16, s19, v25, v16
	v_add_u32_e32 v3, v69, v24
	ds_read_b128 v[36:39], v56
	ds_read_b128 v[40:43], v60
	ds_read_b128 v[48:51], v16
	ds_read_b128 v[24:27], v3
	v_add_u32_e32 v3, 0, v22
	ds_read_u8 v70, v3 offset:63488
	ds_read_b128 v[56:59], v56 offset:16384
	ds_read_b128 v[60:63], v60 offset:16384
	v_xor_b32_e32 v71, 0xfa40, v22
	s_waitcnt lgkmcnt(10)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[28:31], v[8:11], a[12:15], v23, v7 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v71, 0, v71
	s_mul_hi_i32 s2, s13, 0x1a000
	v_lshlrev_b32_e32 v0, 7, v0
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[52:55], v[8:11], a[8:11], v70, v7 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v7, v71
	ds_read_u8 v3, v3 offset:64512
	ds_read_b128 v[8:11], v16 offset:16384
	v_add_u32_e32 v16, v17, v20
	v_mul_u32_u24_e32 v1, 0xd000, v1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[36:39], v[32:35], a[12:15], v64, v12 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_and_b32_e32 v0, 0x780, v0
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[56:59], v[32:35], a[8:11], v7, v12 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_xor_b32_e32 v12, 0xfe40, v22
	v_add_u32_e32 v12, 0, v12
	ds_read_u8 v12, v12
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[44:47], a[12:15], v65, v13 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v22, v67, v20
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[60:63], v[44:47], a[8:11], v3, v13 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add3_u32 v13, s1, v19, v18
	ds_read_u8 v34, v13
	s_ashr_i32 s1, s13, 31
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[48:51], v[24:27], a[12:15], v66, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_mul_i32 s13, s13, 0x1a000
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[8:11], v[24:27], a[8:11], v12, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[16:19], v16 offset:4096
	ds_read_u8 v5, v13 offset:128
	v_add_u32_e32 v26, v68, v20
	v_add_u32_e32 v20, v69, v20
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[28:31], v[16:19], a[4:7], v23, v34 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[22:25], v22 offset:4096
	ds_read_u8 v35, v13 offset:256
	ds_read_b128 v[26:29], v26 offset:4096
	ds_read_u8 v13, v13 offset:384
	ds_read_b128 v[30:33], v20 offset:4096
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[52:55], v[16:19], a[0:3], v70, v34 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[56:59], v[22:25], a[0:3], v7, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_and_b32_e32 v7, 0x78, v6
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[60:63], v[26:29], a[0:3], v3, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v3, s1
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[22:25], a[4:7], v64, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v5, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s3, s6, s13
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[8:11], v[30:33], a[0:3], v12, v13 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v8, s0, v7
	v_mov_b32_e32 v9, s1
	s_addc_u32 s2, s7, s2
	s_lshl_b64 s[0:1], s[0:1], 1
	s_add_u32 s4, s3, s0
	s_addc_u32 s5, s2, s1
	s_ashr_i32 s13, s12, 31
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[40:43], v[26:29], a[4:7], v65, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v10, v1, v7
	v_cmp_gt_i64_e32 vcc, s[12:13], v[2:3]
	v_and_b32_e32 v1, 12, v14
	v_lshrrev_b32_e32 v2, 3, v0
	v_add_u32_e32 v2, 0, v2
	v_lshlrev_b32_e32 v1, 1, v1
	v_lshlrev_b32_e32 v0, 1, v0
	s_ashr_i32 s15, s14, 31
	v_add3_u32 v0, v2, v1, v0
	v_lshlrev_b32_e32 v1, 1, v15
	v_lshlrev_b32_e32 v2, 1, v21
	v_cmp_gt_i64_e64 s[2:3], s[14:15], v[8:9]
	v_add3_u32 v8, v0, v1, v2
	v_accvgpr_read_b32 v0, a15
	v_accvgpr_read_b32 v1, a14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[48:51], v[30:33], a[4:7], v66, v13 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a13
	v_accvgpr_read_b32 v2, a12
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_accvgpr_read_b32 v2, a11
	v_accvgpr_read_b32 v3, a10
	v_cmp_gt_i64_e64 s[0:1], s[12:13], v[4:5]
	v_cvt_pk_bf16_f32 v3, v3, v2
	v_accvgpr_read_b32 v2, a9
	v_accvgpr_read_b32 v5, a8
	v_and_b32_e32 v4, 0x7f8, v6
	v_cvt_pk_bf16_f32 v2, v5, v2
	ds_write2_b64 v8, v[0:1], v[2:3] offset1:16
	v_lshrrev_b32_e32 v0, 3, v6
	v_lshlrev_b32_e32 v1, 1, v4
	v_accvgpr_read_b32 v4, a7
	v_accvgpr_read_b32 v5, a6
	v_and_b32_e32 v0, 0xf0, v0
	v_cvt_pk_bf16_f32 v5, v5, v4
	v_accvgpr_read_b32 v4, a5
	v_accvgpr_read_b32 v6, a4
	v_add3_u32 v9, 0, v0, v1
	v_cvt_pk_bf16_f32 v4, v6, v4
	v_accvgpr_read_b32 v6, a3
	v_accvgpr_read_b32 v7, a2
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[0:3], v9
	v_cvt_pk_bf16_f32 v7, v7, v6
	v_accvgpr_read_b32 v6, a1
	v_accvgpr_read_b32 v11, a0
	v_cvt_pk_bf16_f32 v6, v11, v6
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v8, v[4:5], v[6:7] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[4:7], v9
	v_lshlrev_b32_e32 v8, 1, v10
	v_bfrev_b32_e32 v9, 1
	s_and_b64 vcc, vcc, s[2:3]
	s_and_b32 s5, s5, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v10, v9, v8, vcc
	buffer_store_dwordx4 v[0:3], v10, s[4:7], 0 offen
	s_and_b64 vcc, s[0:1], s[2:3]
	s_nop 0
	v_add_u32_e32 v0, 0x1a0000, v8
	v_cndmask_b32_e32 v0, v9, v0, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[4:7], v0, s[4:7], 0 offen
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
		.amdhsa_next_free_vgpr 92
		.amdhsa_next_free_sgpr 41
		.amdhsa_accum_offset 76
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
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 73
	.set _gemm_afp4_wfp4_kernel.num_agpr, 16
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 41
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5604
; TotalNumSgprs: 47
; NumVgprs: 73
; NumAgprs: 16
; TotalNumVgprs: 92
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 11
; NumSGPRsForWavesPerEU: 47
; NumVGPRsForWavesPerEU: 92
; AccumOffset: 76
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 18
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
  - .agpr_count:     16
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
    .max_flat_workgroup_size: 256
    .name:           _gemm_afp4_wfp4_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     47
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     92
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
