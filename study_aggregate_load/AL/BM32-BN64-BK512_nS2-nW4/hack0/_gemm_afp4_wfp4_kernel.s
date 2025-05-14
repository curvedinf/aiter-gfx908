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
	s_add_i32 s1, s13, 63
	s_mov_b64 s[20:21], s[10:11]
	s_ashr_i32 s10, s1, 31
	s_lshr_b32 s10, s10, 26
	s_add_i32 s1, s1, s10
	s_mov_b32 s0, s13
	s_ashr_i32 s13, s1, 6
	.file	3 "/app/aiter/aiter/ops/triton/utils" "pid_preprocessing.py"
	s_abs_i32 s1, s13
	v_cvt_f32_u32_e32 v1, s1
	s_sub_i32 s14, 0, s1
	s_abs_i32 s11, s16
	s_xor_b32 s10, s16, s13
	v_rcp_iflag_f32_e32 v1, v1
	s_ashr_i32 s10, s10, 31
	v_lshlrev_b32_e32 v50, 4, v0
	v_and_b32_e32 v18, 0xfe0, v50
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_lshrrev_b32_e32 v52, 4, v0
	v_and_b32_e32 v55, 48, v50
	v_and_b32_e32 v19, 16, v0
	v_readfirstlane_b32 s15, v1
	s_mul_i32 s14, s14, s15
	s_mul_hi_u32 s14, s15, s14
	s_add_i32 s15, s15, s14
	s_mul_hi_u32 s14, s11, s15
	s_mul_i32 s15, s14, s1
	s_sub_i32 s11, s11, s15
	s_add_i32 s15, s14, 1
	s_sub_i32 s17, s11, s1
	s_cmp_ge_u32 s11, s1
	s_cselect_b32 s14, s15, s14
	s_cselect_b32 s11, s17, s11
	s_add_i32 s15, s14, 1
	s_cmp_ge_u32 s11, s1
	s_cselect_b32 s1, s15, s14
	s_abs_i32 s14, s12
	v_cvt_f32_u32_e32 v1, s14
	s_xor_b32 s1, s1, s10
	s_sub_i32 s17, s1, s10
	s_lshl_b32 s1, s17, 5
	v_rcp_iflag_f32_e32 v1, v1
	s_sub_i32 s10, 0, s14
	v_and_or_b32 v2, v50, 16, s1
	s_bfe_i32 s15, s17, 0x1001a
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_add_u32_e32 v2, s15, v2
	v_xor_b32_e32 v2, s15, v2
	s_and_b32 s9, s9, 0xffff
	v_mul_lo_u32 v3, s10, v1
	v_mul_hi_u32 v3, v1, v3
	v_add_u32_e32 v1, v1, v3
	v_mul_hi_u32 v3, v2, v1
	v_mul_lo_u32 v3, v3, s14
	v_sub_u32_e32 v2, v2, v3
	v_subrev_u32_e32 v3, s14, v2
	v_cmp_le_u32_e32 vcc, s14, v2
	s_mov_b32 s11, 0x27000
	s_mov_b32 s10, 0x7ffffffe
	v_cndmask_b32_e32 v2, v2, v3, vcc
	v_subrev_u32_e32 v3, s14, v2
	v_cmp_le_u32_e32 vcc, s14, v2
	v_or_b32_e32 v12, s1, v52
	v_add_u32_e32 v12, s15, v12
	v_cndmask_b32_e32 v2, v2, v3, vcc
	v_xor_b32_e32 v2, s15, v2
	v_subrev_u32_e32 v2, s15, v2
	v_add_u32_e32 v10, v2, v18
	v_add_u32_e32 v11, 0x1000, v10
	buffer_load_dwordx4 v[2:5], v10, s[8:11], 0 offen
	buffer_load_dwordx4 v[6:9], v11, s[8:11], 0 offen
	v_xor_b32_e32 v12, s15, v12
	v_mul_hi_u32 v14, v12, v1
	v_mul_lo_u32 v14, v14, s14
	v_sub_u32_e32 v12, v12, v14
	v_subrev_u32_e32 v14, s14, v12
	v_cmp_le_u32_e32 vcc, s14, v12
	v_or_b32_e32 v11, 16, v52
	v_or_b32_e32 v13, s1, v11
	v_cndmask_b32_e32 v12, v12, v14, vcc
	v_subrev_u32_e32 v14, s14, v12
	v_cmp_le_u32_e32 vcc, s14, v12
	s_mul_i32 s17, s17, s13
	s_sub_i32 s13, s16, s17
	v_cndmask_b32_e32 v53, v12, v14, vcc
	v_add_u32_e32 v12, s15, v13
	v_xor_b32_e32 v12, s15, v12
	v_mul_hi_u32 v1, v12, v1
	v_mul_lo_u32 v1, v1, s14
	v_sub_u32_e32 v1, v12, v1
	v_subrev_u32_e32 v12, s14, v1
	v_cmp_le_u32_e32 vcc, s14, v1
	s_abs_i32 s16, s0
	s_bfe_i32 s17, s13, 0x10019
	v_cndmask_b32_e32 v1, v1, v12, vcc
	v_subrev_u32_e32 v12, s14, v1
	v_cmp_le_u32_e32 vcc, s14, v1
	s_lshl_b32 s14, s13, 6
	s_sub_i32 s13, 0, s16
	v_cndmask_b32_e32 v54, v1, v12, vcc
	v_cvt_f32_u32_e32 v12, s16
	v_or_b32_e32 v13, s14, v52
	v_add_u32_e32 v56, s17, v13
	v_xor_b32_e32 v13, s17, v56
	v_rcp_iflag_f32_e32 v12, v12
	v_or_b32_e32 v11, s14, v11
	v_or_b32_e32 v14, s14, v55
	v_add_u32_e32 v47, s17, v11
	v_mul_f32_e32 v12, 0x4f7ffffe, v12
	v_cvt_u32_f32_e32 v12, v12
	v_add_u32_e32 v11, s17, v14
	v_xor_b32_e32 v11, s17, v11
	v_lshlrev_b32_e32 v1, 3, v0
	v_mul_lo_u32 v15, s13, v12
	v_mul_hi_u32 v15, v12, v15
	v_add_u32_e32 v57, v12, v15
	v_mul_hi_u32 v12, v13, v57
	v_mul_lo_u32 v12, v12, s16
	v_sub_u32_e32 v12, v13, v12
	v_subrev_u32_e32 v13, s16, v12
	v_cmp_le_u32_e32 vcc, s16, v12
	v_add_u32_e32 v20, 0x2000, v10
	v_add_u32_e32 v21, 0x3000, v10
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_subrev_u32_e32 v13, s16, v12
	v_cmp_le_u32_e32 vcc, s16, v12
	s_add_i32 s13, 0, 0x10000
	v_and_b32_e32 v51, 32, v0
	v_cndmask_b32_e32 v58, v12, v13, vcc
	v_mul_hi_u32 v12, v11, v57
	v_mul_lo_u32 v12, v12, s16
	v_sub_u32_e32 v11, v11, v12
	v_subrev_u32_e32 v12, s16, v11
	v_cmp_le_u32_e32 vcc, s16, v11
	v_lshrrev_b32_e32 v60, 2, v0
	s_mov_b32 s18, 0xd000
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_subrev_u32_e32 v12, s16, v11
	v_cmp_le_u32_e32 vcc, s16, v11
	s_and_b32 s21, s21, 0xffff
	s_mov_b32 s22, s10
	v_cndmask_b32_e32 v11, v11, v12, vcc
	v_xor_b32_e32 v11, s17, v11
	v_subrev_u32_e32 v46, s17, v11
	buffer_load_dwordx4 v[10:13], v20, s[8:11], 0 offen
	buffer_load_dwordx4 v[14:17], v21, s[8:11], 0 offen
	v_bitop3_b32 v20, v50, 16, v1 bitop3:0x48
	v_add3_u32 v59, s13, v20, v18
	s_waitcnt vmcnt(3)
	ds_write_b128 v59, v[2:5]
	s_waitcnt vmcnt(2)
	ds_write_b128 v59, v[6:9] offset:4096
	v_bfe_u32 v4, v0, 2, 2
	v_lshrrev_b32_e32 v2, 2, v19
	v_lshrrev_b32_e32 v3, 2, v51
	v_or3_b32 v6, v2, v4, v3
	v_and_b32_e32 v4, 16, v60
	v_and_b32_e32 v5, 32, v60
	v_or3_b32 v61, v6, v4, v5
	v_or_b32_e32 v6, 64, v61
	v_mad_u64_u32 v[6:7], s[8:9], v6, s18, v[46:47]
	s_mov_b32 s23, s11
	v_or_b32_e32 v8, 0x80, v61
	buffer_load_dwordx4 v[18:21], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v8, s18, v[46:47]
	v_or_b32_e32 v9, 0xc0, v61
	buffer_load_dwordx4 v[22:25], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v9, s18, v[46:47]
	v_or_b32_e32 v30, 0x100, v61
	buffer_load_dwordx4 v[26:29], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v30, s18, v[46:47]
	v_or_b32_e32 v34, 0x140, v61
	buffer_load_dwordx4 v[30:33], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v34, s18, v[46:47]
	v_or_b32_e32 v38, 0x180, v61
	buffer_load_dwordx4 v[34:37], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v38, s18, v[46:47]
	v_or_b32_e32 v42, 0x1c0, v61
	buffer_load_dwordx4 v[38:41], v6, s[20:23], 0 offen
	v_mad_u64_u32 v[6:7], s[8:9], v42, s18, v[46:47]
	buffer_load_dwordx4 v[42:45], v6, s[20:23], 0 offen
	v_xor_b32_e32 v6, s17, v47
	v_mul_hi_u32 v7, v6, v57
	v_mul_lo_u32 v7, v7, s16
	v_sub_u32_e32 v6, v6, v7
	v_subrev_u32_e32 v7, s16, v6
	v_cmp_le_u32_e32 vcc, s16, v6
	v_and_b32_e32 v62, 0xf0, v50
	s_movk_i32 s8, 0xf0
	v_cndmask_b32_e32 v6, v6, v7, vcc
	v_subrev_u32_e32 v7, s16, v6
	v_cmp_le_u32_e32 vcc, s16, v6
	s_and_b32 s9, s3, 0xffff
	v_accvgpr_write_b32 a3, 0
	v_cndmask_b32_e32 v6, v6, v7, vcc
	v_add_u32_e32 v7, 32, v56
	v_xor_b32_e32 v7, s17, v7
	v_mul_hi_u32 v8, v7, v57
	v_mul_lo_u32 v8, v8, s16
	v_sub_u32_e32 v7, v7, v8
	v_subrev_u32_e32 v8, s16, v7
	v_cmp_le_u32_e32 vcc, s16, v7
	v_xor_b32_e32 v6, s17, v6
	v_subrev_u32_e32 v6, s17, v6
	v_cndmask_b32_e32 v7, v7, v8, vcc
	v_subrev_u32_e32 v8, s16, v7
	v_cmp_le_u32_e32 vcc, s16, v7
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_cndmask_b32_e32 v7, v7, v8, vcc
	v_mad_u32_u24 v8, v61, s18, v46
	buffer_load_dwordx4 v[46:49], v8, s[20:23], 0 offen
	v_add_u32_e32 v8, 48, v56
	v_xor_b32_e32 v8, s17, v8
	v_mul_hi_u32 v9, v8, v57
	v_mul_lo_u32 v9, v9, s16
	v_sub_u32_e32 v8, v8, v9
	v_subrev_u32_e32 v9, s16, v8
	v_cmp_le_u32_e32 vcc, s16, v8
	v_xor_b32_e32 v7, s17, v7
	v_subrev_u32_e32 v57, s17, v7
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_subrev_u32_e32 v9, s16, v8
	v_cmp_le_u32_e32 vcc, s16, v8
	s_waitcnt vmcnt(8)
	ds_write_b128 v59, v[14:17] offset:12288
	v_lshlrev_b32_e32 v17, 6, v61
	v_cndmask_b32_e32 v8, v8, v9, vcc
	v_xor_b32_e32 v9, s15, v53
	v_subrev_u32_e32 v53, s15, v9
	v_xor_b32_e32 v9, s15, v54
	v_subrev_u32_e32 v54, s15, v9
	v_xor_b32_e32 v9, s17, v58
	v_xor_b32_e32 v7, s17, v8
	v_lshl_or_b32 v8, v6, 13, v62
	v_lshlrev_b32_e32 v6, 2, v0
	v_subrev_u32_e32 v9, s17, v9
	v_bitop3_b32 v6, v6, 48, v50 bitop3:0x48
	v_subrev_u32_e32 v58, s17, v7
	v_lshl_or_b32 v7, v9, 13, v62
	v_lshl_or_b32 v9, v57, 13, v62
	v_add_u32_e32 v57, 0, v6
	v_or_b32_e32 v6, 0x1000, v17
	v_add_u32_e32 v6, v57, v6
	ds_write_b128 v59, v[10:13] offset:8192
	s_waitcnt vmcnt(7)
	ds_write_b128 v6, v[18:21]
	v_or_b32_e32 v6, 0x2000, v17
	v_add_u32_e32 v6, v57, v6
	s_waitcnt vmcnt(6)
	ds_write_b128 v6, v[22:25]
	v_or_b32_e32 v6, 0x3000, v17
	v_add_u32_e32 v6, v57, v6
	s_waitcnt vmcnt(5)
	ds_write_b128 v6, v[26:29]
	v_or_b32_e32 v6, 0x4000, v17
	v_add_u32_e32 v6, v57, v6
	s_waitcnt vmcnt(4)
	ds_write_b128 v6, v[30:33]
	v_or_b32_e32 v6, 0x5000, v17
	v_add_u32_e32 v6, v57, v6
	s_waitcnt vmcnt(3)
	ds_write_b128 v6, v[34:37]
	v_or_b32_e32 v6, 0x6000, v17
	v_add_u32_e32 v6, v57, v6
	s_waitcnt vmcnt(2)
	ds_write_b128 v6, v[38:41]
	v_or_b32_e32 v6, 0x7000, v17
	v_add_u32_e32 v6, v57, v6
	v_and_b32_e32 v20, 48, v0
	s_waitcnt vmcnt(1)
	ds_write_b128 v6, v[42:45]
	v_bitop3_b32 v6, v50, v20, s8 bitop3:0x6c
	v_and_b32_e32 v11, 0xc0, v0
	v_xor_b32_e32 v11, v6, v11
	v_sub_u32_e32 v14, v11, v62
	v_and_b32_e32 v56, 63, v0
	v_ashrrev_i16_e32 v14, 4, v14
	v_lshlrev_b32_e32 v12, 8, v52
	v_add_u32_sdwa v15, v56, sext(v14) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_mov_b32_e32 v16, 4
	v_or_b32_e32 v13, v62, v12
	s_add_i32 s15, 0, 0x14000
	v_lshlrev_b32_sdwa v21, v16, sext(v14) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshrrev_b64 v[14:15], v15, exec
	v_add_u32_e32 v18, s15, v13
	v_add_u32_e32 v22, v21, v62
	v_and_b32_e32 v14, 1, v14
	v_add_u32_e32 v19, 0x1000, v18
	v_lshl_add_u32 v16, v53, 13, v22
	v_bfrev_b32_e32 v15, 1
	v_cmp_eq_u32_e32 vcc, 1, v14
	v_readfirstlane_b32 s16, v18
	s_mov_b32 s8, s2
	v_cndmask_b32_e32 v14, v15, v16, vcc
	s_mov_b32 m0, s16
	v_lshl_add_u32 v18, v54, 13, v22
	v_readfirstlane_b32 s16, v19
	buffer_load_dwordx4 v14, s[8:11], 0 offen lds
	v_cndmask_b32_e32 v14, v15, v18, vcc
	s_mov_b32 m0, s16
	s_add_i32 s22, 0, 0x8000
	buffer_load_dwordx4 v14, s[8:11], 0 offen lds
	v_add_u32_e32 v14, 0, v13
	v_add_u32_e32 v14, 0x8000, v14
	v_add_u32_e32 v19, s22, v13
	v_add_u32_e32 v22, 0x1000, v19
	v_add_u32_e32 v24, v7, v21
	v_readfirstlane_b32 s16, v14
	s_and_b32 s9, s5, 0xffff
	s_mov_b32 s8, s4
	v_cndmask_b32_e32 v24, v15, v24, vcc
	s_mov_b32 m0, s16
	v_add_u32_e32 v14, v8, v21
	v_readfirstlane_b32 s16, v22
	v_add_u32_e32 v23, 0x2000, v19
	buffer_load_dwordx4 v24, s[8:11], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v14, v15, v14, vcc
	s_mov_b32 m0, s16
	v_readfirstlane_b32 s16, v23
	buffer_load_dwordx4 v14, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v14, v9, v21
	v_lshl_or_b32 v10, v58, 13, v62
	v_add_u32_e32 v19, 0x3000, v19
	v_cndmask_b32_e32 v14, v15, v14, vcc
	s_mov_b32 m0, s16
	v_readfirstlane_b32 s16, v19
	buffer_load_dwordx4 v14, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v14, v10, v21
	v_cndmask_b32_e32 v14, v15, v14, vcc
	s_mov_b32 m0, s16
	v_add_u32_e32 v17, v57, v17
	buffer_load_dwordx4 v14, s[8:11], 0 offen sc0 nt lds
	v_bfe_i32 v14, v0, 4, 1
	v_and_b32_e32 v25, 15, v0
	v_bfe_i32 v15, v0, 5, 1
	s_waitcnt vmcnt(0)
	ds_write_b128 v17, v[46:49]
	v_and_b32_e32 v26, 48, v14
	v_lshlrev_b32_e32 v22, 1, v51
	v_or_b32_e32 v17, 16, v25
	v_bitop3_b32 v24, v14, v17, 48 bitop3:0x6c
	v_bitop3_b32 v28, v22, v26, v17 bitop3:0xf6
	v_and_or_b32 v17, v60, 48, v25
	v_and_b32_e32 v14, 0x50, v14
	v_and_b32_e32 v15, 0xa0, v15
	v_and_b32_e32 v19, 0x70, v50
	v_and_b32_e32 v29, 0x80, v50
	v_bitop3_b32 v23, v14, v17, v15 bitop3:0x36
	v_bitop3_b32 v14, v55, v50, 64 bitop3:0x72
	v_bitop3_b32 v21, v14, v20, v29 bitop3:0x36
	v_or_b32_e32 v14, 0x80, v19
	s_add_u32 s4, s4, 0x100
	v_bitop3_b32 v19, v29, v14, v20 bitop3:0x36
	v_or_b32_e32 v14, 0xc0, v55
	v_and_or_b32 v17, v50, 64, v20
	s_addc_u32 s5, s5, 0
	v_or3_b32 v30, v5, v4, v25
	v_bitop3_b32 v17, v17, v14, v29 bitop3:0x36
	v_lshlrev_b32_e32 v14, 8, v0
	s_add_u32 s2, s2, 0x100
	s_mov_b32 s16, 0
	v_or3_b32 v27, v22, v25, v26
	v_lshlrev_b32_e32 v15, 8, v25
	v_and_b32_e32 v14, 0xf00, v14
	v_lshlrev_b32_e32 v20, 8, v30
	s_addc_u32 s3, s3, 0
	v_accvgpr_write_b32 a0, 0
	v_accvgpr_write_b32 a7, 0
	v_accvgpr_write_b32 a6, 0
	v_accvgpr_write_b32 a5, 0
	v_accvgpr_write_b32 a4, 0
	s_mov_b32 s17, 0
	s_mov_b32 s20, 0
	s_mov_b32 s19, 0
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_add_i32 s9, s20, 1
	s_cmp_lt_i32 s9, 2
	s_cselect_b32 s20, s9, 0
	s_mov_b32 s23, s15
	s_lshl_b32 s15, s20, 13
	s_lshl_b32 s18, s20, 14
	s_add_i32 s15, s15, 0
	s_add_i32 s18, s18, 0
	s_add_i32 s15, s15, 0x14000
	s_add_i32 s21, s18, 0x8000
	v_add3_u32 v29, s18, v11, v12
	v_add_u32_e32 v30, s15, v13
	v_add_u32_e32 v32, s21, v13
	v_add_u32_e32 v31, 0x8000, v29
	v_add_u32_e32 v33, 0x1000, v30
	v_readfirstlane_b32 s24, v30
	v_add_u32_e32 v30, 0x1000, v32
	v_sub_u32_e32 v29, v29, v32
	v_add_u32_e32 v34, 0x2000, v32
	v_add_u32_e32 v35, 0x3000, v32
	v_readfirstlane_b32 s25, v32
	v_add_u32_e32 v29, 0x8000, v29
	v_sub_u32_e32 v32, v31, v30
	v_readfirstlane_b32 s26, v33
	v_readfirstlane_b32 s27, v30
	v_sub_u32_e32 v30, v31, v34
	v_ashrrev_i32_e32 v33, 31, v29
	v_add_u32_e32 v32, 0x1000, v32
	v_readfirstlane_b32 s28, v34
	v_sub_u32_e32 v31, v31, v35
	v_add_u32_e32 v30, 0x2000, v30
	v_lshrrev_b32_e32 v33, 28, v33
	v_ashrrev_i32_e32 v34, 31, v32
	s_mov_b32 s8, s2
	s_and_b32 s9, s3, 0xffff
	v_readfirstlane_b32 s29, v35
	s_mov_b32 m0, s24
	v_add_u32_e32 v31, 0x3000, v31
	v_ashrrev_i32_e32 v35, 31, v30
	v_add_u32_e32 v29, v29, v33
	v_lshrrev_b32_e32 v33, 28, v34
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	buffer_load_dwordx4 v16, s[8:11], 0 offen lds
	s_mov_b32 m0, s26
	v_ashrrev_i32_e32 v36, 31, v31
	v_lshrrev_b32_e32 v34, 28, v35
	v_and_b32_e32 v29, -16, v29
	v_add_u32_e32 v32, v32, v33
	buffer_load_dwordx4 v18, s[8:11], 0 offen lds
	s_and_b32 s9, s5, 0xffff
	s_mov_b32 s8, s4
	v_lshrrev_b32_e32 v35, 28, v36
	v_add_u32_e32 v30, v30, v34
	v_add_u32_e32 v29, v29, v7
	v_and_b32_e32 v32, -16, v32
	s_mov_b32 m0, s25
	v_add_u32_e32 v31, v31, v35
	v_and_b32_e32 v30, -16, v30
	buffer_load_dwordx4 v29, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v29, v32, v8
	s_mov_b32 m0, s27
	v_and_b32_e32 v31, -16, v31
	v_add_u32_e32 v30, v30, v9
	buffer_load_dwordx4 v29, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s28
	v_add_u32_e32 v31, v31, v10
	buffer_load_dwordx4 v30, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s29
	s_nop 0
	buffer_load_dwordx4 v31, s[8:11], 0 offen sc0 nt lds
	; sched_barrier mask(0x00000000)
	s_and_b32 s8, s16, 0x200
	s_and_b32 s9, s16, 0x400
	s_and_b32 s24, s16, 0x800
	s_and_b32 s25, s16, 0x1000
	v_add_u32_e32 v29, s23, v6
	v_add_u32_e32 v30, s23, v21
	v_or_b32_e32 v38, s8, v27
	s_cmp_lt_u32 s19, 16
	v_add_u32_e32 v50, s23, v19
	v_add_u32_e32 v51, s23, v17
	v_add3_u32 v31, s22, v6, v20
	v_add3_u32 v34, s22, v21, v20
	v_add3_u32 v52, s22, v19, v20
	v_add3_u32 v53, s22, v17, v20
	v_or_b32_e32 v46, s8, v28
	v_add_u32_e32 v39, v29, v15
	v_add_u32_e32 v42, v30, v15
	v_or_b32_e32 v48, s9, v38
	s_cselect_b32 s8, 0, 0x2000
	s_cselect_b32 s22, 0, 0x4000
	s_and_b32 s23, s16, 0x1800
	s_and_b32 s27, s17, 0x3000
	s_and_b32 s28, s17, 0x1000
	v_add_u32_e32 v47, v30, v14
	ds_read_b128 v[30:33], v31
	ds_read_b128 v[34:37], v34
	v_or_b32_e32 v49, s9, v46
	s_and_b32 s26, s17, 0xc00
	s_and_b32 s29, s17, 0x2000
	ds_read_b128 v[38:41], v39
	ds_read_b128 v[42:45], v42
	v_or_b32_e32 v54, s24, v48
	s_or_b32 s24, s8, s25
	s_or_b32 s25, s23, s8
	v_or_b32_e32 v46, s23, v46
	s_add_i32 s23, s27, 0
	v_or_b32_e32 v55, s28, v23
	s_or_b32 s27, s22, s29
	v_or_b32_e32 v46, s9, v46
	s_add_i32 s23, s23, s26
	v_or_b32_e32 v55, s26, v55
	v_or_b32_e32 v54, s24, v54
	v_or_b32_e32 v48, s25, v48
	v_or_b32_e32 v49, s25, v49
	v_or_b32_e32 v46, s8, v46
	s_add_i32 s22, s22, s23
	v_or_b32_e32 v55, s27, v55
	v_add_u32_e32 v29, v29, v14
	v_add_u32_e32 v54, s13, v54
	v_add_u32_e32 v48, s13, v48
	v_add_u32_e32 v49, s13, v49
	v_add_u32_e32 v46, s13, v46
	v_add_u32_e32 v56, s22, v23
	v_add_u32_e32 v55, 0, v55
	ds_read_u8 v54, v54
	ds_read_u8 v57, v48 offset:128
	ds_read_u8 v58, v48 offset:256
	ds_read_u8 v59, v48 offset:384
	ds_read_u8 v60, v49
	ds_read_u8 v56, v56
	ds_read_u8 v61, v46 offset:128
	ds_read_u8 v62, v46 offset:256
	ds_read_u8 v63, v46 offset:384
	ds_read_u8 v64, v55 offset:256
	ds_read_u8 v65, v55 offset:512
	ds_read_u8 v55, v55 offset:768
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[30:33], v[38:41], a[4:7], v56, v54 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[38:41], v29 offset:4096
	ds_read_b128 v[46:49], v47 offset:4096
	v_add_u32_e32 v29, v50, v15
	v_add_u32_e32 v54, v51, v15
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[30:33], v[38:41], a[0:3], v56, v60 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[30:33], v52
	ds_read_b128 v[38:41], v53
	v_add_u32_e32 v50, v50, v14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[34:37], v[42:45], a[4:7], v64, v57 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v51, v51, v14
	s_add_i32 s19, s19, 1
	s_add_u32 s4, s4, 0x100
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[34:37], v[46:49], a[0:3], v64, v61 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[34:37], v29
	ds_read_b128 v[42:45], v54
	s_addc_u32 s5, s5, 0
	s_add_u32 s2, s2, 0x100
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[30:33], v[34:37], a[4:7], v65, v58 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[34:37], v50 offset:4096
	ds_read_b128 v[46:49], v51 offset:4096
	s_addc_u32 s3, s3, 0
	s_addk_i32 s17, 0x400
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[30:33], v[34:37], a[0:3], v65, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addk_i32 s16, 0x200
	s_cmp_lg_u32 s19, 31
	s_mov_b32 s22, s21
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[38:41], v[42:45], a[4:7], v55, v59 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[38:41], v[46:49], a[0:3], v55, v63 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_1
; %bb.2:
	s_add_i32 s2, 0, 0x13e00
	v_add_u32_e32 v7, s2, v25
	v_add3_u32 v7, v7, v26, v22
	v_add_u32_e32 v45, s15, v6
	v_add_u32_e32 v46, s15, v21
	s_waitcnt vmcnt(0)
	s_barrier
	v_add3_u32 v8, s2, v24, v22
	ds_read_u8 v16, v7
	ds_read_u8 v34, v7 offset:128
	ds_read_u8 v35, v7 offset:256
	ds_read_u8 v36, v7 offset:384
	ds_read_u8 v37, v8
	ds_read_u8 v38, v8 offset:128
	ds_read_u8 v39, v8 offset:256
	ds_read_u8 v40, v8 offset:384
	v_add_u32_e32 v7, 0, v23
	v_add_u32_e32 v10, v45, v15
	v_add_u32_e32 v18, v46, v15
	v_add3_u32 v6, s18, v6, v20
	ds_read_u8 v41, v7 offset:31744
	ds_read_u8 v42, v7 offset:32000
	ds_read_u8 v43, v7 offset:32256
	ds_read_u8 v44, v7 offset:32512
	ds_read_b128 v[6:9], v6 offset:32768
	ds_read_b128 v[10:13], v10
	ds_read_b128 v[22:25], v18
	v_add3_u32 v18, s18, v21, v20
	ds_read_b128 v[26:29], v18 offset:32768
	v_add_u32_e32 v47, s15, v19
	v_add3_u32 v19, s18, v19, v20
	ds_read_b128 v[30:33], v19 offset:32768
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[6:9], v[10:13], a[4:7], v41, v16 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v18, v47, v15
	v_add3_u32 v10, s18, v17, v20
	ds_read_b128 v[10:13], v10 offset:32768
	ds_read_b128 v[18:21], v18
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[26:29], v[22:25], a[4:7], v42, v34 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v34, s15, v17
	v_add_u32_e32 v15, v34, v15
	ds_read_b128 v[22:25], v15
	v_add_u32_e32 v15, v45, v14
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[30:33], v[18:21], a[4:7], v43, v35 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[16:19], v15 offset:4096
	v_add_u32_e32 v15, v46, v14
	s_ashr_i32 s2, s1, 31
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[10:13], v[22:25], a[4:7], v44, v36 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[20:23], v15 offset:4096
	s_ashr_i32 s15, s14, 31
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[6:9], v[16:19], a[0:3], v41, v37 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v6, v47, v14
	ds_read_b128 v[6:9], v6 offset:4096
	v_add_u32_e32 v14, v34, v14
	ds_read_b128 v[14:17], v14 offset:4096
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[26:29], v[20:23], a[0:3], v42, v38 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_lshrrev_b32_e32 v19, 3, v0
	s_waitcnt lgkmcnt(0)
	s_barrier
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[30:33], v[6:9], a[0:3], v43, v39 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v6, s1, v19
	v_mov_b32_e32 v7, s2
	s_mul_hi_i32 s2, s1, 0x1a000
	s_mul_i32 s1, s1, 0x1a000
	s_add_u32 s1, s6, s1
	s_addc_u32 s5, s7, s2
	s_lshl_b64 s[2:3], s[14:15], 1
	s_add_u32 s4, s1, s2
	s_addc_u32 s2, s5, s3
	s_ashr_i32 s13, s12, 31
	v_cmp_gt_i64_e32 vcc, s[12:13], v[6:7]
	v_lshlrev_b32_e32 v6, 6, v0
	v_and_b32_e32 v6, 0x3c0, v6
	v_or3_b32 v2, v6, v2, v3
	v_or3_b32 v4, v2, v4, v5
	v_lshrrev_b32_e32 v2, 2, v6
	v_lshlrev_b32_e32 v3, 1, v4
	v_add3_u32 v5, 0, v2, v3
	v_accvgpr_read_b32 v2, a7
	v_accvgpr_read_b32 v3, a6
	v_cvt_pk_bf16_f32 v3, v3, v2
	v_accvgpr_read_b32 v2, a5
	v_accvgpr_read_b32 v6, a4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[10:13], v[14:17], a[0:3], v44, v40 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v2, v6, v2
	ds_write_b64 v5, v[2:3]
	v_or_b32_e32 v2, 0x400, v4
	v_lshrrev_b32_e32 v3, 2, v2
	v_and_b32_e32 v3, 0x3ffffff0, v3
	v_lshlrev_b32_e32 v2, 1, v2
	v_and_b32_e32 v18, 56, v1
	v_and_b32_e32 v1, 0x7f8, v1
	v_add3_u32 v4, 0, v3, v2
	v_accvgpr_read_b32 v2, a3
	v_accvgpr_read_b32 v3, a2
	v_and_b32_e32 v0, 0xf8, v0
	v_cvt_pk_bf16_f32 v3, v3, v2
	v_accvgpr_read_b32 v2, a1
	v_accvgpr_read_b32 v5, a0
	v_lshlrev_b32_e32 v0, 1, v0
	v_lshlrev_b32_e32 v1, 1, v1
	v_cvt_pk_bf16_f32 v2, v5, v2
	v_add3_u32 v0, 0, v0, v1
	ds_write_b64 v4, v[2:3]
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[0:3], v0
	v_or_b32_e32 v8, s14, v18
	v_mov_b32_e32 v9, s15
	v_mul_u32_u24_e32 v10, 0xd000, v19
	s_ashr_i32 s1, s0, 31
	v_or_b32_e32 v10, v10, v18
	v_cmp_gt_i64_e64 s[0:1], s[0:1], v[8:9]
	v_lshlrev_b32_e32 v4, 1, v10
	v_bfrev_b32_e32 v5, 1
	s_and_b64 vcc, vcc, s[0:1]
	s_and_b32 s5, s2, 0xffff
	s_mov_b32 s7, 0x27000
	s_mov_b32 s6, 0x7ffffffe
	v_cndmask_b32_e32 v4, v5, v4, vcc
	s_waitcnt lgkmcnt(0)
	buffer_store_dwordx4 v[0:3], v4, s[4:7], 0 offen
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
		.amdhsa_next_free_vgpr 76
		.amdhsa_next_free_sgpr 30
		.amdhsa_accum_offset 68
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
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 66
	.set _gemm_afp4_wfp4_kernel.num_agpr, 8
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 30
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4232
; TotalNumSgprs: 36
; NumVgprs: 66
; NumAgprs: 8
; TotalNumVgprs: 76
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 4
; VGPRBlocks: 9
; NumSGPRsForWavesPerEU: 36
; NumVGPRsForWavesPerEU: 76
; AccumOffset: 68
; Occupancy: 6
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 16
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
  - .agpr_count:     8
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
    .sgpr_count:     36
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     76
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
