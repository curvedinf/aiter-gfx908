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
	s_mov_b64 s[20:21], s[10:11]
	.file	3 "/app/aiter/aiter/ops/triton/utils" "pid_preprocessing.py"
	s_abs_i32 s10, s0
	v_cvt_f32_u32_e32 v1, s10
	s_sub_i32 s15, 0, s10
	s_mov_b32 s14, s13
	s_abs_i32 s13, s16
	v_rcp_iflag_f32_e32 v1, v1
	s_xor_b32 s1, s16, s0
	s_ashr_i32 s11, s1, 31
	v_lshlrev_b32_e32 v22, 4, v0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_and_b32_e32 v16, 0xfe0, v22
	v_and_b32_e32 v56, 0x70, v22
	v_lshrrev_b32_e32 v57, 3, v0
	v_readfirstlane_b32 s17, v1
	s_mul_i32 s15, s15, s17
	s_mul_hi_u32 s15, s17, s15
	s_add_i32 s17, s17, s15
	s_mul_hi_u32 s15, s13, s17
	s_mul_i32 s17, s15, s10
	s_sub_i32 s13, s13, s17
	s_add_i32 s17, s15, 1
	s_sub_i32 s18, s13, s10
	s_cmp_ge_u32 s13, s10
	s_cselect_b32 s15, s17, s15
	s_cselect_b32 s13, s18, s13
	s_add_i32 s17, s15, 1
	s_cmp_ge_u32 s13, s10
	s_cselect_b32 s10, s17, s15
	s_xor_b32 s10, s10, s11
	s_sub_i32 s10, s10, s11
	s_mul_i32 s0, s10, s0
	s_sub_i32 s15, s16, s0
	s_abs_i32 s0, s12
	v_cvt_f32_u32_e32 v2, s0
	s_lshl_b32 s13, s10, 5
	s_bfe_i32 s16, s10, 0x1001a
	s_sub_i32 s10, 0, s0
	v_rcp_iflag_f32_e32 v5, v2
	v_and_or_b32 v6, v22, 16, s13
	v_add_u32_e32 v6, s16, v6
	v_xor_b32_e32 v6, s16, v6
	v_mul_f32_e32 v5, 0x4f7ffffe, v5
	v_cvt_u32_f32_e32 v5, v5
	s_and_b32 s9, s9, 0xffff
	s_or_b32 s9, s9, 0x60000000
	s_mov_b32 s11, 0x27000
	v_mul_lo_u32 v8, s10, v5
	v_mul_hi_u32 v8, v5, v8
	v_add_u32_e32 v5, v5, v8
	v_mul_hi_u32 v8, v6, v5
	v_mul_lo_u32 v8, v8, s0
	v_sub_u32_e32 v6, v6, v8
	v_subrev_u32_e32 v8, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	s_mov_b32 s10, 0x7ffffffe
	v_lshrrev_b32_e32 v1, 4, v0
	v_cndmask_b32_e32 v6, v6, v8, vcc
	v_subrev_u32_e32 v8, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_or_b32_e32 v4, s13, v1
	v_or_b32_e32 v3, 16, v1
	v_cndmask_b32_e32 v6, v6, v8, vcc
	v_xor_b32_e32 v6, s16, v6
	v_subrev_u32_e32 v6, s16, v6
	v_add_u32_e32 v18, v6, v16
	buffer_load_dwordx4 v[8:11], v18, s[8:11], 0 offen
	v_add_u32_e32 v12, 0x1000, v18
	buffer_load_dwordx4 v[12:15], v12, s[8:11], 0 offen
	v_add_u32_e32 v6, s16, v4
	v_xor_b32_e32 v6, s16, v6
	v_mul_hi_u32 v20, v6, v5
	v_mul_lo_u32 v20, v20, s0
	v_sub_u32_e32 v6, v6, v20
	v_subrev_u32_e32 v20, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	s_abs_i32 s17, s14
	v_or_b32_e32 v2, s13, v3
	v_cndmask_b32_e32 v6, v6, v20, vcc
	v_subrev_u32_e32 v20, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_cvt_f32_u32_e32 v21, s17
	s_bfe_i32 s18, s15, 0x10018
	v_cndmask_b32_e32 v20, v6, v20, vcc
	v_add_u32_e32 v6, s16, v2
	v_xor_b32_e32 v6, s16, v6
	v_mul_hi_u32 v5, v6, v5
	v_mul_lo_u32 v5, v5, s0
	v_rcp_iflag_f32_e32 v21, v21
	v_sub_u32_e32 v5, v6, v5
	v_subrev_u32_e32 v6, s0, v5
	v_cmp_le_u32_e32 vcc, s0, v5
	v_mul_f32_e32 v21, 0x4f7ffffe, v21
	v_cvt_u32_f32_e32 v21, v21
	v_cndmask_b32_e32 v5, v5, v6, vcc
	v_add_u32_e32 v6, 0x2000, v18
	buffer_load_dwordx4 v[24:27], v6, s[8:11], 0 offen
	v_subrev_u32_e32 v6, s0, v5
	v_cmp_le_u32_e32 vcc, s0, v5
	s_lshl_b32 s0, s15, 7
	s_sub_i32 s15, 0, s17
	v_or_b32_e32 v28, s0, v56
	v_mul_lo_u32 v29, s15, v21
	v_mul_hi_u32 v29, v21, v29
	v_add_u32_e32 v28, s18, v28
	v_add_u32_e32 v21, v21, v29
	v_xor_b32_e32 v28, s18, v28
	v_mul_hi_u32 v29, v28, v21
	v_mul_lo_u32 v29, v29, s17
	v_sub_u32_e32 v28, v28, v29
	v_cndmask_b32_e32 v5, v5, v6, vcc
	v_subrev_u32_e32 v29, s17, v28
	v_cmp_le_u32_e32 vcc, s17, v28
	v_add_u32_e32 v18, 0x3000, v18
	v_lshlrev_b32_e32 v6, 3, v0
	v_cndmask_b32_e32 v28, v28, v29, vcc
	v_subrev_u32_e32 v29, s17, v28
	v_cmp_le_u32_e32 vcc, s17, v28
	s_mov_b32 s22, s10
	s_mov_b32 s23, s11
	v_cndmask_b32_e32 v32, v28, v29, vcc
	buffer_load_dwordx4 v[28:31], v18, s[8:11], 0 offen
	v_xor_b32_e32 v18, s18, v32
	v_subrev_u32_e32 v18, s18, v18
	s_mov_b32 s8, 0xd000
	v_mad_u32_u24 v18, v57, s8, v18
	s_and_b32 s8, s21, 0xffff
	s_or_b32 s21, s8, 0x60000000
	v_bitop3_b32 v44, v22, 16, v6 bitop3:0x48
	s_add_i32 s15, 0, 0x20000
	v_add_u32_e32 v45, 0x1a0000, v18
	buffer_load_dwordx4 v[32:35], v18, s[20:23], 0 offen
	v_add_u32_e32 v46, 0x340000, v18
	buffer_load_dwordx4 v[36:39], v45, s[20:23], 0 offen
	buffer_load_dwordx4 v[40:43], v46, s[20:23], 0 offen
	v_add3_u32 v16, s15, v44, v16
	v_add_u32_e32 v44, 0x4e0000, v18
	buffer_load_dwordx4 v[44:47], v44, s[20:23], 0 offen
	v_add_u32_e32 v58, 0x680000, v18
	v_add_u32_e32 v59, 0x820000, v18
	buffer_load_dwordx4 v[48:51], v58, s[20:23], 0 offen
	buffer_load_dwordx4 v[52:55], v59, s[20:23], 0 offen
	v_or_b32_e32 v23, s0, v1
	v_add_u32_e32 v23, s18, v23
	v_or_b32_e32 v3, s0, v3
	v_add_u32_e32 v3, s18, v3
	v_xor_b32_e32 v3, s18, v3
	s_movk_i32 s8, 0x70
	s_waitcnt vmcnt(9)
	ds_write_b128 v16, v[8:11]
	v_add_u32_e32 v8, 0x9c0000, v18
	buffer_load_dwordx4 v[8:11], v8, s[20:23], 0 offen
	s_waitcnt vmcnt(9)
	ds_write_b128 v16, v[12:15] offset:4096
	v_xor_b32_e32 v12, s18, v23
	v_mul_hi_u32 v13, v12, v21
	v_mul_lo_u32 v13, v13, s17
	v_sub_u32_e32 v12, v12, v13
	v_subrev_u32_e32 v13, s17, v12
	v_cmp_le_u32_e32 vcc, s17, v12
	v_add_u32_e32 v63, 0xea0000, v18
	v_add_u32_e32 v64, 0x1040000, v18
	v_cndmask_b32_e32 v12, v12, v13, vcc
	v_subrev_u32_e32 v13, s17, v12
	v_cmp_le_u32_e32 vcc, s17, v12
	v_add_u32_e32 v65, 0x11e0000, v18
	v_add_u32_e32 v66, 0x1380000, v18
	v_cndmask_b32_e32 v58, v12, v13, vcc
	v_mul_hi_u32 v12, v3, v21
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v3, v3, v12
	v_subrev_u32_e32 v12, s17, v3
	v_cmp_le_u32_e32 vcc, s17, v3
	v_add_u32_e32 v67, 0x1520000, v18
	v_add_u32_e32 v68, 0x16c0000, v18
	v_cndmask_b32_e32 v3, v3, v12, vcc
	v_add_u32_e32 v12, 0xb60000, v18
	buffer_load_dwordx4 v[12:15], v12, s[20:23], 0 offen
	v_subrev_u32_e32 v59, s17, v3
	v_cmp_le_u32_e32 vcc, s17, v3
	s_waitcnt vmcnt(9)
	ds_write_b128 v16, v[24:27] offset:8192
	v_add_u32_e32 v24, 32, v23
	v_xor_b32_e32 v24, s18, v24
	v_mul_hi_u32 v25, v24, v21
	v_mul_lo_u32 v25, v25, s17
	v_sub_u32_e32 v24, v24, v25
	v_cndmask_b32_e32 v3, v3, v59, vcc
	v_subrev_u32_e32 v25, s17, v24
	v_cmp_le_u32_e32 vcc, s17, v24
	v_xor_b32_e32 v5, s16, v5
	v_subrev_u32_e32 v62, s16, v5
	v_cndmask_b32_e32 v24, v24, v25, vcc
	v_subrev_u32_e32 v25, s17, v24
	v_cmp_le_u32_e32 vcc, s17, v24
	v_add_u32_e32 v5, 64, v23
	v_xor_b32_e32 v5, s18, v5
	v_cndmask_b32_e32 v59, v24, v25, vcc
	v_add_u32_e32 v24, 48, v23
	v_xor_b32_e32 v24, s18, v24
	v_mul_hi_u32 v25, v24, v21
	v_mul_lo_u32 v25, v25, s17
	v_sub_u32_e32 v24, v24, v25
	v_subrev_u32_e32 v25, s17, v24
	v_cmp_le_u32_e32 vcc, s17, v24
	v_xor_b32_e32 v3, s18, v3
	s_waitcnt vmcnt(8)
	ds_write_b128 v16, v[28:31] offset:12288
	v_cndmask_b32_e32 v24, v24, v25, vcc
	v_subrev_u32_e32 v25, s17, v24
	v_cmp_le_u32_e32 vcc, s17, v24
	v_add_u32_e32 v16, 0xd00000, v18
	v_add_u32_e32 v18, 0x1860000, v18
	v_cndmask_b32_e32 v60, v24, v25, vcc
	v_lshlrev_b32_e32 v24, 1, v0
	v_bitop3_b32 v24, v22, s8, v24 bitop3:0x48
	v_lshlrev_b32_e32 v25, 7, v57
	v_add3_u32 v57, 0, v24, v25
	s_waitcnt vmcnt(7)
	ds_write_b128 v57, v[32:35]
	s_waitcnt vmcnt(6)
	ds_write_b128 v57, v[36:39] offset:4096
	s_waitcnt vmcnt(5)
	ds_write_b128 v57, v[40:43] offset:8192
	buffer_load_dwordx4 v[24:27], v16, s[20:23], 0 offen
	buffer_load_dwordx4 v[28:31], v63, s[20:23], 0 offen
	v_xor_b32_e32 v20, s16, v20
	s_waitcnt vmcnt(6)
	ds_write_b128 v57, v[44:47] offset:12288
	buffer_load_dwordx4 v[32:35], v64, s[20:23], 0 offen
	buffer_load_dwordx4 v[36:39], v65, s[20:23], 0 offen
	s_waitcnt vmcnt(7)
	ds_write_b128 v57, v[48:51] offset:16384
	s_waitcnt vmcnt(6)
	ds_write_b128 v57, v[52:55] offset:20480
	buffer_load_dwordx4 v[40:43], v66, s[20:23], 0 offen
	buffer_load_dwordx4 v[44:47], v67, s[20:23], 0 offen
	v_subrev_u32_e32 v3, s18, v3
	s_mov_b32 s1, 0
	v_and_b32_e32 v19, 63, v0
	v_bfe_i32 v17, v0, 4, 1
	v_and_b32_e32 v7, 32, v0
	v_subrev_u32_e32 v20, s16, v20
	v_bfe_i32 v61, v0, 5, 1
	s_waitcnt vmcnt(7)
	ds_write_b128 v57, v[8:11] offset:24576
	buffer_load_dwordx4 v[48:51], v68, s[20:23], 0 offen
	buffer_load_dwordx4 v[52:55], v18, s[20:23], 0 offen
	v_mul_hi_u32 v8, v5, v21
	v_mul_lo_u32 v8, v8, s17
	v_sub_u32_e32 v5, v5, v8
	v_subrev_u32_e32 v8, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	v_xor_b32_e32 v9, s18, v59
	v_xor_b32_e32 v10, s18, v60
	v_cndmask_b32_e32 v5, v5, v8, vcc
	v_subrev_u32_e32 v8, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	v_subrev_u32_e32 v9, s18, v9
	v_subrev_u32_e32 v10, s18, v10
	v_cndmask_b32_e32 v5, v5, v8, vcc
	v_xor_b32_e32 v5, s18, v5
	v_subrev_u32_e32 v11, s18, v5
	v_add_u32_e32 v5, 0x50, v23
	v_xor_b32_e32 v5, s18, v5
	v_xor_b32_e32 v8, s18, v58
	v_subrev_u32_e32 v8, s18, v8
	v_and_b32_e32 v63, 48, v22
	v_and_b32_e32 v58, 0x80, v22
	s_movk_i32 s8, 0xf0
	s_waitcnt vmcnt(8)
	ds_write_b128 v57, v[12:15] offset:28672
	v_mul_hi_u32 v12, v5, v21
	v_mul_lo_u32 v12, v12, s17
	v_sub_u32_e32 v5, v5, v12
	v_subrev_u32_e32 v12, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	s_waitcnt vmcnt(7)
	ds_write_b128 v57, v[24:27] offset:32768
	s_waitcnt vmcnt(6)
	ds_write_b128 v57, v[28:31] offset:36864
	s_waitcnt vmcnt(5)
	ds_write_b128 v57, v[32:35] offset:40960
	s_waitcnt vmcnt(4)
	ds_write_b128 v57, v[36:39] offset:45056
	s_waitcnt vmcnt(3)
	ds_write_b128 v57, v[40:43] offset:49152
	s_waitcnt vmcnt(2)
	ds_write_b128 v57, v[44:47] offset:53248
	s_waitcnt vmcnt(1)
	ds_write_b128 v57, v[48:51] offset:57344
	s_waitcnt vmcnt(0)
	ds_write_b128 v57, v[52:55] offset:61440
	v_cndmask_b32_e32 v5, v5, v12, vcc
	v_subrev_u32_e32 v12, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	s_nop 1
	v_cndmask_b32_e32 v5, v5, v12, vcc
	v_xor_b32_e32 v5, s18, v5
	v_subrev_u32_e32 v12, s18, v5
	v_add_u32_e32 v5, 0x60, v23
	v_xor_b32_e32 v5, s18, v5
	v_mul_hi_u32 v13, v5, v21
	v_mul_lo_u32 v13, v13, s17
	v_sub_u32_e32 v5, v5, v13
	v_subrev_u32_e32 v13, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	s_nop 1
	v_cndmask_b32_e32 v5, v5, v13, vcc
	v_subrev_u32_e32 v13, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	s_nop 1
	v_cndmask_b32_e32 v5, v5, v13, vcc
	v_xor_b32_e32 v5, s18, v5
	v_subrev_u32_e32 v13, s18, v5
	v_add_u32_e32 v5, 0x70, v23
	v_xor_b32_e32 v5, s18, v5
	v_mul_hi_u32 v14, v5, v21
	v_mul_lo_u32 v14, v14, s17
	v_sub_u32_e32 v5, v5, v14
	v_subrev_u32_e32 v14, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	v_and_b32_e32 v21, 0xf0, v22
	v_lshl_or_b32 v9, v9, 13, v21
	v_cndmask_b32_e32 v5, v5, v14, vcc
	v_subrev_u32_e32 v14, s17, v5
	v_cmp_le_u32_e32 vcc, s17, v5
	v_lshl_or_b32 v10, v10, 13, v21
	v_lshl_or_b32 v11, v11, 13, v21
	v_cndmask_b32_e32 v5, v5, v14, vcc
	v_xor_b32_e32 v5, s18, v5
	v_subrev_u32_e32 v14, s18, v5
	v_lshl_or_b32 v5, v8, 13, v21
	v_lshl_or_b32 v8, v3, 13, v21
	v_lshl_or_b32 v12, v12, 13, v21
	v_lshl_or_b32 v13, v13, 13, v21
	v_lshl_or_b32 v14, v14, 13, v21
	; sched_barrier mask(0x00000000)
	v_and_b32_e32 v34, 48, v0
	v_bitop3_b32 v3, v22, v34, s8 bitop3:0x6c
	v_and_b32_e32 v15, 0xc0, v0
	v_xor_b32_e32 v15, v3, v15
	v_sub_u32_e32 v24, v15, v21
	v_ashrrev_i16_e32 v24, 4, v24
	v_lshlrev_b32_e32 v16, 8, v1
	v_add_u32_sdwa v19, v19, sext(v24) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_mov_b32_e32 v25, 4
	v_or_b32_e32 v18, v21, v16
	s_add_i32 s16, 0, 0x24000
	v_lshlrev_b32_sdwa v27, v25, sext(v24) dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:WORD_0
	v_lshrrev_b64 v[24:25], v19, exec
	v_add_u32_e32 v23, s16, v18
	v_add_u32_e32 v21, v27, v21
	v_and_b32_e32 v19, 1, v24
	v_add_u32_e32 v26, 0x1000, v23
	s_and_b32 s8, s3, 0xffff
	v_lshl_add_u32 v20, v20, 13, v21
	v_bfrev_b32_e32 v24, 1
	v_cmp_eq_u32_e32 vcc, 1, v19
	v_readfirstlane_b32 s17, v23
	s_or_b32 s9, s8, 0x60000000
	s_mov_b32 s8, s2
	v_cndmask_b32_e32 v19, v24, v20, vcc
	s_mov_b32 m0, s17
	v_lshl_add_u32 v23, v62, 13, v21
	v_readfirstlane_b32 s17, v26
	buffer_load_dwordx4 v19, s[8:11], 0 offen lds
	v_cndmask_b32_e32 v19, v24, v23, vcc
	s_mov_b32 m0, s17
	s_add_i32 s17, 0, 0x10000
	buffer_load_dwordx4 v19, s[8:11], 0 offen lds
	v_add_u32_e32 v19, s17, v18
	v_add_u32_e32 v21, 0x1000, v19
	s_and_b32 s8, s5, 0xffff
	v_add_u32_e32 v32, v5, v27
	v_readfirstlane_b32 s18, v19
	v_add_u32_e32 v25, 0x2000, v19
	v_add_u32_e32 v26, 0x3000, v19
	v_add_u32_e32 v28, 0x4000, v19
	v_add_u32_e32 v29, 0x5000, v19
	v_add_u32_e32 v30, 0x6000, v19
	v_add_u32_e32 v31, 0x7000, v19
	s_or_b32 s9, s8, 0x60000000
	s_mov_b32 s8, s4
	v_cndmask_b32_e32 v32, v24, v32, vcc
	s_mov_b32 m0, s18
	v_add_u32_e32 v19, v8, v27
	v_readfirstlane_b32 s18, v21
	buffer_load_dwordx4 v32, s[8:11], 0 offen sc0 nt lds
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v25
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v9, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v26
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v10, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v28
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v11, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v29
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v12, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v30
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v13, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_readfirstlane_b32 s18, v31
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_add_u32_e32 v19, v14, v27
	v_cndmask_b32_e32 v19, v24, v19, vcc
	s_mov_b32 m0, s18
	v_and_b32_e32 v26, 15, v0
	buffer_load_dwordx4 v19, s[8:11], 0 offen sc0 nt lds
	v_and_b32_e32 v30, 48, v17
	v_lshlrev_b32_e32 v28, 1, v7
	v_or_b32_e32 v7, 16, v26
	v_bitop3_b32 v29, v17, v7, 48 bitop3:0x6c
	v_bitop3_b32 v32, v28, v30, v7 bitop3:0xf6
	v_lshrrev_b32_e32 v7, 2, v0
	v_and_or_b32 v35, v7, 48, v26
	v_and_b32_e32 v17, 0x90, v17
	v_and_b32_e32 v19, 0x120, v61
	v_or_b32_e32 v24, 64, v35
	v_or_b32_e32 v21, v19, v17
	v_bitop3_b32 v27, v19, v35, v17 bitop3:0x36
	v_bitop3_b32 v19, v19, v24, v17 bitop3:0x36
	v_bitop3_b32 v17, v63, v22, 64 bitop3:0x72
	s_movk_i32 s8, 0x400
	v_bitop3_b32 v25, v17, v34, v58 bitop3:0x36
	v_or_b32_e32 v17, 0x80, v56
	s_add_u32 s4, s4, 0x100
	v_bitop3_b32 v33, v21, s8, v24 bitop3:0xde
	v_bitop3_b32 v24, v58, v17, v34 bitop3:0x36
	v_or_b32_e32 v17, 0xc0, v63
	v_and_or_b32 v22, v22, 64, v34
	s_addc_u32 s5, s5, 0
	v_bitop3_b32 v22, v22, v17, v58 bitop3:0x36
	v_lshlrev_b32_e32 v17, 8, v0
	s_add_u32 s2, s2, 0x100
	v_or3_b32 v31, v28, v26, v30
	v_lshlrev_b32_e32 v21, 8, v26
	v_and_b32_e32 v17, 0xf00, v17
	v_lshlrev_b32_e32 v34, 8, v35
	s_addc_u32 s3, s3, 0
	v_accvgpr_write_b32 a11, 0
	v_accvgpr_write_b32 a10, 0
	v_accvgpr_write_b32 a9, 0
	v_accvgpr_write_b32 a8, 0
	v_accvgpr_write_b32 a3, 0
	v_accvgpr_write_b32 a2, 0
	v_accvgpr_write_b32 a1, 0
	v_accvgpr_write_b32 a0, 0
	v_accvgpr_write_b32 a15, 0
	v_accvgpr_write_b32 a14, 0
	v_accvgpr_write_b32 a13, 0
	v_accvgpr_write_b32 a12, 0
	v_accvgpr_write_b32 a7, 0
	v_accvgpr_write_b32 a6, 0
	v_accvgpr_write_b32 a5, 0
	v_accvgpr_write_b32 a4, 0
	s_movk_i32 s18, 0x240
	s_movk_i32 s19, 0x640
	s_mov_b32 s20, 0
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	s_add_i32 s1, s1, 1
	s_cmp_lt_i32 s1, 2
	s_cselect_b32 s1, s1, 0
	s_mov_b32 s22, s16
	s_mov_b32 s21, s17
	s_lshl_b32 s16, s1, 13
	s_lshl_b32 s17, s1, 15
	s_add_i32 s16, s16, 0
	s_add_i32 s17, s17, 0
	s_add_i32 s16, s16, 0x24000
	s_add_i32 s17, s17, 0x10000
	v_add_u32_e32 v35, s16, v18
	v_add3_u32 v36, s17, v15, v16
	v_add_u32_e32 v37, s17, v18
	v_add_u32_e32 v38, 0x1000, v35
	v_readfirstlane_b32 s24, v35
	v_add_u32_e32 v35, 0x1000, v37
	v_sub_u32_e32 v45, v36, v37
	v_add_u32_e32 v39, 0x2000, v37
	v_add_u32_e32 v40, 0x3000, v37
	v_add_u32_e32 v41, 0x4000, v37
	v_add_u32_e32 v42, 0x5000, v37
	v_add_u32_e32 v43, 0x6000, v37
	v_add_u32_e32 v44, 0x7000, v37
	v_readfirstlane_b32 s25, v37
	v_readfirstlane_b32 s26, v38
	v_ashrrev_i32_e32 v37, 31, v45
	v_sub_u32_e32 v38, v36, v35
	s_and_b32 s9, s3, 0xffff
	v_readfirstlane_b32 s27, v35
	v_sub_u32_e32 v35, v36, v39
	v_lshrrev_b32_e32 v37, 28, v37
	v_add_u32_e32 v38, 0x1000, v38
	s_mov_b32 s8, s2
	s_or_b32 s9, s9, 0x60000000
	v_readfirstlane_b32 s28, v39
	v_sub_u32_e32 v39, v36, v40
	v_readfirstlane_b32 s29, v40
	v_sub_u32_e32 v40, v36, v41
	v_readfirstlane_b32 s30, v41
	v_sub_u32_e32 v41, v36, v42
	v_readfirstlane_b32 s31, v42
	v_sub_u32_e32 v42, v36, v43
	v_readfirstlane_b32 s33, v43
	s_mov_b32 m0, s24
	v_add_u32_e32 v35, 0x2000, v35
	v_add_u32_e32 v37, v45, v37
	v_ashrrev_i32_e32 v43, 31, v38
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	s_and_b32 s23, s5, 0xffff
	v_sub_u32_e32 v36, v36, v44
	v_readfirstlane_b32 s34, v44
	buffer_load_dwordx4 v20, s[8:11], 0 offen lds
	v_add_u32_e32 v39, 0x3000, v39
	s_mov_b32 m0, s26
	v_ashrrev_i32_e32 v44, 31, v35
	v_and_b32_e32 v37, -16, v37
	v_lshrrev_b32_e32 v43, 28, v43
	v_add_u32_e32 v40, 0x4000, v40
	buffer_load_dwordx4 v23, s[8:11], 0 offen lds
	s_or_b32 s9, s23, 0x60000000
	s_mov_b32 s8, s4
	v_ashrrev_i32_e32 v45, 31, v39
	v_lshrrev_b32_e32 v44, 28, v44
	v_add_u32_e32 v37, v37, v5
	v_add_u32_e32 v38, v38, v43
	s_mov_b32 m0, s25
	v_add_u32_e32 v41, 0x5000, v41
	v_ashrrev_i32_e32 v46, 31, v40
	v_lshrrev_b32_e32 v45, 28, v45
	v_add_u32_e32 v35, v35, v44
	buffer_load_dwordx4 v37, s[8:11], 0 offen sc0 nt lds
	v_and_b32_e32 v37, -16, v38
	v_add_u32_e32 v42, 0x6000, v42
	v_ashrrev_i32_e32 v47, 31, v41
	v_lshrrev_b32_e32 v46, 28, v46
	v_add_u32_e32 v39, v39, v45
	v_and_b32_e32 v35, -16, v35
	v_add_u32_e32 v37, v37, v8
	s_mov_b32 m0, s27
	v_add_u32_e32 v36, 0x7000, v36
	v_ashrrev_i32_e32 v48, 31, v42
	v_lshrrev_b32_e32 v47, 28, v47
	v_add_u32_e32 v40, v40, v46
	v_and_b32_e32 v38, -16, v39
	v_add_u32_e32 v35, v35, v9
	buffer_load_dwordx4 v37, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s28
	v_ashrrev_i32_e32 v49, 31, v36
	v_lshrrev_b32_e32 v48, 28, v48
	v_add_u32_e32 v41, v41, v47
	v_and_b32_e32 v39, -16, v40
	v_add_u32_e32 v38, v38, v10
	buffer_load_dwordx4 v35, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s29
	v_lshrrev_b32_e32 v49, 28, v49
	v_add_u32_e32 v42, v42, v48
	v_and_b32_e32 v40, -16, v41
	v_add_u32_e32 v39, v39, v11
	buffer_load_dwordx4 v38, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s30
	v_add_u32_e32 v36, v36, v49
	v_and_b32_e32 v41, -16, v42
	v_add_u32_e32 v40, v40, v12
	buffer_load_dwordx4 v39, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s31
	v_and_b32_e32 v36, -16, v36
	v_add_u32_e32 v41, v41, v13
	buffer_load_dwordx4 v40, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s33
	v_add_u32_e32 v36, v36, v14
	buffer_load_dwordx4 v41, s[8:11], 0 offen sc0 nt lds
	s_mov_b32 m0, s34
	s_nop 0
	buffer_load_dwordx4 v36, s[8:11], 0 offen sc0 nt lds
	; sched_barrier mask(0x00000000)
	s_and_b32 s8, s20, 1
	s_and_b32 s9, s20, 2
	s_and_b32 s23, s20, 4
	s_and_b32 s24, s20, 8
	s_lshl_b32 s25, s8, 9
	s_lshl_b32 s26, s9, 9
	s_lshl_b32 s27, s23, 9
	s_lshl_b32 s28, s24, 9
	s_cmp_lt_u32 s20, 16
	v_or_b32_e32 v52, s25, v31
	v_or_b32_e32 v53, s25, v32
	s_cselect_b32 s25, 0, 0x2000
	s_cselect_b32 s29, 0, 0x8000
	s_lshl_b32 s8, s8, 11
	v_or_b32_e32 v52, s26, v52
	s_lshl_b32 s23, s23, 11
	s_or_b32 s25, s25, s28
	v_or_b32_e32 v57, s8, v27
	v_or_b32_e32 v54, s26, v53
	s_lshl_b32 s9, s9, 11
	s_lshl_b32 s24, s24, 11
	v_or_b32_e32 v55, s27, v52
	v_or_b32_e32 v58, s8, v19
	v_or_b32_e32 v60, s23, v33
	v_or_b32_e32 v53, s25, v53
	v_or_b32_e32 v57, s23, v57
	v_add_u32_e32 v35, s22, v3
	v_add_u32_e32 v36, s22, v25
	v_or_b32_e32 v55, s25, v55
	s_or_b32 s28, s25, s27
	v_or_b32_e32 v58, s23, v58
	v_or_b32_e32 v60, s24, v60
	v_or_b32_e32 v53, s26, v53
	v_or_b32_e32 v61, s9, v57
	v_or_b32_e32 v57, s24, v57
	v_add3_u32 v40, s21, v3, v34
	v_add_u32_e32 v44, v35, v21
	v_add_u32_e32 v48, v36, v21
	v_add_u32_e32 v55, s15, v55
	v_or_b32_e32 v52, s28, v52
	v_or_b32_e32 v58, s24, v58
	v_or_b32_e32 v60, s8, v60
	v_or_b32_e32 v53, s27, v53
	v_or_b32_e32 v61, s24, v61
	v_or_b32_e32 v57, s9, v57
	v_add_u32_e32 v56, v36, v17
	ds_read_b128 v[36:39], v40
	ds_read_b128 v[40:43], v40 offset:16384
	ds_read_b128 v[44:47], v44
	ds_read_b128 v[48:51], v48
	v_mov_b32_e32 v59, s29
	v_or_b32_e32 v54, s28, v54
	v_add_u32_e32 v52, s15, v52
	v_or_b32_e32 v58, s9, v58
	v_or_b32_e32 v60, s9, v60
	ds_read_u8 v62, v55
	v_add_u32_e32 v53, s15, v53
	v_or_b32_e32 v55, s29, v61
	v_or_b32_e32 v57, s29, v57
	v_add_u32_e32 v54, s15, v54
	v_or_b32_e32 v61, s29, v58
	v_bitop3_b32 v63, v58, s18, v59 bitop3:0x36
	v_or_b32_e32 v60, s29, v60
	v_bitop3_b32 v58, v58, s19, v59 bitop3:0x36
	ds_read_u8 v64, v52 offset:128
	ds_read_u8 v65, v52 offset:256
	ds_read_u8 v66, v52 offset:384
	ds_read_u8 v67, v54
	ds_read_u8 v68, v53 offset:128
	ds_read_u8 v69, v53 offset:256
	ds_read_u8 v70, v53 offset:384
	v_add_u32_e32 v52, 0, v55
	v_or_b32_e32 v53, 0x240, v57
	v_or_b32_e32 v55, 0x640, v57
	v_add_u32_e32 v35, v35, v17
	v_add_u32_e32 v54, 0, v57
	v_add_u32_e32 v57, 0, v61
	v_add_u32_e32 v59, 0, v63
	v_add_u32_e32 v60, 0, v60
	v_add_u32_e32 v58, 0, v58
	v_add_u32_e32 v53, 0, v53
	v_add_u32_e32 v55, 0, v55
	ds_read_u8 v61, v52
	ds_read_u8 v63, v53
	ds_read_u8 v71, v54 offset:1024
	ds_read_u8 v72, v55
	ds_read_u8 v73, v57
	ds_read_u8 v74, v59
	ds_read_u8 v60, v60
	ds_read_u8 v75, v58
	ds_read_b128 v[52:55], v35 offset:4096
	ds_read_b128 v[56:59], v56 offset:4096
	v_add3_u32 v35, s21, v25, v34
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[44:47], a[4:7], v61, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s20, s20, 1
	s_add_u32 s4, s4, 0x100
	s_addc_u32 s5, s5, 0
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[52:55], a[0:3], v61, v67 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_u32 s2, s2, 0x100
	s_addc_u32 s3, s3, 0
	s_cmp_lg_u32 s20, 31
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[44:47], a[12:15], v73, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v44, s22, v22
	v_add3_u32 v45, s21, v24, v34
	v_add_u32_e32 v61, v44, v17
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[40:43], v[52:55], a[8:11], v73, v67 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v35
	ds_read_b128 v[40:43], v35 offset:16384
	v_add_u32_e32 v53, v44, v21
	v_add_u32_e32 v35, s22, v24
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[48:51], a[4:7], v63, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v52, v35, v21
	v_add_u32_e32 v35, v35, v17
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[56:59], a[0:3], v63, v68 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v45
	ds_read_b128 v[44:47], v45 offset:16384
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[48:51], a[12:15], v74, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[40:43], v[56:59], a[8:11], v74, v68 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[40:43], v52
	ds_read_b128 v[48:51], v53
	ds_read_b128 v[52:55], v35 offset:4096
	ds_read_b128 v[56:59], v61 offset:4096
	v_add3_u32 v35, s21, v22, v34
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[40:43], a[4:7], v71, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[52:55], a[0:3], v71, v69 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[44:47], v[40:43], a[12:15], v60, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[36:39], v35
	ds_read_b128 v[40:43], v35 offset:16384
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[44:47], v[52:55], a[8:11], v60, v69 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[36:39], v[48:51], a[4:7], v72, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[36:39], v[56:59], a[0:3], v72, v70 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[40:43], v[48:51], a[12:15], v75, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[40:43], v[56:59], a[8:11], v75, v70 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_1
; %bb.2:
	s_add_i32 s1, 0, 0x23e00
	v_add_u32_e32 v5, s1, v26
	v_add3_u32 v5, v5, v30, v28
	v_add3_u32 v8, s1, v29, v28
	s_waitcnt vmcnt(0)
	s_barrier
	ds_read_u8 v16, v5
	ds_read_u8 v18, v5 offset:128
	ds_read_u8 v62, v5 offset:256
	ds_read_u8 v5, v5 offset:384
	ds_read_u8 v63, v8
	ds_read_u8 v64, v8 offset:128
	ds_read_u8 v65, v8 offset:256
	ds_read_u8 v66, v8 offset:384
	v_and_b32_e32 v67, 16, v7
	v_and_b32_e32 v68, 32, v7
	v_add_u32_e32 v8, 0, v27
	v_or3_b32 v20, v67, v26, v68
	v_add_u32_e32 v9, 0, v19
	ds_read_u8 v69, v8 offset:63488
	ds_read_u8 v70, v8 offset:64064
	ds_read_u8 v71, v8 offset:64512
	ds_read_u8 v72, v8 offset:65088
	ds_read_u8 v73, v9 offset:63488
	v_xor_b32_e32 v8, 0xfe40, v19
	v_add_u32_e32 v8, 0, v8
	v_add_u32_e32 v76, s16, v3
	v_add_u32_e32 v77, s16, v25
	v_lshlrev_b32_e32 v20, 8, v20
	ds_read_u8 v74, v8
	ds_read_u8 v75, v9 offset:64512
	v_add_u32_e32 v8, v76, v21
	v_add_u32_e32 v12, v77, v21
	v_add3_u32 v3, s17, v3, v20
	ds_read_b128 v[8:11], v8
	ds_read_b128 v[12:15], v12
	ds_read_b128 v[26:29], v3
	v_add_u32_e32 v78, s16, v24
	v_add3_u32 v25, s17, v25, v20
	ds_read_b128 v[30:33], v25
	v_add_u32_e32 v79, s16, v22
	v_add3_u32 v24, s17, v24, v20
	ds_read_b128 v[34:37], v24
	ds_read_b128 v[38:41], v3 offset:16384
	v_add_u32_e32 v3, v79, v21
	v_add_u32_e32 v23, v78, v21
	ds_read_b128 v[42:45], v25 offset:16384
	ds_read_b128 v[46:49], v23
	ds_read_b128 v[50:53], v3
	v_add3_u32 v3, s17, v22, v20
	ds_read_b128 v[20:23], v24 offset:16384
	ds_read_b128 v[54:57], v3
	ds_read_b128 v[58:61], v3 offset:16384
	v_xor_b32_e32 v3, 0xfa40, v19
	v_add_u32_e32 v3, 0, v3
	ds_read_u8 v3, v3
	s_waitcnt lgkmcnt(10)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[26:29], v[8:11], a[4:7], v69, v16 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_ashr_i32 s1, s13, 31
	s_mul_hi_i32 s2, s13, 0x1a000
	s_mul_i32 s13, s13, 0x1a000
	s_waitcnt lgkmcnt(7)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[38:41], v[8:11], a[12:15], v73, v16 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v8, v76, v17
	ds_read_b128 v[8:11], v8 offset:4096
	v_lshlrev_b32_e32 v0, 7, v0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[30:33], v[12:15], a[4:7], v70, v18 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mul_u32_u24_e32 v1, 0xd000, v1
	v_and_b32_e32 v0, 0x780, v0
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[42:45], v[12:15], a[12:15], v3, v18 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[34:37], v[46:49], a[4:7], v71, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[20:23], v[46:49], a[12:15], v75, v62 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[4:7], v[54:57], v[50:53], a[4:7], v72, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[12:15], v[58:61], v[50:53], a[12:15], v74, v5 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v5, v77, v17
	ds_read_b128 v[12:15], v5 offset:4096
	v_add_u32_e32 v5, v78, v17
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[38:41], v[8:11], a[8:11], v73, v63 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[26:29], v[8:11], a[0:3], v69, v63 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[24:27], v5 offset:4096
	v_add_u32_e32 v5, v79, v17
	ds_read_b128 v[16:19], v5 offset:4096
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[42:45], v[12:15], a[8:11], v3, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mov_b32_e32 v5, s1
	v_mov_b32_e32 v3, s1
	s_ashr_i32 s1, s0, 31
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[30:33], v[12:15], a[0:3], v70, v64 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_and_b32_e32 v10, 0x78, v6
	s_add_u32 s3, s6, s13
	v_or_b32_e32 v8, s0, v10
	v_mov_b32_e32 v9, s1
	s_addc_u32 s2, s7, s2
	s_lshl_b64 s[0:1], s[0:1], 1
	s_add_u32 s4, s3, s0
	s_addc_u32 s5, s2, s1
	s_ashr_i32 s13, s12, 31
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[34:37], v[24:27], a[0:3], v71, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v10, v1, v10
	v_cmp_gt_i64_e64 s[0:1], s[12:13], v[2:3]
	v_and_b32_e32 v1, 12, v7
	v_lshrrev_b32_e32 v2, 3, v0
	v_add_u32_e32 v2, 0, v2
	v_lshlrev_b32_e32 v1, 1, v1
	v_lshlrev_b32_e32 v0, 1, v0
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[20:23], v[24:27], a[8:11], v75, v65 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_ashr_i32 s15, s14, 31
	v_add3_u32 v0, v2, v1, v0
	v_lshlrev_b32_e32 v1, 1, v67
	v_lshlrev_b32_e32 v2, 1, v68
	v_cmp_gt_i64_e64 s[2:3], s[14:15], v[8:9]
	v_add3_u32 v8, v0, v1, v2
	v_accvgpr_read_b32 v0, a7
	v_accvgpr_read_b32 v1, a6
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 a[0:3], v[54:57], v[16:19], a[0:3], v72, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cvt_pk_bf16_f32 v1, v1, v0
	v_accvgpr_read_b32 v0, a5
	v_accvgpr_read_b32 v2, a4
	v_cvt_pk_bf16_f32 v0, v2, v0
	v_accvgpr_read_b32 v2, a15
	v_accvgpr_read_b32 v3, a14
	v_mfma_scale_f32_16x16x128_f8f6f4 a[8:11], v[58:61], v[16:19], a[8:11], v74, v66 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_cmp_gt_i64_e32 vcc, s[12:13], v[4:5]
	v_cvt_pk_bf16_f32 v3, v3, v2
	v_accvgpr_read_b32 v2, a13
	v_accvgpr_read_b32 v5, a12
	v_and_b32_e32 v4, 0x7f8, v6
	v_cvt_pk_bf16_f32 v2, v5, v2
	s_barrier
	ds_write2_b64 v8, v[0:1], v[2:3] offset1:16
	v_lshrrev_b32_e32 v0, 3, v6
	v_lshlrev_b32_e32 v1, 1, v4
	v_accvgpr_read_b32 v4, a3
	v_accvgpr_read_b32 v5, a2
	v_and_b32_e32 v0, 0xf0, v0
	v_cvt_pk_bf16_f32 v5, v5, v4
	v_accvgpr_read_b32 v4, a1
	v_accvgpr_read_b32 v6, a0
	v_add3_u32 v9, 0, v0, v1
	v_cvt_pk_bf16_f32 v4, v6, v4
	v_accvgpr_read_b32 v6, a11
	v_accvgpr_read_b32 v7, a10
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[0:3], v9
	v_cvt_pk_bf16_f32 v7, v7, v6
	v_accvgpr_read_b32 v6, a9
	v_accvgpr_read_b32 v11, a8
	v_cvt_pk_bf16_f32 v6, v11, v6
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_write2_b64 v8, v[4:5], v[6:7] offset1:16
	s_waitcnt lgkmcnt(0)
	s_barrier
	ds_read_b128 v[4:7], v9
	s_and_b32 s5, s5, 0xffff
	v_lshlrev_b32_e32 v8, 1, v10
	v_bfrev_b32_e32 v9, 1
	s_and_b64 vcc, vcc, s[2:3]
	s_or_b32 s5, s5, 0x60000000
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
		.amdhsa_next_free_vgpr 96
		.amdhsa_next_free_sgpr 35
		.amdhsa_accum_offset 80
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
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 80
	.set _gemm_afp4_wfp4_kernel.num_agpr, 16
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 35
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5700
; TotalNumSgprs: 41
; NumVgprs: 80
; NumAgprs: 16
; TotalNumVgprs: 96
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 5
; VGPRBlocks: 11
; NumSGPRsForWavesPerEU: 41
; NumVGPRsForWavesPerEU: 96
; AccumOffset: 80
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 19
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
    .sgpr_count:     41
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     96
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
