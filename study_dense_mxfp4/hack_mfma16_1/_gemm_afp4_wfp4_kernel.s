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
; %bb.9:
	.file	1 "/app/aiter/aiter/ops/triton" "gemm_afp4wfp4.py"
	s_load_dwordx2 s[2:3], s[0:1], 0x0
	s_load_dwordx8 s[4:11], s[0:1], 0x8
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_waitcnt lgkmcnt(0)
	s_branch .LBB0_0
	.p2align	8
; %bb.10:
.LBB0_0:
	s_mov_b32 s26, s13
	.file	2 "/app/OAI-triton/python/triton/language" "standard.py"
	s_add_i32 s17, s26, 0xff
	s_ashr_i32 s18, s17, 31
	s_lshr_b32 s18, s18, 24
	s_add_i32 s17, s17, s18
	s_ashr_i32 s18, s17, 8
	.file	3 "/app/aiter/aiter/ops/triton/utils" "pid_preprocessing.py"
	s_lshl_b32 s18, s18, 2
	s_abs_i32 s19, s18
	v_cvt_f32_u32_e32 v1, s19
	s_add_i32 s13, s12, 0xff
	s_ashr_i32 s20, s13, 31
	s_lshr_b32 s20, s20, 24
	v_rcp_iflag_f32_e32 v1, v1
	s_add_i32 s13, s13, s20
	s_sub_i32 s20, 0, s19
	s_abs_i32 s25, s16
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s24, s16, 31
	s_ashr_i32 s17, s17, 31
	s_ashr_i32 s13, s13, 8
	v_readfirstlane_b32 s21, v1
	s_mul_i32 s20, s20, s21
	s_mul_hi_u32 s20, s21, s20
	s_add_i32 s21, s21, s20
	s_mul_hi_u32 s20, s25, s21
	s_mul_i32 s21, s20, s19
	s_sub_i32 s21, s25, s21
	s_xor_b32 s17, s24, s17
	s_add_i32 s22, s20, 1
	s_sub_i32 s23, s21, s19
	s_cmp_ge_u32 s21, s19
	s_cselect_b32 s20, s22, s20
	s_cselect_b32 s21, s23, s21
	s_add_i32 s22, s20, 1
	s_cmp_ge_u32 s21, s19
	s_cselect_b32 s19, s22, s20
	s_xor_b32 s19, s19, s17
	s_sub_i32 s17, s19, s17
	s_lshl_b32 s19, s17, 2
	s_sub_i32 s13, s13, s19
	s_min_i32 s13, s13, 4
	s_abs_i32 s27, s13
	v_cvt_f32_u32_e32 v1, s27
	s_load_dwordx4 s[20:23], s[0:1], 0x38
	s_sub_i32 s0, 0, s27
	s_mul_i32 s17, s17, s18
	v_rcp_iflag_f32_e32 v1, v1
	v_lshlrev_b32_e32 v2, 2, v0
	v_and_b32_e32 v7, 0xfc, v2
	v_lshrrev_b32_e32 v2, 4, v0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	v_and_b32_e32 v162, 16, v2
	v_lshlrev_b32_e32 v150, 4, v0
	s_movk_i32 s30, 0x70
	v_readfirstlane_b32 s28, v1
	s_mul_i32 s0, s0, s28
	s_mul_hi_u32 s0, s28, s0
	s_add_i32 s28, s28, s0
	s_mul_hi_u32 s0, s25, s28
	s_mul_i32 s0, s0, s27
	s_sub_i32 s0, s25, s0
	s_sub_i32 s25, s0, s27
	s_cmp_ge_u32 s0, s27
	s_cselect_b32 s0, s25, s0
	s_sub_i32 s25, s0, s27
	s_cmp_ge_u32 s0, s27
	s_cselect_b32 s0, s25, s0
	s_xor_b32 s0, s0, s24
	s_sub_i32 s0, s0, s24
	s_add_i32 s19, s19, s0
	s_sub_i32 s0, s16, s17
	s_xor_b32 s13, s0, s13
	s_abs_i32 s0, s0
	s_mul_hi_u32 s16, s0, s28
	s_mul_i32 s17, s16, s27
	s_sub_i32 s0, s0, s17
	s_ashr_i32 s13, s13, 31
	s_add_i32 s17, s16, 1
	s_sub_i32 s18, s0, s27
	s_cmp_ge_u32 s0, s27
	s_cselect_b32 s16, s17, s16
	s_cselect_b32 s0, s18, s0
	s_add_i32 s17, s16, 1
	s_cmp_ge_u32 s0, s27
	s_cselect_b32 s0, s17, s16
	s_xor_b32 s0, s0, s13
	s_sub_i32 s16, s0, s13
	s_abs_i32 s0, s12
	v_cvt_f32_u32_e32 v2, s0
	s_lshl_b32 s13, s19, 8
	v_lshrrev_b32_e32 v1, 3, v0
	s_sub_i32 s18, 0, s0
	v_rcp_iflag_f32_e32 v2, v2
	v_or_b32_e32 v6, s13, v1
	s_bfe_i32 s17, s19, 0x10017
	v_add_u32_e32 v6, s17, v6
	v_mul_f32_e32 v2, 0x4f7ffffe, v2
	v_cvt_u32_f32_e32 v2, v2
	v_xor_b32_e32 v6, s17, v6
	v_or_b32_e32 v3, 64, v1
	v_or_b32_e32 v8, s13, v3
	v_mul_lo_u32 v12, s18, v2
	v_mul_hi_u32 v12, v2, v12
	v_add_u32_e32 v2, v2, v12
	v_mul_hi_u32 v12, v6, v2
	v_mul_lo_u32 v12, v12, s0
	v_sub_u32_e32 v6, v6, v12
	v_subrev_u32_e32 v12, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_or_b32_e32 v4, 0x80, v1
	v_or_b32_e32 v9, s13, v4
	v_cndmask_b32_e32 v6, v6, v12, vcc
	v_subrev_u32_e32 v12, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_or_b32_e32 v5, 0xc0, v1
	v_or_b32_e32 v10, s13, v5
	v_cndmask_b32_e32 v6, v6, v12, vcc
	v_xor_b32_e32 v6, s17, v6
	v_subrev_u32_e32 v12, s17, v6
	v_add_u32_e32 v6, s17, v8
	v_xor_b32_e32 v6, s17, v6
	v_mul_hi_u32 v8, v6, v2
	v_mul_lo_u32 v8, v8, s0
	v_sub_u32_e32 v6, v6, v8
	v_subrev_u32_e32 v8, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_or_b32_e32 v11, s13, v7
	s_add_i32 s31, s14, 0x7f
	v_cndmask_b32_e32 v6, v6, v8, vcc
	v_subrev_u32_e32 v8, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	s_mov_b32 s19, 0x27000
	v_and_b32_e32 v151, 63, v0
	v_cndmask_b32_e32 v6, v6, v8, vcc
	v_xor_b32_e32 v6, s17, v6
	v_subrev_u32_e32 v8, s17, v6
	v_add_u32_e32 v6, s17, v9
	v_xor_b32_e32 v6, s17, v6
	v_mul_hi_u32 v9, v6, v2
	v_mul_lo_u32 v9, v9, s0
	v_sub_u32_e32 v6, v6, v9
	v_subrev_u32_e32 v9, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_and_b32_e32 v154, 15, v0
	v_lshrrev_b32_e32 v163, 2, v0
	v_cndmask_b32_e32 v6, v6, v9, vcc
	v_subrev_u32_e32 v9, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	s_mov_b32 s1, 0
	v_and_b32_e32 v155, 16, v163
	v_cndmask_b32_e32 v6, v6, v9, vcc
	v_xor_b32_e32 v6, s17, v6
	v_subrev_u32_e32 v9, s17, v6
	v_add_u32_e32 v6, s17, v10
	v_xor_b32_e32 v6, s17, v6
	v_mul_hi_u32 v10, v6, v2
	v_mul_lo_u32 v10, v10, s0
	v_sub_u32_e32 v6, v6, v10
	v_subrev_u32_e32 v10, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_and_b32_e32 v164, 32, v163
	v_add_u32_e32 v165, v154, v162
	v_cndmask_b32_e32 v6, v6, v10, vcc
	v_subrev_u32_e32 v10, s0, v6
	v_cmp_le_u32_e32 vcc, s0, v6
	v_or_b32_e32 v166, 64, v154
	s_nop 0
	v_cndmask_b32_e32 v6, v6, v10, vcc
	v_xor_b32_e32 v6, s17, v6
	v_subrev_u32_e32 v10, s17, v6
	v_add_u32_e32 v6, s17, v11
	v_xor_b32_e32 v6, s17, v6
	v_mul_hi_u32 v2, v6, v2
	v_mul_lo_u32 v2, v2, s0
	v_sub_u32_e32 v2, v6, v2
	v_subrev_u32_e32 v6, s0, v2
	v_cmp_le_u32_e32 vcc, s0, v2
	s_nop 1
	v_cndmask_b32_e32 v2, v2, v6, vcc
	v_subrev_u32_e32 v6, s0, v2
	v_cmp_le_u32_e32 vcc, s0, v2
	s_lshl_b32 s0, s16, 8
	v_or_b32_e32 v11, s0, v1
	v_cndmask_b32_e32 v2, v2, v6, vcc
	v_xor_b32_e32 v2, s17, v2
	v_subrev_u32_e32 v2, s17, v2
	s_abs_i32 s17, s26
	v_cvt_f32_u32_e32 v6, s17
	s_sub_i32 s18, 0, s17
	s_bfe_i32 s16, s16, 0x10017
	v_add_u32_e32 v11, s16, v11
	v_rcp_iflag_f32_e32 v6, v6
	v_xor_b32_e32 v11, s16, v11
	v_or_b32_e32 v3, s0, v3
	v_add_u32_e32 v3, s16, v3
	v_mul_f32_e32 v6, 0x4f7ffffe, v6
	v_cvt_u32_f32_e32 v6, v6
	v_xor_b32_e32 v3, s16, v3
	v_or_b32_e32 v4, s0, v4
	v_add_u32_e32 v4, s16, v4
	v_mul_lo_u32 v14, s18, v6
	v_mul_hi_u32 v14, v6, v14
	v_add_u32_e32 v6, v6, v14
	v_mul_hi_u32 v14, v11, v6
	v_mul_lo_u32 v14, v14, s17
	v_sub_u32_e32 v11, v11, v14
	v_subrev_u32_e32 v14, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_xor_b32_e32 v4, s16, v4
	v_or_b32_e32 v5, s0, v5
	v_cndmask_b32_e32 v11, v11, v14, vcc
	v_subrev_u32_e32 v14, s17, v11
	v_cmp_le_u32_e32 vcc, s17, v11
	v_or_b32_e32 v13, s0, v7
	s_cmpk_gt_i32 s31, 0x7f
	v_cndmask_b32_e32 v11, v11, v14, vcc
	v_mul_hi_u32 v14, v3, v6
	v_mul_lo_u32 v14, v14, s17
	v_sub_u32_e32 v3, v3, v14
	v_subrev_u32_e32 v14, s17, v3
	v_cmp_le_u32_e32 vcc, s17, v3
	v_xor_b32_e32 v11, s16, v11
	v_subrev_u32_e32 v11, s16, v11
	v_cndmask_b32_e32 v3, v3, v14, vcc
	v_subrev_u32_e32 v14, s17, v3
	v_cmp_le_u32_e32 vcc, s17, v3
	s_mov_b32 s18, 0x7ffffffe
	s_nop 0
	v_cndmask_b32_e32 v3, v3, v14, vcc
	v_mul_hi_u32 v14, v4, v6
	v_mul_lo_u32 v14, v14, s17
	v_sub_u32_e32 v4, v4, v14
	v_subrev_u32_e32 v14, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	v_xor_b32_e32 v3, s16, v3
	v_subrev_u32_e32 v3, s16, v3
	v_cndmask_b32_e32 v4, v4, v14, vcc
	v_subrev_u32_e32 v14, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v14, vcc
	v_xor_b32_e32 v4, s16, v4
	v_subrev_u32_e32 v14, s16, v4
	v_add_u32_e32 v4, s16, v5
	v_xor_b32_e32 v4, s16, v4
	v_mul_hi_u32 v5, v4, v6
	v_mul_lo_u32 v5, v5, s17
	v_sub_u32_e32 v4, v4, v5
	v_subrev_u32_e32 v5, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v5, vcc
	v_subrev_u32_e32 v5, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v5, vcc
	v_xor_b32_e32 v4, s16, v4
	v_subrev_u32_e32 v5, s16, v4
	v_add_u32_e32 v4, s16, v13
	v_xor_b32_e32 v4, s16, v4
	v_mul_hi_u32 v6, v4, v6
	v_mul_lo_u32 v6, v6, s17
	v_sub_u32_e32 v4, v4, v6
	v_subrev_u32_e32 v6, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_subrev_u32_e32 v6, s17, v4
	v_cmp_le_u32_e32 vcc, s17, v4
	s_nop 1
	v_cndmask_b32_e32 v4, v4, v6, vcc
	v_xor_b32_e32 v4, s16, v4
	v_and_b32_e32 v6, 0x70, v150
	v_subrev_u32_e32 v4, s16, v4
	s_waitcnt lgkmcnt(0)
	v_mad_u64_u32 v[140:141], s[16:17], v3, s20, v[6:7]
	v_lshrrev_b32_e32 v3, 6, v0
	v_mad_u64_u32 v[130:131], s[16:17], v12, s15, v[6:7]
	v_mad_u64_u32 v[132:133], s[16:17], v8, s15, v[6:7]
	v_mad_u64_u32 v[134:135], s[16:17], v9, s15, v[6:7]
	v_mad_u64_u32 v[136:137], s[16:17], v10, s15, v[6:7]
	v_mad_u64_u32 v[138:139], s[16:17], v11, s20, v[6:7]
	v_mad_u64_u32 v[142:143], s[16:17], v14, s20, v[6:7]
	v_mad_u64_u32 v[144:145], s[16:17], v5, s20, v[6:7]
	v_mad_u64_u32 v[146:147], s[16:17], s22, v3, v[2:3]
	v_mad_u64_u32 v[148:149], s[16:17], s23, v3, v[4:5]
	s_cselect_b64 vcc, -1, 0
	s_cmpk_lt_i32 s31, 0x80
	s_cselect_b64 s[24:25], -1, 0
	v_lshl_or_b32 v133, v3, 8, v7
	s_add_i32 s14, 0, 0x20000
	s_and_b32 s16, s22, 0x3fff
	v_add_u32_e32 v2, s14, v133
	s_bitset1_b32 s16, 14
	v_bfrev_b32_e32 v4, 1
	s_and_b32 s17, s9, 0xffff
	s_lshl_b32 s27, s16, 16
	v_readfirstlane_b32 s28, v2
	s_or_b32 s17, s17, s27
	s_mov_b32 s16, s8
	v_cndmask_b32_e32 v3, v4, v146, vcc
	s_mov_b32 m0, s28
	s_add_i32 s29, 0, 0x21000
	buffer_load_dword v3, s[16:19], 0 offen lds
	s_and_b32 s16, s23, 0x3fff
	v_add_u32_e32 v2, s29, v133
	s_bitset1_b32 s16, 14
	v_bitop3_b32 v135, v150, s30, v0 bitop3:0x48
	s_and_b32 s17, s11, 0xffff
	s_lshl_b32 s28, s16, 16
	v_readfirstlane_b32 s33, v2
	v_sub_u32_e32 v2, v135, v6
	s_or_b32 s17, s17, s28
	s_mov_b32 s16, s10
	v_cndmask_b32_e32 v3, v4, v148, vcc
	s_mov_b32 m0, s33
	v_ashrrev_i32_e32 v2, 4, v2
	buffer_load_dword v3, s[16:19], 0 offen lds
	v_add_u32_e32 v2, v2, v151
	v_mov_b32_e32 v3, 0x7f
	v_lshlrev_b32_e32 v137, 7, v1
	v_lshlrev_b32_e32 v143, 2, v2
	v_cmp_gt_i32_e32 vcc, s31, v3
	v_or_b32_e32 v141, v137, v6
	ds_bpermute_b32 v6, v143, v130
	v_lshrrev_b64 v[2:3], v2, vcc
	ds_bpermute_b32 v3, v143, v132
	s_and_b32 s15, s15, 0x3fff
	v_add_u32_e32 v1, 0, v141
	s_bitset1_b32 s15, 14
	v_and_b32_e32 v2, 1, v2
	v_add_u32_e32 v5, 0x2000, v1
	s_and_b32 s16, s3, 0xffff
	s_lshl_b32 s15, s15, 16
	v_cmp_eq_u32_e32 vcc, 1, v2
	v_readfirstlane_b32 s30, v1
	s_or_b32 s17, s16, s15
	s_mov_b32 s16, s2
	s_waitcnt lgkmcnt(1)
	v_cndmask_b32_e32 v2, v4, v6, vcc
	s_mov_b32 m0, s30
	v_readfirstlane_b32 s30, v5
	v_add_u32_e32 v7, 0x4000, v1
	v_add_u32_e32 v8, 0x6000, v1
	buffer_load_dwordx4 v2, s[16:19], 0 offen lds
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e32 v1, v4, v3, vcc
	ds_bpermute_b32 v2, v143, v134
	s_mov_b32 m0, s30
	v_readfirstlane_b32 s30, v7
	buffer_load_dwordx4 v1, s[16:19], 0 offen lds
	ds_bpermute_b32 v1, v143, v136
	s_waitcnt lgkmcnt(1)
	v_cndmask_b32_e32 v2, v4, v2, vcc
	s_mov_b32 m0, s30
	v_readfirstlane_b32 s30, v8
	ds_bpermute_b32 v6, v143, v138
	buffer_load_dwordx4 v2, s[16:19], 0 offen lds
	s_waitcnt lgkmcnt(1)
	v_cndmask_b32_e32 v1, v4, v1, vcc
	s_mov_b32 m0, s30
	ds_bpermute_b32 v7, v143, v140
	buffer_load_dwordx4 v1, s[16:19], 0 offen lds
	s_add_i32 s30, 0, 0x10000
	s_and_b32 s16, s20, 0x3fff
	v_add_u32_e32 v1, s30, v141
	s_bitset1_b32 s16, 14
	v_add_u32_e32 v2, 0x2000, v1
	s_and_b32 s17, s5, 0xffff
	s_lshl_b32 s20, s16, 16
	v_readfirstlane_b32 s33, v1
	s_or_b32 s17, s17, s20
	s_mov_b32 s16, s4
	s_waitcnt lgkmcnt(1)
	v_cndmask_b32_e32 v6, v4, v6, vcc
	s_mov_b32 m0, s33
	v_readfirstlane_b32 s33, v2
	v_add_u32_e32 v3, 0x4000, v1
	v_add_u32_e32 v5, 0x6000, v1
	buffer_load_dwordx4 v6, s[16:19], 0 offen lds
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e32 v1, v4, v7, vcc
	ds_bpermute_b32 v6, v143, v142
	s_mov_b32 m0, s33
	v_readfirstlane_b32 s33, v3
	buffer_load_dwordx4 v1, s[16:19], 0 offen lds
	ds_bpermute_b32 v1, v143, v144
	s_waitcnt lgkmcnt(1)
	v_cndmask_b32_e32 v2, v4, v6, vcc
	s_mov_b32 m0, s33
	v_readfirstlane_b32 s33, v5
	buffer_load_dwordx4 v2, s[16:19], 0 offen lds
	s_waitcnt lgkmcnt(0)
	v_cndmask_b32_e32 v1, v4, v1, vcc
	s_mov_b32 m0, s33
	v_mov_b32_e32 v5, 0
	buffer_load_dwordx4 v1, s[16:19], 0 offen lds
	v_or_b32_e32 v1, v162, v154
	s_cmpk_lt_i32 s31, 0x100
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v3, v5
	v_mov_b32_e32 v2, v5
	v_mov_b32_e32 v13, v5
	v_mov_b32_e32 v12, v5
	v_mov_b32_e32 v11, v5
	v_mov_b32_e32 v10, v5
	v_mov_b32_e32 v21, v5
	v_mov_b32_e32 v20, v5
	v_mov_b32_e32 v19, v5
	v_mov_b32_e32 v18, v5
	v_mov_b32_e32 v9, v5
	v_mov_b32_e32 v8, v5
	v_mov_b32_e32 v7, v5
	v_mov_b32_e32 v6, v5
	v_mov_b32_e32 v17, v5
	v_mov_b32_e32 v16, v5
	v_mov_b32_e32 v15, v5
	v_mov_b32_e32 v14, v5
	v_mov_b32_e32 v25, v5
	v_mov_b32_e32 v24, v5
	v_mov_b32_e32 v23, v5
	v_mov_b32_e32 v22, v5
	v_mov_b32_e32 v29, v5
	v_mov_b32_e32 v28, v5
	v_mov_b32_e32 v27, v5
	v_mov_b32_e32 v26, v5
	v_mov_b32_e32 v33, v5
	v_mov_b32_e32 v32, v5
	v_mov_b32_e32 v31, v5
	v_mov_b32_e32 v30, v5
	v_mov_b32_e32 v37, v5
	v_mov_b32_e32 v36, v5
	v_mov_b32_e32 v35, v5
	v_mov_b32_e32 v34, v5
	v_mov_b32_e32 v41, v5
	v_mov_b32_e32 v40, v5
	v_mov_b32_e32 v39, v5
	v_mov_b32_e32 v38, v5
	v_mov_b32_e32 v45, v5
	v_mov_b32_e32 v44, v5
	v_mov_b32_e32 v43, v5
	v_mov_b32_e32 v42, v5
	v_mov_b32_e32 v49, v5
	v_mov_b32_e32 v48, v5
	v_mov_b32_e32 v47, v5
	v_mov_b32_e32 v46, v5
	v_mov_b32_e32 v53, v5
	v_mov_b32_e32 v52, v5
	v_mov_b32_e32 v51, v5
	v_mov_b32_e32 v50, v5
	v_mov_b32_e32 v57, v5
	v_mov_b32_e32 v56, v5
	v_mov_b32_e32 v55, v5
	v_mov_b32_e32 v54, v5
	v_mov_b32_e32 v61, v5
	v_mov_b32_e32 v60, v5
	v_mov_b32_e32 v59, v5
	v_mov_b32_e32 v58, v5
	v_mov_b32_e32 v65, v5
	v_mov_b32_e32 v64, v5
	v_mov_b32_e32 v63, v5
	v_mov_b32_e32 v62, v5
	v_mov_b32_e32 v69, v5
	v_mov_b32_e32 v68, v5
	v_mov_b32_e32 v67, v5
	v_mov_b32_e32 v66, v5
	v_mov_b32_e32 v73, v5
	v_mov_b32_e32 v72, v5
	v_mov_b32_e32 v71, v5
	v_mov_b32_e32 v70, v5
	v_mov_b32_e32 v77, v5
	v_mov_b32_e32 v76, v5
	v_mov_b32_e32 v75, v5
	v_mov_b32_e32 v74, v5
	v_mov_b32_e32 v81, v5
	v_mov_b32_e32 v80, v5
	v_mov_b32_e32 v79, v5
	v_mov_b32_e32 v78, v5
	v_mov_b32_e32 v85, v5
	v_mov_b32_e32 v84, v5
	v_mov_b32_e32 v83, v5
	v_mov_b32_e32 v82, v5
	v_mov_b32_e32 v89, v5
	v_mov_b32_e32 v88, v5
	v_mov_b32_e32 v87, v5
	v_mov_b32_e32 v86, v5
	v_mov_b32_e32 v93, v5
	v_mov_b32_e32 v92, v5
	v_mov_b32_e32 v91, v5
	v_mov_b32_e32 v90, v5
	v_mov_b32_e32 v97, v5
	v_mov_b32_e32 v96, v5
	v_mov_b32_e32 v95, v5
	v_mov_b32_e32 v94, v5
	v_mov_b32_e32 v101, v5
	v_mov_b32_e32 v100, v5
	v_mov_b32_e32 v99, v5
	v_mov_b32_e32 v98, v5
	v_mov_b32_e32 v105, v5
	v_mov_b32_e32 v104, v5
	v_mov_b32_e32 v103, v5
	v_mov_b32_e32 v102, v5
	v_mov_b32_e32 v109, v5
	v_mov_b32_e32 v108, v5
	v_mov_b32_e32 v107, v5
	v_mov_b32_e32 v106, v5
	v_mov_b32_e32 v113, v5
	v_mov_b32_e32 v112, v5
	v_mov_b32_e32 v111, v5
	v_mov_b32_e32 v110, v5
	v_mov_b32_e32 v117, v5
	v_mov_b32_e32 v116, v5
	v_mov_b32_e32 v115, v5
	v_mov_b32_e32 v114, v5
	v_mov_b32_e32 v121, v5
	v_mov_b32_e32 v120, v5
	v_mov_b32_e32 v119, v5
	v_mov_b32_e32 v118, v5
	v_mov_b32_e32 v129, v5
	v_mov_b32_e32 v128, v5
	v_mov_b32_e32 v127, v5
	v_mov_b32_e32 v126, v5
	v_mov_b32_e32 v125, v5
	v_mov_b32_e32 v124, v5
	v_mov_b32_e32 v123, v5
	v_mov_b32_e32 v122, v5
	v_and_b32_e32 v131, 48, v0
	v_lshlrev_b32_e32 v139, 7, v1
	s_cbranch_scc1 .LBB0_3
; %bb.1:                                ; %.lr.ph
	s_movk_i32 s1, 0x1880
	v_mov_b32_e32 v15, 0x1000
	v_or_b32_e32 v2, v155, v164
	v_bitop3_b32 v15, v139, s1, v15 bitop3:0xc8
	s_movk_i32 s1, 0x3880
	v_mov_b32_e32 v16, 0x3000
	v_or_b32_e32 v8, v2, v154
	v_and_b32_e32 v10, 0x300, v150
	v_bitop3_b32 v16, v139, s1, v16 bitop3:0xc8
	s_movk_i32 s1, 0x5880
	v_mov_b32_e32 v17, 0x5000
	v_or_b32_e32 v147, v8, v10
	v_bfe_i32 v12, v0, 1, 1
	v_bitop3_b32 v17, v139, s1, v17 bitop3:0xc8
	s_movk_i32 s1, 0x7880
	v_mov_b32_e32 v18, 0x7000
	v_lshlrev_b32_e32 v8, 7, v8
	v_and_b32_e32 v12, 0x110, v12
	v_bfe_i32 v13, v0, 2, 1
	v_bitop3_b32 v18, v139, s1, v18 bitop3:0xc8
	v_and_b32_e32 v19, 0x80, v8
	s_movk_i32 s1, 0x1800
	s_lshl_b32 s23, s23, 3
	s_lshl_b32 s22, s22, 3
	v_or_b32_e32 v9, v166, v2
	v_and_b32_e32 v13, 0x220, v13
	v_or_b32_e32 v20, v131, v19
	v_and_or_b32 v8, v8, s1, v12
	s_lshr_b32 s16, s31, 7
	s_ashr_i32 s31, s22, 31
	s_ashr_i32 s33, s23, 31
	v_or_b32_e32 v3, v166, v162
	v_or_b32_e32 v4, 0x80, v154
	v_or_b32_e32 v21, v8, v13
	v_bitop3_b32 v167, v8, v20, v13 bitop3:0x36
	v_lshlrev_b32_e32 v8, 7, v9
	v_or_b32_e32 v5, v4, v162
	v_or_b32_e32 v4, v4, v2
	v_lshlrev_b32_e32 v3, 7, v3
	v_and_b32_e32 v9, 0x80, v8
	s_movk_i32 s1, 0x3800
	s_add_u32 s4, s4, 0x80
	v_bfe_i32 v14, v0, 3, 1
	v_and_b32_e32 v3, 0x2880, v3
	v_or_b32_e32 v20, v131, v9
	v_and_or_b32 v8, v8, s1, v12
	v_lshlrev_b32_e32 v4, 7, v4
	s_addc_u32 s5, s5, 0
	v_or_b32_e32 v6, 0xc0, v154
	v_or_b32_e32 v11, 64, v131
	v_and_b32_e32 v149, 0x440, v14
	v_or3_b32 v3, v3, v12, v13
	v_or_b32_e32 v22, v8, v13
	v_bitop3_b32 v168, v8, v20, v13 bitop3:0x36
	v_and_b32_e32 v8, 0x80, v4
	s_movk_i32 s1, 0x5800
	s_add_u32 s2, s2, 0x80
	v_or_b32_e32 v7, v6, v162
	v_or_b32_e32 v6, v6, v2
	v_bitop3_b32 v156, v3, v131, v149 bitop3:0x36
	v_or_b32_e32 v20, v131, v8
	v_and_or_b32 v4, v4, s1, v12
	v_bitop3_b32 v173, v3, v11, v149 bitop3:0x36
	v_or_b32_e32 v3, v11, v19
	s_addc_u32 s3, s3, 0
	v_lshlrev_b32_e32 v5, 7, v5
	v_lshlrev_b32_e32 v7, 7, v7
	v_or_b32_e32 v23, v4, v13
	v_bitop3_b32 v169, v4, v20, v13 bitop3:0x36
	v_lshlrev_b32_e32 v4, 7, v6
	s_movk_i32 s1, 0x7800
	v_bitop3_b32 v179, v21, v3, v149 bitop3:0x36
	v_or_b32_e32 v3, v11, v9
	s_add_u32 s10, s10, s23
	v_and_b32_e32 v14, 0x880, v139
	v_and_b32_e32 v5, 0x4880, v5
	v_and_b32_e32 v7, 0x6880, v7
	v_and_b32_e32 v6, 0x80, v4
	v_and_or_b32 v4, v4, s1, v12
	v_bitop3_b32 v180, v22, v3, v149 bitop3:0x36
	v_or_b32_e32 v3, v11, v8
	s_addc_u32 s11, s11, s33
	v_or3_b32 v14, v14, v12, v13
	v_or3_b32 v15, v15, v12, v13
	v_or3_b32 v16, v16, v12, v13
	v_or3_b32 v5, v5, v12, v13
	v_or3_b32 v17, v17, v12, v13
	v_or3_b32 v7, v7, v12, v13
	v_or3_b32 v18, v18, v12, v13
	v_or_b32_e32 v20, v131, v6
	v_or_b32_e32 v12, v4, v13
	v_bitop3_b32 v181, v23, v3, v149 bitop3:0x36
	v_or_b32_e32 v3, v11, v6
	v_add_u32_e32 v2, v154, v2
	s_add_u32 s8, s8, s22
	v_mov_b32_e32 v122, 0
	v_or_b32_e32 v145, v1, v10
	v_bitop3_b32 v152, v14, v131, v149 bitop3:0x36
	v_bitop3_b32 v153, v15, v131, v149 bitop3:0x36
	v_bitop3_b32 v157, v16, v131, v149 bitop3:0x36
	v_bitop3_b32 v158, v5, v131, v149 bitop3:0x36
	v_bitop3_b32 v159, v17, v131, v149 bitop3:0x36
	v_bitop3_b32 v160, v7, v131, v149 bitop3:0x36
	v_bitop3_b32 v161, v18, v131, v149 bitop3:0x36
	v_bitop3_b32 v170, v4, v20, v13 bitop3:0x36
	v_bitop3_b32 v171, v14, v11, v149 bitop3:0x36
	v_bitop3_b32 v172, v15, v11, v149 bitop3:0x36
	v_bitop3_b32 v174, v16, v11, v149 bitop3:0x36
	v_bitop3_b32 v175, v5, v11, v149 bitop3:0x36
	v_bitop3_b32 v176, v17, v11, v149 bitop3:0x36
	v_bitop3_b32 v177, v7, v11, v149 bitop3:0x36
	v_bitop3_b32 v178, v18, v11, v149 bitop3:0x36
	v_bitop3_b32 v182, v12, v3, v149 bitop3:0x36
	v_or_b32_e32 v183, v165, v10
	v_or_b32_e32 v184, v2, v10
	s_addc_u32 s9, s9, s31
	s_mov_b32 s1, 0
	s_add_i32 s14, 0, 0x20000
	s_add_i32 s29, 0, 0x21000
	s_add_i32 s30, 0, 0x10000
	s_add_i32 s34, s16, -1
	s_mov_b32 s35, 0
	v_mov_b32_e32 v123, v122
	v_mov_b32_e32 v124, v122
	v_mov_b32_e32 v125, v122
	v_mov_b32_e32 v126, v122
	v_mov_b32_e32 v127, v122
	v_mov_b32_e32 v128, v122
	v_mov_b32_e32 v129, v122
	v_mov_b32_e32 v118, v122
	v_mov_b32_e32 v119, v122
	v_mov_b32_e32 v120, v122
	v_mov_b32_e32 v121, v122
	v_mov_b32_e32 v114, v122
	v_mov_b32_e32 v115, v122
	v_mov_b32_e32 v116, v122
	v_mov_b32_e32 v117, v122
	v_mov_b32_e32 v110, v122
	v_mov_b32_e32 v111, v122
	v_mov_b32_e32 v112, v122
	v_mov_b32_e32 v113, v122
	v_mov_b32_e32 v106, v122
	v_mov_b32_e32 v107, v122
	v_mov_b32_e32 v108, v122
	v_mov_b32_e32 v109, v122
	v_mov_b32_e32 v102, v122
	v_mov_b32_e32 v103, v122
	v_mov_b32_e32 v104, v122
	v_mov_b32_e32 v105, v122
	v_mov_b32_e32 v98, v122
	v_mov_b32_e32 v99, v122
	v_mov_b32_e32 v100, v122
	v_mov_b32_e32 v101, v122
	v_mov_b32_e32 v94, v122
	v_mov_b32_e32 v95, v122
	v_mov_b32_e32 v96, v122
	v_mov_b32_e32 v97, v122
	v_mov_b32_e32 v90, v122
	v_mov_b32_e32 v91, v122
	v_mov_b32_e32 v92, v122
	v_mov_b32_e32 v93, v122
	v_mov_b32_e32 v86, v122
	v_mov_b32_e32 v87, v122
	v_mov_b32_e32 v88, v122
	v_mov_b32_e32 v89, v122
	v_mov_b32_e32 v82, v122
	v_mov_b32_e32 v83, v122
	v_mov_b32_e32 v84, v122
	v_mov_b32_e32 v85, v122
	v_mov_b32_e32 v78, v122
	v_mov_b32_e32 v79, v122
	v_mov_b32_e32 v80, v122
	v_mov_b32_e32 v81, v122
	v_mov_b32_e32 v74, v122
	v_mov_b32_e32 v75, v122
	v_mov_b32_e32 v76, v122
	v_mov_b32_e32 v77, v122
	v_mov_b32_e32 v70, v122
	v_mov_b32_e32 v71, v122
	v_mov_b32_e32 v72, v122
	v_mov_b32_e32 v73, v122
	v_mov_b32_e32 v66, v122
	v_mov_b32_e32 v67, v122
	v_mov_b32_e32 v68, v122
	v_mov_b32_e32 v69, v122
	v_mov_b32_e32 v62, v122
	v_mov_b32_e32 v63, v122
	v_mov_b32_e32 v64, v122
	v_mov_b32_e32 v65, v122
	v_mov_b32_e32 v58, v122
	v_mov_b32_e32 v59, v122
	v_mov_b32_e32 v60, v122
	v_mov_b32_e32 v61, v122
	v_mov_b32_e32 v54, v122
	v_mov_b32_e32 v55, v122
	v_mov_b32_e32 v56, v122
	v_mov_b32_e32 v57, v122
	v_mov_b32_e32 v50, v122
	v_mov_b32_e32 v51, v122
	v_mov_b32_e32 v52, v122
	v_mov_b32_e32 v53, v122
	v_mov_b32_e32 v46, v122
	v_mov_b32_e32 v47, v122
	v_mov_b32_e32 v48, v122
	v_mov_b32_e32 v49, v122
	v_mov_b32_e32 v42, v122
	v_mov_b32_e32 v43, v122
	v_mov_b32_e32 v44, v122
	v_mov_b32_e32 v45, v122
	v_mov_b32_e32 v38, v122
	v_mov_b32_e32 v39, v122
	v_mov_b32_e32 v40, v122
	v_mov_b32_e32 v41, v122
	v_mov_b32_e32 v34, v122
	v_mov_b32_e32 v35, v122
	v_mov_b32_e32 v36, v122
	v_mov_b32_e32 v37, v122
	v_mov_b32_e32 v30, v122
	v_mov_b32_e32 v31, v122
	v_mov_b32_e32 v32, v122
	v_mov_b32_e32 v33, v122
	v_mov_b32_e32 v26, v122
	v_mov_b32_e32 v27, v122
	v_mov_b32_e32 v28, v122
	v_mov_b32_e32 v29, v122
	v_mov_b32_e32 v22, v122
	v_mov_b32_e32 v23, v122
	v_mov_b32_e32 v24, v122
	v_mov_b32_e32 v25, v122
	v_mov_b32_e32 v14, v122
	v_mov_b32_e32 v15, v122
	v_mov_b32_e32 v16, v122
	v_mov_b32_e32 v17, v122
	v_mov_b32_e32 v6, v122
	v_mov_b32_e32 v7, v122
	v_mov_b32_e32 v8, v122
	v_mov_b32_e32 v9, v122
	v_mov_b32_e32 v18, v122
	v_mov_b32_e32 v19, v122
	v_mov_b32_e32 v20, v122
	v_mov_b32_e32 v21, v122
	v_mov_b32_e32 v10, v122
	v_mov_b32_e32 v11, v122
	v_mov_b32_e32 v12, v122
	v_mov_b32_e32 v13, v122
	v_mov_b32_e32 v2, v122
	v_mov_b32_e32 v3, v122
	v_mov_b32_e32 v4, v122
	v_mov_b32_e32 v5, v122
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s37, s14
	s_mov_b32 s36, s29
	s_mov_b32 s39, s1
	s_mov_b32 s38, s30
	; sched_barrier mask(0x00000000)
	s_waitcnt vmcnt(0)
	s_barrier
	s_waitcnt lgkmcnt(0)
	; sched_barrier mask(0x00000000)
	s_add_i32 s1, s35, 1
	s_cmp_lt_i32 s1, 2
	s_cselect_b32 s35, s1, 0
	ds_bpermute_b32 v185, v143, v130
	s_and_b32 s1, s3, 0xffff
	s_lshl_b32 s14, s35, 15
	ds_bpermute_b32 v186, v143, v132
	s_or_b32 s17, s1, s15
	s_add_i32 s1, s14, 0
	ds_bpermute_b32 v187, v143, v134
	v_add_u32_e32 v189, s1, v141
	ds_bpermute_b32 v188, v143, v136
	s_lshl_b32 s29, s35, 11
	v_add_u32_e32 v190, 0x2000, v189
	v_readfirstlane_b32 s40, v189
	s_mov_b32 s16, s2
	s_add_i32 s29, s29, 0
	v_add_u32_e32 v191, 0x4000, v189
	v_readfirstlane_b32 s41, v190
	s_mov_b32 m0, s40
	s_add_i32 s14, s29, 0x20000
	v_add_u32_e32 v192, 0x6000, v189
	v_readfirstlane_b32 s42, v191
	s_waitcnt lgkmcnt(3)
	buffer_load_dwordx4 v185, s[16:19], 0 offen lds
	s_mov_b32 m0, s41
	v_add_u32_e32 v189, s14, v133
	v_readfirstlane_b32 s43, v192
	s_waitcnt lgkmcnt(2)
	buffer_load_dwordx4 v186, s[16:19], 0 offen lds
	s_mov_b32 m0, s42
	s_and_b32 s30, s9, 0xffff
	v_readfirstlane_b32 s44, v189
	s_waitcnt lgkmcnt(1)
	buffer_load_dwordx4 v187, s[16:19], 0 offen lds
	s_mov_b32 m0, s43
	v_add_u32_e32 v185, s39, v152
	s_waitcnt lgkmcnt(0)
	buffer_load_dwordx4 v188, s[16:19], 0 offen lds
	s_or_b32 s17, s30, s27
	s_mov_b32 s16, s8
	s_mov_b32 m0, s44
	v_add_u32_e32 v190, s39, v153
	buffer_load_dword v146, s[16:19], 0 offen lds
	v_add_u32_e32 v194, s39, v156
	v_add_u32_e32 v198, s39, v157
	v_add_u32_e32 v202, s39, v158
	v_add_u32_e32 v206, s39, v159
	v_add_u32_e32 v210, s39, v160
	v_add_u32_e32 v214, s39, v161
	v_add3_u32 v218, s38, v167, v149
	v_add3_u32 v222, s38, v168, v149
	v_add3_u32 v226, s38, v169, v149
	v_add3_u32 v230, s38, v170, v149
	v_add_u32_e32 v235, s37, v183
	v_add_u32_e32 v237, s36, v184
	v_add_u32_e32 v234, s37, v145
	v_add_u32_e32 v236, s36, v147
	ds_read_b128 v[186:189], v185
	ds_read_b128 v[190:193], v190
	ds_read_b128 v[194:197], v194
	ds_read_b128 v[198:201], v198
	ds_read_b128 v[202:205], v202
	ds_read_b128 v[206:209], v206
	ds_read_b128 v[210:213], v210
	ds_read_b128 v[214:217], v214
	ds_read_b128 v[218:221], v218
	ds_read_b128 v[222:225], v222
	ds_read_b128 v[226:229], v226
	ds_read_b128 v[230:233], v230
	ds_read_u8 v185, v234
	ds_read_u8 v238, v234 offset:32
	ds_read_u8 v239, v234 offset:96
	ds_read_u8 v240, v234 offset:160
	ds_read_u8 v241, v235 offset:128
	ds_read_u8 v242, v235 offset:192
	ds_read_u8 v235, v235 offset:64
	ds_read_u8 v243, v234 offset:224
	ds_read_u8 v244, v236
	ds_read_u8 v245, v237 offset:64
	ds_read_u8 v246, v237 offset:128
	ds_read_u8 v237, v237 offset:192
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:221], v[186:189], v[122:125], v244, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[222:225], v[186:189], v[126:129], v245, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:229], v[186:189], v[118:121], v246, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[230:233], v[186:189], v[114:117], v237, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[218:221], v[190:193], v[110:113], v244, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[222:225], v[190:193], v[106:109], v245, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:229], v[190:193], v[102:105], v246, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[230:233], v[190:193], v[98:101], v237, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[218:221], v[194:197], v[94:97], v244, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[222:225], v[194:197], v[90:93], v245, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[226:229], v[194:197], v[86:89], v246, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[230:233], v[194:197], v[82:85], v237, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[218:221], v[198:201], v[78:81], v244, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[222:225], v[198:201], v[74:77], v245, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[226:229], v[198:201], v[70:73], v246, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[230:233], v[198:201], v[66:69], v237, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[218:221], v[202:205], v[62:65], v244, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[222:225], v[202:205], v[58:61], v245, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:229], v[202:205], v[54:57], v246, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[230:233], v[202:205], v[50:53], v237, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[218:221], v[206:209], v[46:49], v244, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[222:225], v[206:209], v[42:45], v245, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:229], v[206:209], v[38:41], v246, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[230:233], v[206:209], v[34:37], v237, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[218:221], v[210:213], v[30:33], v244, v242 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[222:225], v[210:213], v[26:29], v245, v242 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[226:229], v[210:213], v[22:25], v246, v242 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[230:233], v[210:213], v[14:17], v237, v242 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[218:221], v[214:217], v[6:9], v244, v243 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[222:225], v[214:217], v[18:21], v245, v243 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[226:229], v[214:217], v[10:13], v246, v243 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[230:233], v[214:217], v[2:5], v237, v243 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	; sched_barrier mask(0x00000000)
	s_add_i32 s30, s1, 0x10000
	v_add3_u32 v185, s30, v135, v137
	v_add_u32_e32 v186, s30, v141
	v_add_u32_e32 v187, 0x2000, v186
	v_sub_u32_e32 v190, v185, v186
	v_add_u32_e32 v188, 0x4000, v186
	v_add_u32_e32 v189, 0x6000, v186
	v_ashrrev_i32_e32 v191, 31, v190
	v_readfirstlane_b32 s40, v186
	v_sub_u32_e32 v186, v185, v187
	v_lshrrev_b32_e32 v191, 28, v191
	v_add_u32_e32 v186, 0x2000, v186
	v_add_u32_e32 v190, v190, v191
	v_ashrrev_i32_e32 v191, 31, v186
	v_lshrrev_b32_e32 v191, 28, v191
	v_ashrrev_i32_e32 v190, 4, v190
	v_add_u32_e32 v186, v186, v191
	v_add_lshl_u32 v190, v190, v151, 2
	v_ashrrev_i32_e32 v186, 4, v186
	ds_bpermute_b32 v190, v190, v138
	v_add_lshl_u32 v186, v186, v151, 2
	ds_bpermute_b32 v186, v186, v140
	s_and_b32 s16, s5, 0xffff
	s_or_b32 s17, s16, s20
	s_mov_b32 s16, s4
	s_mov_b32 m0, s40
	v_readfirstlane_b32 s40, v187
	s_waitcnt lgkmcnt(1)
	buffer_load_dwordx4 v190, s[16:19], 0 offen lds
	s_mov_b32 m0, s40
	v_readfirstlane_b32 s40, v188
	s_waitcnt lgkmcnt(0)
	buffer_load_dwordx4 v186, s[16:19], 0 offen lds
	v_sub_u32_e32 v186, v185, v188
	v_add_u32_e32 v186, 0x4000, v186
	v_ashrrev_i32_e32 v187, 31, v186
	v_sub_u32_e32 v185, v185, v189
	v_lshrrev_b32_e32 v187, 28, v187
	v_add_u32_e32 v185, 0x6000, v185
	v_add_u32_e32 v186, v186, v187
	v_ashrrev_i32_e32 v187, 31, v185
	v_lshrrev_b32_e32 v187, 28, v187
	v_ashrrev_i32_e32 v186, 4, v186
	v_add_u32_e32 v185, v185, v187
	v_add_lshl_u32 v186, v186, v151, 2
	v_ashrrev_i32_e32 v185, 4, v185
	ds_bpermute_b32 v186, v186, v142
	v_add_lshl_u32 v185, v185, v151, 2
	ds_bpermute_b32 v185, v185, v144
	s_mov_b32 m0, s40
	v_readfirstlane_b32 s40, v189
	s_waitcnt lgkmcnt(1)
	buffer_load_dwordx4 v186, s[16:19], 0 offen lds
	s_mov_b32 m0, s40
	s_add_i32 s29, s29, 0x21000
	s_waitcnt lgkmcnt(0)
	buffer_load_dwordx4 v185, s[16:19], 0 offen lds
	v_add_u32_e32 v185, s29, v133
	s_and_b32 s16, s11, 0xffff
	v_readfirstlane_b32 s40, v185
	s_or_b32 s17, s16, s28
	s_mov_b32 s16, s10
	s_mov_b32 m0, s40
	v_add_u32_e32 v185, s39, v171
	buffer_load_dword v148, s[16:19], 0 offen lds
	v_add_u32_e32 v190, s39, v172
	ds_read_b128 v[186:189], v185
	ds_read_b128 v[190:193], v190
	v_add_u32_e32 v185, s39, v173
	v_add_u32_e32 v198, s39, v174
	ds_read_b128 v[194:197], v185
	ds_read_b128 v[198:201], v198
	v_add_u32_e32 v185, s39, v175
	v_add_u32_e32 v206, s39, v176
	ds_read_b128 v[202:205], v185
	ds_read_b128 v[206:209], v206
	v_add_u32_e32 v185, s39, v177
	v_add_u32_e32 v214, s39, v178
	ds_read_b128 v[210:213], v185
	ds_read_b128 v[214:217], v214
	v_add_u32_e32 v185, s38, v179
	v_add_u32_e32 v222, s38, v180
	ds_read_b128 v[218:221], v185
	ds_read_b128 v[222:225], v222
	v_add_u32_e32 v185, s38, v181
	v_add_u32_e32 v230, s38, v182
	s_addk_i32 s37, 0x400
	ds_read_b128 v[226:229], v185
	ds_read_b128 v[230:233], v230
	ds_read_u8 v185, v234 offset:1024
	v_add_u32_e32 v234, s37, v145
	v_add_u32_e32 v235, s37, v183
	ds_read_u8 v237, v234 offset:32
	ds_read_u8 v238, v234 offset:96
	ds_read_u8 v239, v234 offset:160
	ds_read_u8 v240, v235 offset:128
	ds_read_u8 v241, v235 offset:192
	ds_read_u8 v235, v235 offset:64
	ds_read_u8 v234, v234 offset:224
	s_addk_i32 s36, 0x400
	v_add_u32_e32 v242, s36, v184
	ds_read_u8 v236, v236 offset:1024
	ds_read_u8 v243, v242 offset:64
	ds_read_u8 v244, v242 offset:128
	ds_read_u8 v242, v242 offset:192
	; sched_barrier mask(0x00000000)
	s_add_u32 s4, s4, 0x80
	s_addc_u32 s5, s5, 0
	s_add_u32 s2, s2, 0x80
	s_addc_u32 s3, s3, 0
	s_add_u32 s10, s10, s23
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:221], v[186:189], v[122:125], v236, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_addc_u32 s11, s11, s33
	s_add_u32 s8, s8, s22
	s_addc_u32 s9, s9, s31
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[222:225], v[186:189], v[126:129], v243, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_add_i32 s34, s34, -1
	s_cmp_lg_u32 s34, 0
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:229], v[186:189], v[118:121], v244, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[230:233], v[186:189], v[114:117], v242, v185 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[218:221], v[190:193], v[110:113], v236, v237 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[222:225], v[190:193], v[106:109], v243, v237 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:229], v[190:193], v[102:105], v244, v237 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[230:233], v[190:193], v[98:101], v242, v237 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[218:221], v[194:197], v[94:97], v236, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[222:225], v[194:197], v[90:93], v243, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[226:229], v[194:197], v[86:89], v244, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[230:233], v[194:197], v[82:85], v242, v235 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[218:221], v[198:201], v[78:81], v236, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[222:225], v[198:201], v[74:77], v243, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[226:229], v[198:201], v[70:73], v244, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[230:233], v[198:201], v[66:69], v242, v238 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[218:221], v[202:205], v[62:65], v236, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[222:225], v[202:205], v[58:61], v243, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:229], v[202:205], v[54:57], v244, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[230:233], v[202:205], v[50:53], v242, v240 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[218:221], v[206:209], v[46:49], v236, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[222:225], v[206:209], v[42:45], v243, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:229], v[206:209], v[38:41], v244, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[230:233], v[206:209], v[34:37], v242, v239 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[218:221], v[210:213], v[30:33], v236, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[222:225], v[210:213], v[26:29], v243, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[226:229], v[210:213], v[22:25], v244, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[230:233], v[210:213], v[14:17], v242, v241 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[218:221], v[214:217], v[6:9], v236, v234 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[222:225], v[214:217], v[18:21], v243, v234 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[226:229], v[214:217], v[10:13], v244, v234 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[230:233], v[214:217], v[2:5], v242, v234 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_cbranch_scc1 .LBB0_2
.LBB0_3:                                ; %._crit_edge
	s_andn2_b64 vcc, exec, s[24:25]
	v_or_b32_e32 v167, 32, v1
	s_waitcnt vmcnt(0)
	s_barrier
	s_cbranch_vccnz .LBB0_6
; %bb.4:                                ; %._crit_edge._crit_edge
	v_or_b32_e32 v170, 0xe0, v1
	v_or_b32_e32 v169, 0xa0, v1
	v_or_b32_e32 v168, 0x60, v1
	v_or_b32_e32 v130, 32, v1
	s_cbranch_execz .LBB0_7
; %bb.5:
	v_mov_b32_e32 v167, v130
	s_branch .LBB0_8
.LBB0_6:
                                        ; implicit-def: $vgpr170
                                        ; implicit-def: $vgpr169
                                        ; implicit-def: $vgpr168
                                        ; implicit-def: $vgpr130
.LBB0_7:
	v_lshlrev_b32_e32 v0, 3, v0
	v_and_or_b32 v130, v0, 48, 64
	v_and_b32_e32 v132, 64, v0
	s_movk_i32 s2, 0x70
	v_or_b32_e32 v178, 0x80, v154
	v_bitop3_b32 v138, v132, v130, v131 bitop3:0x36
	v_bitop3_b32 v0, v0, v131, s2 bitop3:0x6c
	v_or3_b32 v130, v178, v155, v164
	v_add_u32_e32 v158, s30, v138
	v_add_u32_e32 v156, s30, v0
	v_lshlrev_b32_e32 v130, 7, v130
	v_add_u32_e32 v146, v158, v130
	v_add_u32_e32 v151, v156, v130
	v_or3_b32 v130, v166, v155, v164
	v_lshlrev_b32_e32 v130, 7, v130
	v_or3_b32 v141, v164, v155, v154
	v_or_b32_e32 v190, 0xc0, v154
	v_add_u32_e32 v140, v158, v130
	v_add_u32_e32 v142, v156, v130
	v_lshlrev_b32_e32 v130, 7, v141
	v_add_u32_e32 v179, s1, v138
	v_add3_u32 v147, v154, v155, v164
	v_or3_b32 v154, v190, v155, v164
	v_add_u32_e32 v131, v158, v130
	v_add_u32_e32 v134, v156, v130
	v_add_u32_e32 v0, s1, v0
	v_add_u32_e32 v138, v179, v139
	v_and_b32_e32 v176, 0x300, v150
	v_lshlrev_b32_e32 v159, 7, v154
	ds_read_b128 v[130:133], v131
	ds_read_b128 v[134:137], v134
	v_add_u32_e32 v139, v0, v139
	ds_read_b128 v[168:171], v138
	ds_read_b128 v[172:175], v139
	v_add3_u32 v138, s29, v141, v176
	v_add3_u32 v182, s14, v1, v176
	v_add3_u32 v185, s29, v147, v176
	v_add_u32_e32 v154, v156, v159
	v_add_u32_e32 v158, v158, v159
	ds_read_u8 v180, v138 offset:1024
	ds_read_u8 v181, v138
	ds_read_u8 v177, v182
	ds_read_b128 v[138:141], v140
	ds_read_b128 v[142:145], v142
	ds_read_u8 v183, v182 offset:32
	ds_read_u8 v184, v182 offset:1024
	ds_read_u8 v186, v185 offset:64
	ds_read_b128 v[146:149], v146
	ds_read_b128 v[150:153], v151
	ds_read_u8 v187, v185 offset:1088
	ds_read_u8 v188, v185 offset:1152
	ds_read_u8 v189, v185 offset:128
	ds_read_b128 v[154:157], v154
	ds_read_u8 v191, v185 offset:192
	ds_read_b128 v[158:161], v158
	ds_read_u8 v185, v185 offset:1216
	s_waitcnt lgkmcnt(14)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[134:137], v[172:175], v[122:125], v181, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v166, v166, v162
	v_lshlrev_b32_e32 v166, 7, v166
	v_add3_u32 v165, s14, v165, v176
	s_waitcnt lgkmcnt(9)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[142:145], v[172:175], v[126:129], v186, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v176, v165 offset:64
	s_waitcnt lgkmcnt(5)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[150:153], v[172:175], v[118:121], v189, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[154:157], v[172:175], v[114:117], v191, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_lshlrev_b32_e32 v172, 7, v167
	v_add_u32_e32 v173, v0, v172
	v_add_u32_e32 v172, v179, v172
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[130:133], v[168:171], v[122:125], v180, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v177, v182 offset:1056
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[138:141], v[168:171], v[126:129], v187, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[146:149], v[168:171], v[118:121], v188, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[158:161], v[168:171], v[114:117], v185, v184 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[168:171], v173
	ds_read_b128 v[172:175], v172
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[134:137], v[168:171], v[110:113], v181, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[142:145], v[168:171], v[106:109], v186, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[150:153], v[168:171], v[102:105], v189, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[154:157], v[168:171], v[98:101], v191, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v183, v182 offset:96
	v_add_u32_e32 v168, v0, v166
	ds_read_b128 v[168:171], v168
	v_add_u32_e32 v166, v179, v166
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[130:133], v[172:175], v[110:113], v180, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[138:141], v[172:175], v[106:109], v187, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[146:149], v[172:175], v[102:105], v188, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[158:161], v[172:175], v[98:101], v185, v177 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[172:175], v166
	ds_read_u8 v166, v165 offset:1088
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[134:137], v[168:171], v[94:97], v181, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[142:145], v[168:171], v[90:93], v186, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[150:153], v[168:171], v[86:89], v189, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[154:157], v[168:171], v[82:85], v191, v176 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v168, 0x60, v1
	v_lshlrev_b32_e32 v169, 7, v168
	v_add_u32_e32 v170, v0, v169
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[130:133], v[172:175], v[94:97], v180, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[138:141], v[172:175], v[90:93], v187, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[146:149], v[172:175], v[86:89], v188, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[158:161], v[172:175], v[82:85], v185, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[170:173], v170
	v_add_u32_e32 v166, v179, v169
	ds_read_b128 v[174:177], v166
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[134:137], v[170:173], v[78:81], v181, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v166, v182 offset:1120
	ds_read_u8 v169, v165 offset:128
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[142:145], v[170:173], v[74:77], v186, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[150:153], v[170:173], v[70:73], v189, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[154:157], v[170:173], v[66:69], v191, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v170, v178, v162
	v_lshlrev_b32_e32 v178, 7, v170
	v_add_u32_e32 v170, v0, v178
	ds_read_b128 v[170:173], v170
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[130:133], v[174:177], v[78:81], v180, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v162, v190, v162
	v_lshlrev_b32_e32 v162, 7, v162
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[138:141], v[174:177], v[74:77], v187, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[146:149], v[174:177], v[70:73], v188, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[158:161], v[174:177], v[66:69], v185, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v166, v179, v178
	ds_read_b128 v[174:177], v166
	ds_read_u8 v166, v165 offset:1152
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[134:137], v[170:173], v[62:65], v181, v169 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v178, v182 offset:160
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[142:145], v[170:173], v[58:61], v186, v169 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[150:153], v[170:173], v[54:57], v189, v169 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[154:157], v[170:173], v[50:53], v191, v169 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v169, 0xa0, v1
	v_lshlrev_b32_e32 v183, 7, v169
	v_add_u32_e32 v170, v0, v183
	ds_read_b128 v[170:173], v170
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[130:133], v[174:177], v[62:65], v180, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[138:141], v[174:177], v[58:61], v187, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[146:149], v[174:177], v[54:57], v188, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[158:161], v[174:177], v[50:53], v185, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v166, v179, v183
	ds_read_b128 v[174:177], v166
	ds_read_u8 v166, v182 offset:1184
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[134:137], v[170:173], v[46:49], v181, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_u8 v183, v165 offset:192
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[142:145], v[170:173], v[42:45], v186, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[150:153], v[170:173], v[38:41], v189, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[154:157], v[170:173], v[34:37], v191, v178 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_add_u32_e32 v170, v0, v162
	ds_read_b128 v[170:173], v170
	v_add_u32_e32 v162, v179, v162
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[130:133], v[174:177], v[46:49], v180, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[138:141], v[174:177], v[42:45], v187, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[146:149], v[174:177], v[38:41], v188, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[158:161], v[174:177], v[34:37], v185, v166 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[174:177], v162
	ds_read_u8 v162, v165 offset:1216
	ds_read_u8 v165, v182 offset:224
	s_waitcnt lgkmcnt(3)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[134:137], v[170:173], v[30:33], v181, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[142:145], v[170:173], v[26:29], v186, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[150:153], v[170:173], v[22:25], v189, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[154:157], v[170:173], v[14:17], v191, v183 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_or_b32_e32 v170, 0xe0, v1
	v_lshlrev_b32_e32 v166, 7, v170
	v_add_u32_e32 v0, v0, v166
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[130:133], v[174:177], v[30:33], v180, v162 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[138:141], v[174:177], v[26:29], v187, v162 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[146:149], v[174:177], v[22:25], v188, v162 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[158:161], v[174:177], v[14:17], v185, v162 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[172:175], v0
	ds_read_u8 v0, v182 offset:1248
	v_add_u32_e32 v162, v179, v166
	s_waitcnt lgkmcnt(1)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[134:137], v[172:175], v[6:9], v181, v165 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	ds_read_b128 v[134:137], v162
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[142:145], v[172:175], v[18:21], v186, v165 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[150:153], v[172:175], v[10:13], v189, v165 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[154:157], v[172:175], v[2:5], v191, v165 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[130:133], v[134:137], v[6:9], v180, v0 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[138:141], v[134:137], v[18:21], v187, v0 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[146:149], v[134:137], v[10:13], v188, v0 op_sel_hi:[0,0,0] cbsz:4 blgp:4
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[158:161], v[134:137], v[2:5], v185, v0 op_sel_hi:[0,0,0] cbsz:4 blgp:4
.LBB0_8:
	s_ashr_i32 s1, s13, 31
	s_mul_hi_i32 s3, s13, s21
	s_mul_i32 s2, s13, s21
	v_and_or_b32 v154, v163, 28, v164
	v_mov_b32_e32 v131, s1
	v_mov_b32_e32 v133, s1
	v_mov_b32_e32 v135, s1
	v_mov_b32_e32 v137, s1
	v_mov_b32_e32 v139, s1
	v_mov_b32_e32 v141, s1
	v_mov_b32_e32 v143, s1
	v_mov_b32_e32 v145, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b32 s4, s21, 6
	s_lshl_b64 s[2:3], s[2:3], 1
	v_or_b32_e32 v155, 0xc0, v154
	v_or_b32_e32 v156, 0x80, v154
	v_or_b32_e32 v157, 64, v154
	s_add_u32 s2, s6, s2
	v_or_b32_e32 v146, s0, v154
	v_mov_b32_e32 v147, s1
	v_or_b32_e32 v148, s0, v157
	v_mov_b32_e32 v149, s1
	v_or_b32_e32 v150, s0, v156
	v_mov_b32_e32 v151, s1
	v_or_b32_e32 v152, s0, v155
	v_mov_b32_e32 v153, s1
	s_addc_u32 s3, s7, s3
	s_lshl_b64 s[0:1], s[0:1], 1
	s_add_u32 s24, s2, s0
	v_or_b32_e32 v130, s13, v1
	v_or_b32_e32 v132, s13, v167
	v_or_b32_e32 v136, s13, v168
	v_or_b32_e32 v140, s13, v169
	v_or_b32_e32 v144, s13, v170
	v_mul_lo_u32 v158, s21, v1
	s_addc_u32 s25, s3, s1
	s_ashr_i32 s13, s12, 31
	s_ashr_i32 s27, s26, 31
	v_or_b32_e32 v134, 64, v130
	v_or_b32_e32 v138, 0x80, v130
	v_or_b32_e32 v142, 0xc0, v130
	v_add_u32_e32 v160, s4, v158
	v_cmp_gt_i64_e64 s[22:23], s[12:13], v[130:131]
	v_cmp_gt_i64_e64 s[6:7], s[26:27], v[146:147]
	v_mul_lo_u32 v159, s21, v167
	v_mul_lo_u32 v161, s21, v168
	v_add_u32_e32 v162, s4, v160
	v_mul_lo_u32 v163, s21, v169
	v_mul_lo_u32 v165, s21, v170
	v_cmp_gt_i64_e64 s[20:21], s[12:13], v[132:133]
	v_cmp_gt_i64_e64 s[18:19], s[12:13], v[134:135]
	v_cmp_gt_i64_e64 s[16:17], s[12:13], v[136:137]
	v_cmp_gt_i64_e64 s[14:15], s[12:13], v[138:139]
	v_cmp_gt_i64_e64 s[10:11], s[12:13], v[140:141]
	v_cmp_gt_i64_e64 s[8:9], s[12:13], v[142:143]
	v_cmp_gt_i64_e32 vcc, s[12:13], v[144:145]
	v_cvt_pk_bf16_f32 v0, v122, v123
	v_add_lshl_u32 v122, v158, v154, 1
	v_bfrev_b32_e32 v123, 1
	s_and_b64 s[12:13], s[22:23], s[6:7]
	v_add_u32_e32 v164, s4, v162
	v_cmp_gt_i64_e64 s[4:5], s[26:27], v[148:149]
	v_cmp_gt_i64_e64 s[2:3], s[26:27], v[150:151]
	v_cmp_gt_i64_e64 s[0:1], s[26:27], v[152:153]
	s_and_b32 s25, s25, 0xffff
	s_mov_b32 s27, 0x27000
	s_mov_b32 s26, 0x7ffffffe
	v_cvt_pk_bf16_f32 v1, v124, v125
	v_cndmask_b32_e64 v122, v123, v122, s[12:13]
	buffer_store_dwordx2 v[0:1], v122, s[24:27], 0 offen
	v_add_lshl_u32 v122, v158, v157, 1
	s_and_b64 s[12:13], s[22:23], s[4:5]
	v_cvt_pk_bf16_f32 v1, v128, v129
	v_cvt_pk_bf16_f32 v0, v126, v127
	v_cndmask_b32_e64 v122, v123, v122, s[12:13]
	buffer_store_dwordx2 v[0:1], v122, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v118, v119
	v_add_lshl_u32 v118, v158, v156, 1
	s_and_b64 s[12:13], s[22:23], s[2:3]
	v_cvt_pk_bf16_f32 v1, v120, v121
	v_cndmask_b32_e64 v118, v123, v118, s[12:13]
	buffer_store_dwordx2 v[0:1], v118, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v114, v115
	v_add_lshl_u32 v114, v158, v155, 1
	s_and_b64 s[12:13], s[22:23], s[0:1]
	v_cvt_pk_bf16_f32 v1, v116, v117
	v_cndmask_b32_e64 v114, v123, v114, s[12:13]
	buffer_store_dwordx2 v[0:1], v114, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v110, v111
	v_add_lshl_u32 v110, v159, v154, 1
	s_and_b64 s[12:13], s[20:21], s[6:7]
	v_cvt_pk_bf16_f32 v1, v112, v113
	v_cndmask_b32_e64 v110, v123, v110, s[12:13]
	buffer_store_dwordx2 v[0:1], v110, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v106, v107
	v_add_lshl_u32 v106, v159, v157, 1
	s_and_b64 s[12:13], s[20:21], s[4:5]
	v_cvt_pk_bf16_f32 v1, v108, v109
	v_cndmask_b32_e64 v106, v123, v106, s[12:13]
	buffer_store_dwordx2 v[0:1], v106, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v102, v103
	v_add_lshl_u32 v102, v159, v156, 1
	s_and_b64 s[12:13], s[20:21], s[2:3]
	v_cvt_pk_bf16_f32 v1, v104, v105
	v_cndmask_b32_e64 v102, v123, v102, s[12:13]
	buffer_store_dwordx2 v[0:1], v102, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v98, v99
	v_add_lshl_u32 v98, v159, v155, 1
	s_and_b64 s[12:13], s[20:21], s[0:1]
	v_cvt_pk_bf16_f32 v1, v100, v101
	v_cndmask_b32_e64 v98, v123, v98, s[12:13]
	buffer_store_dwordx2 v[0:1], v98, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v94, v95
	v_add_lshl_u32 v94, v160, v154, 1
	s_and_b64 s[12:13], s[18:19], s[6:7]
	v_cvt_pk_bf16_f32 v1, v96, v97
	v_cndmask_b32_e64 v94, v123, v94, s[12:13]
	buffer_store_dwordx2 v[0:1], v94, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v90, v91
	v_add_lshl_u32 v90, v160, v157, 1
	s_and_b64 s[12:13], s[18:19], s[4:5]
	v_cvt_pk_bf16_f32 v1, v92, v93
	v_cndmask_b32_e64 v90, v123, v90, s[12:13]
	buffer_store_dwordx2 v[0:1], v90, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v86, v87
	v_add_lshl_u32 v86, v160, v156, 1
	s_and_b64 s[12:13], s[18:19], s[2:3]
	v_cvt_pk_bf16_f32 v1, v88, v89
	v_cndmask_b32_e64 v86, v123, v86, s[12:13]
	buffer_store_dwordx2 v[0:1], v86, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v82, v83
	v_add_lshl_u32 v82, v160, v155, 1
	s_and_b64 s[12:13], s[18:19], s[0:1]
	v_cvt_pk_bf16_f32 v1, v84, v85
	v_cndmask_b32_e64 v82, v123, v82, s[12:13]
	buffer_store_dwordx2 v[0:1], v82, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v78, v79
	v_add_lshl_u32 v78, v161, v154, 1
	s_and_b64 s[12:13], s[16:17], s[6:7]
	v_cvt_pk_bf16_f32 v1, v80, v81
	v_cndmask_b32_e64 v78, v123, v78, s[12:13]
	buffer_store_dwordx2 v[0:1], v78, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v74, v75
	v_add_lshl_u32 v74, v161, v157, 1
	s_and_b64 s[12:13], s[16:17], s[4:5]
	v_cvt_pk_bf16_f32 v1, v76, v77
	v_cndmask_b32_e64 v74, v123, v74, s[12:13]
	buffer_store_dwordx2 v[0:1], v74, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v70, v71
	v_add_lshl_u32 v70, v161, v156, 1
	s_and_b64 s[12:13], s[16:17], s[2:3]
	v_cvt_pk_bf16_f32 v1, v72, v73
	v_cndmask_b32_e64 v70, v123, v70, s[12:13]
	buffer_store_dwordx2 v[0:1], v70, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v66, v67
	v_add_lshl_u32 v66, v161, v155, 1
	s_and_b64 s[12:13], s[16:17], s[0:1]
	v_cvt_pk_bf16_f32 v1, v68, v69
	v_cndmask_b32_e64 v66, v123, v66, s[12:13]
	buffer_store_dwordx2 v[0:1], v66, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v62, v63
	v_add_lshl_u32 v62, v162, v154, 1
	s_and_b64 s[12:13], s[14:15], s[6:7]
	v_cvt_pk_bf16_f32 v1, v64, v65
	v_cndmask_b32_e64 v62, v123, v62, s[12:13]
	buffer_store_dwordx2 v[0:1], v62, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v58, v59
	v_add_lshl_u32 v58, v162, v157, 1
	s_and_b64 s[12:13], s[14:15], s[4:5]
	v_cvt_pk_bf16_f32 v1, v60, v61
	v_cndmask_b32_e64 v58, v123, v58, s[12:13]
	buffer_store_dwordx2 v[0:1], v58, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v54, v55
	v_add_lshl_u32 v54, v162, v156, 1
	s_and_b64 s[12:13], s[14:15], s[2:3]
	v_cvt_pk_bf16_f32 v1, v56, v57
	v_cndmask_b32_e64 v54, v123, v54, s[12:13]
	buffer_store_dwordx2 v[0:1], v54, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v50, v51
	v_add_lshl_u32 v50, v162, v155, 1
	s_and_b64 s[12:13], s[14:15], s[0:1]
	v_cvt_pk_bf16_f32 v1, v52, v53
	v_cndmask_b32_e64 v50, v123, v50, s[12:13]
	buffer_store_dwordx2 v[0:1], v50, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v46, v47
	v_add_lshl_u32 v46, v163, v154, 1
	s_and_b64 s[12:13], s[10:11], s[6:7]
	v_cvt_pk_bf16_f32 v1, v48, v49
	v_cndmask_b32_e64 v46, v123, v46, s[12:13]
	buffer_store_dwordx2 v[0:1], v46, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v42, v43
	v_add_lshl_u32 v42, v163, v157, 1
	s_and_b64 s[12:13], s[10:11], s[4:5]
	v_cvt_pk_bf16_f32 v1, v44, v45
	v_cndmask_b32_e64 v42, v123, v42, s[12:13]
	buffer_store_dwordx2 v[0:1], v42, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v38, v39
	v_add_lshl_u32 v38, v163, v156, 1
	s_and_b64 s[12:13], s[10:11], s[2:3]
	v_cvt_pk_bf16_f32 v1, v40, v41
	v_cndmask_b32_e64 v38, v123, v38, s[12:13]
	buffer_store_dwordx2 v[0:1], v38, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v34, v35
	v_add_lshl_u32 v34, v163, v155, 1
	s_and_b64 s[10:11], s[10:11], s[0:1]
	v_cvt_pk_bf16_f32 v1, v36, v37
	v_cndmask_b32_e64 v34, v123, v34, s[10:11]
	buffer_store_dwordx2 v[0:1], v34, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v30, v31
	v_add_lshl_u32 v30, v164, v154, 1
	s_and_b64 s[10:11], s[8:9], s[6:7]
	v_cvt_pk_bf16_f32 v1, v32, v33
	v_cndmask_b32_e64 v30, v123, v30, s[10:11]
	buffer_store_dwordx2 v[0:1], v30, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v26, v27
	v_add_lshl_u32 v26, v164, v157, 1
	s_and_b64 s[10:11], s[8:9], s[4:5]
	v_cvt_pk_bf16_f32 v1, v28, v29
	v_cndmask_b32_e64 v26, v123, v26, s[10:11]
	buffer_store_dwordx2 v[0:1], v26, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v22, v23
	v_add_lshl_u32 v22, v164, v156, 1
	s_and_b64 s[10:11], s[8:9], s[2:3]
	v_cvt_pk_bf16_f32 v1, v24, v25
	v_cndmask_b32_e64 v22, v123, v22, s[10:11]
	buffer_store_dwordx2 v[0:1], v22, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v14, v15
	v_add_lshl_u32 v14, v164, v155, 1
	s_and_b64 s[8:9], s[8:9], s[0:1]
	v_cvt_pk_bf16_f32 v1, v16, v17
	v_cndmask_b32_e64 v14, v123, v14, s[8:9]
	buffer_store_dwordx2 v[0:1], v14, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v6, v7
	v_add_lshl_u32 v6, v165, v154, 1
	s_and_b64 s[6:7], vcc, s[6:7]
	v_cvt_pk_bf16_f32 v1, v8, v9
	v_cndmask_b32_e64 v6, v123, v6, s[6:7]
	buffer_store_dwordx2 v[0:1], v6, s[24:27], 0 offen
	v_add_lshl_u32 v6, v165, v157, 1
	s_and_b64 s[4:5], vcc, s[4:5]
	v_cvt_pk_bf16_f32 v1, v20, v21
	v_cvt_pk_bf16_f32 v0, v18, v19
	v_cndmask_b32_e64 v6, v123, v6, s[4:5]
	buffer_store_dwordx2 v[0:1], v6, s[24:27], 0 offen
	v_add_lshl_u32 v6, v165, v156, 1
	s_and_b64 s[2:3], vcc, s[2:3]
	v_cvt_pk_bf16_f32 v1, v12, v13
	v_cvt_pk_bf16_f32 v0, v10, v11
	v_cndmask_b32_e64 v6, v123, v6, s[2:3]
	buffer_store_dwordx2 v[0:1], v6, s[24:27], 0 offen
	v_cvt_pk_bf16_f32 v0, v2, v3
	v_add_lshl_u32 v2, v165, v155, 1
	s_and_b64 vcc, vcc, s[0:1]
	v_cvt_pk_bf16_f32 v1, v4, v5
	v_cndmask_b32_e32 v2, v123, v2, vcc
	buffer_store_dwordx2 v[0:1], v2, s[24:27], 0 offen
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _gemm_afp4_wfp4_kernel
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 80
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
		.amdhsa_next_free_vgpr 247
		.amdhsa_next_free_sgpr 45
		.amdhsa_accum_offset 248
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
	.set _gemm_afp4_wfp4_kernel.num_vgpr, 247
	.set _gemm_afp4_wfp4_kernel.num_agpr, 0
	.set _gemm_afp4_wfp4_kernel.numbered_sgpr, 45
	.set _gemm_afp4_wfp4_kernel.private_seg_size, 0
	.set _gemm_afp4_wfp4_kernel.uses_vcc, 1
	.set _gemm_afp4_wfp4_kernel.uses_flat_scratch, 0
	.set _gemm_afp4_wfp4_kernel.has_dyn_sized_stack, 0
	.set _gemm_afp4_wfp4_kernel.has_recursion, 0
	.set _gemm_afp4_wfp4_kernel.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9876
; TotalNumSgprs: 51
; NumVgprs: 247
; NumAgprs: 0
; TotalNumVgprs: 247
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 6
; VGPRBlocks: 30
; NumSGPRsForWavesPerEU: 51
; NumVGPRsForWavesPerEU: 247
; AccumOffset: 248
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 16
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 61
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
	.byte	1                               ; Abbrev [1] 0xb:0x70 DW_TAG_compile_unit
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
	.byte	3                               ; Abbrev [3] 0x30:0x4a DW_TAG_subprogram
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
	.byte	5                               ; Abbrev [5] 0x61:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	62                              ; DW_AT_call_line
	.byte	27                              ; DW_AT_call_column
	.byte	5                               ; Abbrev [5] 0x6d:0xc DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	89                              ; DW_AT_call_line
	.byte	33                              ; DW_AT_call_column
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
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp3-.Lfunc_begin0
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp5-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp7-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp18-.Lfunc_begin0
	.quad	.Ltmp19-.Lfunc_begin0
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
      - .address_space:  global
        .offset:         72
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 80
    .max_flat_workgroup_size: 512
    .name:           _gemm_afp4_wfp4_kernel
    .private_segment_fixed_size: 0
    .sgpr_count:     51
    .sgpr_spill_count: 0
    .symbol:         _gemm_afp4_wfp4_kernel.kd
    .uses_dynamic_stack: false
    .vgpr_count:     247
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
