// SPDX-License-Identifier: MIT
// Copyright (c) 2018-2025, Advanced Micro Devices, Inc. All rights reserved.
// clang-format off

// define the CK_TILE_** macro before include this file to change kernel variation
// we will undef everything defined in this file, so it's safe

// #ifndef CK_TILE_FMLA_UK_MFMA
// #define CK_TILE_FMLA_UK_MFMA CK_TILE_FMLA_UK_MFMA_BF16
// #endif
// 
// #if CK_TILE_FMLA_UK_MFMA == CK_TILE_FMLA_UK_MFMA_BF16
// #define _UK_MFMA_ "v_mfma_f32_16x16x16_bf16"
// #elif CK_TILE_FMLA_UK_MFMA == CK_TILE_FMLA_UK_MFMA_FP16
// #define _UK_MFMA_ "v_mfma_f32_16x16x16_f16"
// #endif

";-------------------------------------------------------------\n"
"   s_barrier                                            \n"   \
"   v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"   \
"   v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"   \
"   v_add_u32     v18, v18, v1                           \n"   \
"   v_add_u32     v19, v19, v1                           \n"   \
"   s_mov_b32     m0, s34                                \n"   \
"   ds_read_b128  acc[144:147], v4                       \n"   \
"   ds_read_b128  acc[148:151], v4 offset:64             \n"   \
"   ds_read_b128  acc[152:155], v4 offset:256            \n"   \
"   ds_read_b128  acc[156:159], v4 offset:320            \n"   \
"   ds_read_b128  acc[160:163], v4 offset:512            \n"   \
"   ds_read_b128  acc[164:167], v4 offset:576            \n"   \
"   ds_read_b128  acc[168:171], v4 offset:768            \n"   \
"   ds_read_b128  acc[172:175], v4 offset:832            \n"   \
"   ds_read_b128  acc[176:179], v4 offset:1024           \n"   \
"   ds_read_b128  acc[180:183], v4 offset:1088           \n"   \
"   ds_read_b128  acc[184:187], v4 offset:1280           \n"   \
"   ds_read_b128  acc[188:191], v4 offset:1344           \n"   \
"   ds_read_b128  acc[192:195], v4 offset:1536           \n"   \
"   ds_read_b128  acc[196:199], v4 offset:1600           \n"   \
"   ds_read_b128  acc[200:203], v4 offset:1792           \n"   \
"   ds_read_b128  acc[204:207], v4 offset:1856           \n"   \
"   ds_read_b128  acc[208:211], v4 offset:2048           \n"   \
"   ds_read_b128  acc[212:215], v4 offset:2112           \n"   \
"   ds_read_b64   v[20:21], v5                           \n"   \
"   ds_read_b64   v[22:23], v5 offset:4640               \n"   \
"   ds_read_b64   v[24:25], v5 offset:9280               \n"   \
"   ds_read_b64   v[26:27], v5 offset:13920              \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   ds_write_b128  v6, v[168:171] offset:37120           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   ds_write_b128  v6, v[168:171] offset:38144           \n"   \
"   ds_read_b64   v[20:21], v5 offset:1024               \n"   \
"   ds_read_b64   v[22:23], v5 offset:5664               \n"   \
"   ds_read_b64   v[24:25], v5 offset:10304              \n"   \
"   ds_read_b64   v[26:27], v5 offset:14944              \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_cmp_lt_u32  s71, 1                                 \n"   \
"   s_cbranch_scc1  label_0DEC                           \n"   \
"   s_cmp_lt_i32  s7, 2                                  \n"   \
"   s_cbranch_scc0  label_0921                           \n"   \
" label_0455: \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
";------------------------------------- gemm_qk---------- n"\
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], [%[q_reg_0], %[q_reg_1]], 0\n"   \
"   ds_read_b128  acc[176:179], v4 offset:1024           \n"   \
"   ds_read_b128  acc[180:183], v4 offset:1088           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], [%[q_reg_2], %[q_reg_3]], v[32:35]\n"   \
"   buffer_load_dword  v10, v8, s[24:27], 0 offen        \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], [%[q_reg_4], %[q_reg_5]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], [%[q_reg_6], %[q_reg_7]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], [%[q_reg_8], %[q_reg_9]], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:1280           \n"   \
"   ds_read_b128  acc[188:191], v4 offset:1344           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], [%[q_reg_10], %[q_reg_11]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], [%[q_reg_12], %[q_reg_13]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], [%[q_reg_14], %[q_reg_15]], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], [%[q_reg_16], %[q_reg_17]], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:1536           \n"   \
"   ds_read_b128  acc[196:199], v4 offset:1600           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], [%[q_reg_18], %[q_reg_19]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], [%[q_reg_20], %[q_reg_21]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], [%[q_reg_22], %[q_reg_23]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], [%[q_reg_24], %[q_reg_25]], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:1792           \n"   \
"   ds_read_b128  acc[204:207], v4 offset:1856           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], [%[q_reg_26], %[q_reg_27]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], [%[q_reg_28], %[q_reg_29]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], [%[q_reg_30], %[q_reg_31]], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], [%[q_reg_32], %[q_reg_33]], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:2048           \n"   \
"   ds_read_b128  acc[212:215], v4 offset:2112           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], [%[q_reg_34], %[q_reg_35]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], [%[q_reg_36], %[q_reg_37]], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], [%[q_reg_38], %[q_reg_39]], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0, s35                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], [%[q_reg_40], %[q_reg_41]], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], [%[q_reg_42], %[q_reg_43]], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0x00000080, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], [%[q_reg_44], %[q_reg_45]], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], [%[q_reg_46], %[q_reg_47]], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000080, s35                    \n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], [%[q_reg_48], %[q_reg_49]], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], [%[q_reg_50], %[q_reg_51]], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000100, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], [%[q_reg_52], %[q_reg_53]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], [%[q_reg_54], %[q_reg_55]], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000100, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], [%[q_reg_56], %[q_reg_57]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], [%[q_reg_58], %[q_reg_59]], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000180, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], [%[q_reg_60], %[q_reg_61]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], [%[q_reg_62], %[q_reg_63]], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000180, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], [%[q_reg_64], %[q_reg_65]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], [%[q_reg_66], %[q_reg_67]], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000200, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], [%[q_reg_68], %[q_reg_69]], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], [%[q_reg_70], %[q_reg_71]], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000200, s35                    \n"   \
"   v_add_u32     v8, s73, v8                            \n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_0516                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_0516: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000280, s34                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000280, s35                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000300, s34                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000300, s35                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000380, s34                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000380, s35                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000400, s34                    \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000400, s35                    \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000480, s34                    \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mul_u32_u24  v18, v11, v9 row_newbcast:0           \n"   \
"   v_mul_u32_u24  v19, v11, v9 row_newbcast:8           \n"   \
"   v_add_u32     v18, v18, v1                           \n"   \
"   v_add_u32     v19, v19, v1                           \n"   \
"   s_mov_b32     m0, s36                                \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   ds_read_b64   v[20:21], v5 offset:18560              \n"   \
"   ds_read_b64   v[22:23], v5 offset:23200              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   ds_read_b64   v[24:25], v5 offset:27840              \n"   \
"   ds_read_b64   v[26:27], v5 offset:32480              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   ds_read_b128  acc[144:147], v4 offset:18560          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   ds_read_b128  acc[148:151], v4 offset:18624          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   ds_read_b128  acc[152:155], v4 offset:18816          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   ds_read_b128  acc[156:159], v4 offset:18880          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   ds_read_b128  acc[160:163], v4 offset:19072          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   ds_read_b128  acc[164:167], v4 offset:19136          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   ds_read_b128  acc[168:171], v4 offset:19328          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   ds_read_b128  acc[172:175], v4 offset:19392          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   s_waitcnt     lgkmcnt(8)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   ds_write_b128  v6, v[168:171] offset:37120           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   ds_write_b128  v6, v[168:171] offset:38144           \n"   \
"   ds_read_b64   v[20:21], v5 offset:19584              \n"   \
"   ds_read_b64   v[22:23], v5 offset:24224              \n"   \
"   ds_read_b64   v[24:25], v5 offset:28864              \n"   \
"   ds_read_b64   v[26:27], v5 offset:33504              \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_addk_i32    s70, 0x0001                            \n"   \
"   s_cmp_lt_i32  s70, s71                               \n"   \
"   s_cbranch_scc0  label_091E                           \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"   \
"   ds_read_b128  acc[176:179], v4 offset:19584          \n"   \
"   ds_read_b128  acc[180:183], v4 offset:19648          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"   \
"   buffer_load_dword  v11, v8, s[24:27], 0 offen        \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:19840          \n"   \
"   ds_read_b128  acc[188:191], v4 offset:19904          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:20096          \n"   \
"   ds_read_b128  acc[196:199], v4 offset:20160          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:20352          \n"   \
"   ds_read_b128  acc[204:207], v4 offset:20416          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:20608          \n"   \
"   ds_read_b128  acc[212:215], v4 offset:20672          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0, s37                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0x00000080, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000080, s37                    \n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000100, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000100, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000180, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000180, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000200, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000200, s37                    \n"   \
"   v_add_u32     v8, s73, v8                            \n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_077A                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_077A: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000280, s36                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000280, s37                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000300, s36                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000300, s37                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000380, s36                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000380, s37                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000400, s36                    \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000400, s37                    \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000480, s36                    \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"   \
"   v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"   \
"   v_add_u32     v18, v18, v1                           \n"   \
"   v_add_u32     v19, v19, v1                           \n"   \
"   s_mov_b32     m0, s34                                \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   ds_read_b64   v[20:21], v5                           \n"   \
"   ds_read_b64   v[22:23], v5 offset:4640               \n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   ds_read_b64   v[24:25], v5 offset:9280               \n"   \
"   ds_read_b64   v[26:27], v5 offset:13920              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   ds_read_b128  acc[144:147], v4                       \n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   ds_read_b128  acc[148:151], v4 offset:64             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   ds_read_b128  acc[152:155], v4 offset:256            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   ds_read_b128  acc[156:159], v4 offset:320            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   ds_read_b128  acc[160:163], v4 offset:512            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   ds_read_b128  acc[164:167], v4 offset:576            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   ds_read_b128  acc[168:171], v4 offset:768            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   ds_read_b128  acc[172:175], v4 offset:832            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   s_waitcnt     lgkmcnt(8)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   ds_write_b128  v6, v[168:171] offset:37120           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   ds_write_b128  v6, v[168:171] offset:38144           \n"   \
"   ds_read_b64   v[20:21], v5 offset:1024               \n"   \
"   ds_read_b64   v[22:23], v5 offset:5664               \n"   \
"   ds_read_b64   v[24:25], v5 offset:10304              \n"   \
"   ds_read_b64   v[26:27], v5 offset:14944              \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_addk_i32    s70, 0x0001                            \n"   \
"   s_cmp_lt_i32  s70, s71                               \n"   \
"   s_cbranch_scc0  label_091E                           \n"   \
"   s_branch      label_0455                             \n"   \
" label_091E: \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_branch      label_0DEA                             \n"   \
" label_0921: \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"   \
"   buffer_load_dword  v10, v8, s[24:27], 0 offen        \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"   \
"   ds_read_b128  acc[176:179], v4 offset:1024           \n"   \
"   ds_read_b128  acc[180:183], v4 offset:1088           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:1280           \n"   \
"   ds_read_b128  acc[188:191], v4 offset:1344           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:1536           \n"   \
"   ds_read_b128  acc[196:199], v4 offset:1600           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:1792           \n"   \
"   ds_read_b128  acc[204:207], v4 offset:1856           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:2048           \n"   \
"   ds_read_b128  acc[212:215], v4 offset:2112           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0, s35                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0x00000080, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000080, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000100, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000100, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000180, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000180, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000200, s34                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000200, s35                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"   \
"   v_add_u32     v8, s73, v8                            \n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_09E2                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_09E2: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000280, s34                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000280, s35                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000300, s34                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000300, s35                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000380, s34                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000380, s35                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000400, s34                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000400, s35                    \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000480, s34                    \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mul_u32_u24  v18, v11, v9 row_newbcast:0           \n"   \
"   v_mul_u32_u24  v19, v11, v9 row_newbcast:8           \n"   \
"   v_add_u32     v18, v18, v1                           \n"   \
"   v_add_u32     v19, v19, v1                           \n"   \
"   s_mov_b32     m0, s36                                \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   ds_read_b64   v[20:21], v5 offset:18560              \n"   \
"   ds_read_b64   v[22:23], v5 offset:23200              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   ds_read_b64   v[24:25], v5 offset:27840              \n"   \
"   ds_read_b64   v[26:27], v5 offset:32480              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   ds_read_b128  acc[144:147], v4 offset:18560          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   ds_read_b128  acc[148:151], v4 offset:18624          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   ds_read_b128  acc[152:155], v4 offset:18816          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   ds_read_b128  acc[156:159], v4 offset:18880          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   ds_read_b128  acc[160:163], v4 offset:19072          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   ds_read_b128  acc[164:167], v4 offset:19136          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   ds_read_b128  acc[168:171], v4 offset:19328          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   ds_read_b128  acc[172:175], v4 offset:19392          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   s_waitcnt     lgkmcnt(8)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   ds_write_b128  v6, v[168:171] offset:37120           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   ds_write_b128  v6, v[168:171] offset:38144           \n"   \
"   ds_read_b64   v[20:21], v5 offset:19584              \n"   \
"   ds_read_b64   v[22:23], v5 offset:24224              \n"   \
"   ds_read_b64   v[24:25], v5 offset:28864              \n"   \
"   ds_read_b64   v[26:27], v5 offset:33504              \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_addk_i32    s70, 0x0001                            \n"   \
"   s_cmp_lt_i32  s70, s71                               \n"   \
"   s_cbranch_scc0  label_091E                           \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"   \
"   buffer_load_dword  v11, v8, s[24:27], 0 offen        \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"   \
"   ds_read_b128  acc[176:179], v4 offset:19584          \n"   \
"   ds_read_b128  acc[180:183], v4 offset:19648          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:19840          \n"   \
"   ds_read_b128  acc[188:191], v4 offset:19904          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:20096          \n"   \
"   ds_read_b128  acc[196:199], v4 offset:20160          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:20352          \n"   \
"   ds_read_b128  acc[204:207], v4 offset:20416          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:20608          \n"   \
"   ds_read_b128  acc[212:215], v4 offset:20672          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0, s37                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen lds    \n"   \
"   s_add_u32     m0, 0x00000080, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000080, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:128 lds\n"   \
"   s_add_u32     m0, 0x00000100, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000100, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:256 lds\n"   \
"   s_add_u32     m0, 0x00000180, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000180, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:384 lds\n"   \
"   s_add_u32     m0, 0x00000200, s36                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000200, s37                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"   \
"   v_add_u32     v8, s73, v8                            \n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_0C46                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_0C46: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:512 lds\n"   \
"   s_add_u32     m0, 0x00000280, s36                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000280, s37                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:640 lds\n"   \
"   s_add_u32     m0, 0x00000300, s36                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000300, s37                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:768 lds\n"   \
"   s_add_u32     m0, 0x00000380, s36                    \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000380, s37                    \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:896 lds\n"   \
"   s_add_u32     m0, 0x00000400, s36                    \n"   \
"   buffer_load_dword   v18, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000400, s37                    \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   buffer_load_dword   v19, s[20:23], 0 offen offset:1024 lds\n"   \
"   s_add_u32     m0, 0x00000480, s36                    \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"   \
"   v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"   \
"   v_add_u32     v18, v18, v1                           \n"   \
"   v_add_u32     v19, v19, v1                           \n"   \
"   s_mov_b32     m0, s34                                \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   ds_read_b64   v[20:21], v5                           \n"   \
"   ds_read_b64   v[22:23], v5 offset:4640               \n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   ds_read_b64   v[24:25], v5 offset:9280               \n"   \
"   ds_read_b64   v[26:27], v5 offset:13920              \n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   ds_read_b128  acc[144:147], v4                       \n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   ds_read_b128  acc[148:151], v4 offset:64             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   ds_read_b128  acc[152:155], v4 offset:256            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   ds_read_b128  acc[156:159], v4 offset:320            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   ds_read_b128  acc[160:163], v4 offset:512            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   ds_read_b128  acc[164:167], v4 offset:576            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   ds_read_b128  acc[168:171], v4 offset:768            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   ds_read_b128  acc[172:175], v4 offset:832            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   s_waitcnt     lgkmcnt(8)                             \n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   ds_write_b128  v6, v[168:171] offset:37120           \n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   ds_write_b128  v6, v[168:171] offset:38144           \n"   \
"   ds_read_b64   v[20:21], v5 offset:1024               \n"   \
"   ds_read_b64   v[22:23], v5 offset:5664               \n"   \
"   ds_read_b64   v[24:25], v5 offset:10304              \n"   \
"   ds_read_b64   v[26:27], v5 offset:14944              \n"   \
"   s_nop         0x0000                                 \n"   \
"   s_addk_i32    s70, 0x0001                            \n"   \
"   s_cmp_lt_i32  s70, s71                               \n"   \
"   s_cbranch_scc0  label_091E                           \n"   \
"   s_branch      label_0921                             \n"   \
" label_0DEA: \n"   \
"   s_cmp_eq_i32  s48, 0                                 \n"   \
"   s_cbranch_scc1  label_11EB                           \n"   \
" label_0DEC: \n"   \
"   s_and_b32     s56, s71, 1                            \n"   \
"   s_cmp_eq_i32  s56, 1                                 \n"   \
"   s_cbranch_scc1  label_0FED                           \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"   \
"   ds_read_b128  acc[176:179], v4 offset:1024           \n"   \
"   ds_read_b128  acc[180:183], v4 offset:1088           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:1280           \n"   \
"   ds_read_b128  acc[188:191], v4 offset:1344           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:1536           \n"   \
"   ds_read_b128  acc[196:199], v4 offset:1600           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:1792           \n"   \
"   ds_read_b128  acc[204:207], v4 offset:1856           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:2048           \n"   \
"   ds_read_b128  acc[212:215], v4 offset:2112           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_0E8A                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_0E8A: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_and_b32     s56, s48, 0x000000ff                   \n"   \
"   v_mov_b32     v24, s56                               \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_lt_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   s_nop         0x0008                                 \n"   \
"   s_branch      label_11EB                             \n"   \
" label_0FED: \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"   \
"   ds_read_b128  acc[176:179], v4 offset:19584          \n"   \
"   ds_read_b128  acc[180:183], v4 offset:19648          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"   \
"   ds_read_b128  acc[184:187], v4 offset:19840          \n"   \
"   ds_read_b128  acc[188:191], v4 offset:19904          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"   \
"   ds_read_b128  acc[192:195], v4 offset:20096          \n"   \
"   ds_read_b128  acc[196:199], v4 offset:20160          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"   \
"   ds_read_b128  acc[200:203], v4 offset:20352          \n"   \
"   ds_read_b128  acc[204:207], v4 offset:20416          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"   \
"   ds_read_b128  acc[208:211], v4 offset:20608          \n"   \
"   ds_read_b128  acc[212:215], v4 offset:20672          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"   \
"   v_perm_b32    v168, v22, v20, s53                    \n"   \
"   v_perm_b32    v170, v22, v20, s52                    \n"   \
"   v_perm_b32    v169, v26, v24, s53                    \n"   \
"   v_perm_b32    v171, v26, v24, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:45312           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"   \
"   v_perm_b32    v168, v23, v21, s53                    \n"   \
"   v_perm_b32    v170, v23, v21, s52                    \n"   \
"   v_perm_b32    v169, v27, v25, s53                    \n"   \
"   v_perm_b32    v171, v27, v25, s52                    \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"   \
"   s_waitcnt     lgkmcnt(1)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"   \
"   ds_write_b128  v6, v[168:171] offset:46336           \n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"   \
"   s_cmp_le_i32  s83, s82                               \n"   \
"   s_cbranch_scc1  label_1088                           \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_add_u32     s57, s82, 0                            \n"   \
"   v_mov_b32     v24, s57                               \n"   \
"   v_add_u32     v24, s7, v24                           \n"   \
"   s_sub_u32     s56, s83, 15                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v20, s56, v20                          \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_le_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_le_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
" label_1088: \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   s_barrier                                            \n"   \
"   v_mov_b32     v25, 0xff800000                        \n"   \
"   s_and_b32     s56, s48, 0x000000ff                   \n"   \
"   v_mov_b32     v24, s56                               \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 4, v20                           \n"   \
"   v_add_u32     v21, 1, v20                            \n"   \
"   v_add_u32     v22, 2, v20                            \n"   \
"   v_add_u32     v23, 3, v20                            \n"   \
"   v_cmp_lt_u32  s[38:39], v20, v24                     \n"   \
"   v_add_u32     v20, 64, v20                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v32, v25, v32, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v21, v24                     \n"   \
"   v_add_u32     v21, 64, v21                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v33, v25, v33, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v22, v24                     \n"   \
"   v_add_u32     v22, 64, v22                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v34, v25, v34, s[38:39]               \n"   \
"   v_cmp_lt_u32  s[38:39], v23, v24                     \n"   \
"   v_add_u32     v23, 64, v23                           \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_cndmask_b32  v35, v25, v35, s[38:39]               \n"   \
"   v_max3_f32    v24, v32, v33, v32                     \n"   \
"   v_max3_f32    v24, v34, v35, v24                     \n"   \
"   ds_write_b32  v3, v24 offset:53504                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:53504                   \n"   \
"   ds_read_b32   v21, v2 offset:53568                   \n"   \
"   ds_read_b32   v22, v2 offset:53632                   \n"   \
"   ds_read_b32   v23, v2 offset:53696                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_max3_f32    v24, v20, v21, v24                     \n"   \
"   v_max3_f32    v24, v22, v23, v24                     \n"   \
"   ds_read_b128  acc[144:147], v7 offset:37120          \n"   \
"   ds_read_b128  acc[148:151], v7 offset:38144          \n"   \
"   ds_read_b128  acc[152:155], v7 offset:39168          \n"   \
"   ds_read_b128  acc[156:159], v7 offset:40192          \n"   \
"   ds_read_b128  acc[160:163], v7 offset:41216          \n"   \
"   ds_read_b128  acc[164:167], v7 offset:42240          \n"   \
"   ds_read_b128  acc[168:171], v7 offset:43264          \n"   \
"   ds_read_b128  acc[172:175], v7 offset:44288          \n"   \
"   v_mov_b32     v25, 0xff7fffff                        \n"   \
"   v_cmp_eq_u32  s[38:39], v25, v12                     \n"   \
"   v_max_f32     v20, v24, v12                          \n"   \
"   v_sub_f32     v16, v12, v20                          \n"   \
"   v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"   \
"   v_mov_b32     v12, v20                               \n"   \
"   v_mul_f32     v21, s5, v20                           \n"   \
"   v_mul_f32     v16, s5, v16                           \n"   \
"   v_exp_f32     v16, v16                               \n"   \
"   v_fma_f32     v32, v32, s5, -v21                     \n"   \
"   v_fma_f32     v33, v33, s5, -v21                     \n"   \
"   v_fma_f32     v34, v34, s5, -v21                     \n"   \
"   v_fma_f32     v35, v35, s5, -v21                     \n"   \
"   v_exp_f32     v32, v32                               \n"   \
"   v_exp_f32     v33, v33                               \n"   \
"   v_exp_f32     v34, v34                               \n"   \
"   v_exp_f32     v35, v35                               \n"   \
"   v_mul_f32     v14, v16, v14                          \n"   \
"   v_mov_b32     v22, v32                               \n"   \
"   v_add_f32     v22, v33, v22                          \n"   \
"   v_add_f32     v22, v34, v22                          \n"   \
"   v_add_f32     v22, v35, v22                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   v_cmp_u_f32   s[38:39], v32, v32                     \n"   \
"   v_add3_u32    v28, v32, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v33, v33                     \n"   \
"   v_add3_u32    v28, v33, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v32, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v34, v34                     \n"   \
"   v_add3_u32    v28, v34, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v35, v35                     \n"   \
"   v_add3_u32    v28, v35, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v33, v21, v20, s52                     \n"   \
"   s_nop         0x0002                                 \n"   \
"   s_add_u32     s83, s84, s83                          \n"   \
"   s_nop         0x0000                                 \n"   \
"   v_mov_b32     v22, v16                               \n"   \
"   v_mov_b32     v23, v16                               \n"   \
"   v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"   \
"   v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"   \
"   v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"   \
"   v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"   \
"   v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"   \
"   v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"   \
"   v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"   \
"   v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"   \
"   v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"   \
"   v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"   \
"   v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"   \
"   v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"   \
"   v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"   \
"   v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"   \
"   v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"   \
"   v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"   \
"   v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"   \
"   v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"   \
"   v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"   \
"   v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"   \
"   v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"   \
"   v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"   \
"   v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"   \
"   v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"   \
"   v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"   \
"   v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"   \
"   v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"   \
"   v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"   \
"   v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"   \
"   v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"   \
"   v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"   \
"   v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"   \
"   v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"   \
"   v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"   \
"   v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"   \
"   v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"   \
"   v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"   \
"   v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"   \
"   v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"   \
"   v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"   \
"   v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"   \
"   v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"   \
"   v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"   \
"   v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"   \
"   v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"   \
"   v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"   \
"   v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"   \
"   v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"   \
"   v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"   \
"   v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"   \
"   v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"   \
"   v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"   \
"   v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"   \
"   v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"   \
"   v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"   \
"   v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"   \
"   v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"   \
"   v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"   \
"   v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"   \
"   v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"   \
"   v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"   \
"   v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"   \
"   v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"   \
"   v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"   \
"   ds_read_b128  acc[176:179], v7 offset:45312          \n"   \
"   ds_read_b128  acc[180:183], v7 offset:46336          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"   \
"   ds_read_b128  acc[184:187], v7 offset:47360          \n"   \
"   ds_read_b128  acc[188:191], v7 offset:48384          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"   \
"   ds_read_b128  acc[192:195], v7 offset:49408          \n"   \
"   ds_read_b128  acc[196:199], v7 offset:50432          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"   \
"   ds_read_b128  acc[200:203], v7 offset:51456          \n"   \
"   ds_read_b128  acc[204:207], v7 offset:52480          \n"   \
"   v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"   \
"   s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"   \
"   s_barrier                                            \n"   \
"   v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"   \
"   v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"   \
"   s_nop         0x0008                                 \n"   \
"   s_branch      label_11EB                             \n"   \
" label_11EB: \n"   \
"   ds_write_b32  v3, v14 offset:55552                   \n"   \
"   ds_write_b32  v3, v15 offset:56576                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   ds_read_b32   v20, v2 offset:55552                   \n"   \
"   ds_read_b32   v21, v2 offset:55616                   \n"   \
"   ds_read_b32   v22, v2 offset:55680                   \n"   \
"   ds_read_b32   v23, v2 offset:55744                   \n"   \
"   ds_read_b32   v24, v2 offset:56576                   \n"   \
"   ds_read_b32   v25, v2 offset:56640                   \n"   \
"   ds_read_b32   v26, v2 offset:56704                   \n"   \
"   ds_read_b32   v27, v2 offset:56768                   \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v14, 0                                 \n"   \
"   v_mov_b32     v15, 0                                 \n"   \
"   v_add_f32     v14, v20, v14                          \n"   \
"   v_add_f32     v15, v24, v15                          \n"   \
"   v_add_f32     v14, v21, v14                          \n"   \
"   v_add_f32     v15, v25, v15                          \n"   \
"   v_add_f32     v14, v22, v14                          \n"   \
"   v_add_f32     v15, v26, v15                          \n"   \
"   v_add_f32     v14, v23, v14                          \n"   \
"   v_add_f32     v15, v27, v15                          \n"   \
"   v_mov_b32     v20, 0                                 \n"   \
"   v_cmp_eq_u32  s[38:39], v20, v14                     \n"   \
"   v_cmp_eq_u32  s[40:41], v20, v15                     \n"   \
"   v_mul_f32     v20, v12, s64                          \n"   \
"   v_mul_f32     v22, v13, s64                          \n"   \
"   v_log_f32     v21, v14                               \n"   \
"   v_log_f32     v23, v15                               \n"   \
"   v_cndmask_b32  v14, v14, 1.0, s[38:39]               \n"   \
"   v_cndmask_b32  v15, v15, 1.0, s[40:41]               \n"   \
"   s_nop         0x0001                                 \n"   \
"   v_rcp_f32     v14, v14                               \n"   \
"   v_rcp_f32     v15, v15                               \n"   \
"   s_nop         0x0001                                 \n"   \
"   v_fma_f32     v24, v21, s63, v20                     \n"   \
"   v_fma_f32     v25, v23, s63, v22                     \n"   \
"   v_mul_f32     v40, v14, v40                          \n"   \
"   v_mul_f32     v41, v14, v41                          \n"   \
"   v_mul_f32     v42, v14, v42                          \n"   \
"   v_mul_f32     v43, v14, v43                          \n"   \
"   v_mul_f32     v44, v14, v44                          \n"   \
"   v_mul_f32     v45, v14, v45                          \n"   \
"   v_mul_f32     v46, v14, v46                          \n"   \
"   v_mul_f32     v47, v14, v47                          \n"   \
"   v_mul_f32     v48, v14, v48                          \n"   \
"   v_mul_f32     v49, v14, v49                          \n"   \
"   v_mul_f32     v50, v14, v50                          \n"   \
"   v_mul_f32     v51, v14, v51                          \n"   \
"   v_mul_f32     v52, v14, v52                          \n"   \
"   v_mul_f32     v53, v14, v53                          \n"   \
"   v_mul_f32     v54, v14, v54                          \n"   \
"   v_mul_f32     v55, v14, v55                          \n"   \
"   v_mul_f32     v56, v14, v56                          \n"   \
"   v_mul_f32     v57, v14, v57                          \n"   \
"   v_mul_f32     v58, v14, v58                          \n"   \
"   v_mul_f32     v59, v14, v59                          \n"   \
"   v_mul_f32     v60, v14, v60                          \n"   \
"   v_mul_f32     v61, v14, v61                          \n"   \
"   v_mul_f32     v62, v14, v62                          \n"   \
"   v_mul_f32     v63, v14, v63                          \n"   \
"   v_mul_f32     v64, v14, v64                          \n"   \
"   v_mul_f32     v65, v14, v65                          \n"   \
"   v_mul_f32     v66, v14, v66                          \n"   \
"   v_mul_f32     v67, v14, v67                          \n"   \
"   v_mul_f32     v68, v14, v68                          \n"   \
"   v_mul_f32     v69, v14, v69                          \n"   \
"   v_mul_f32     v70, v14, v70                          \n"   \
"   v_mul_f32     v71, v14, v71                          \n"   \
"   v_mul_f32     v72, v14, v72                          \n"   \
"   v_mul_f32     v73, v14, v73                          \n"   \
"   v_mul_f32     v74, v14, v74                          \n"   \
"   v_mul_f32     v75, v14, v75                          \n"   \
"   v_mul_f32     v76, v14, v76                          \n"   \
"   v_mul_f32     v77, v14, v77                          \n"   \
"   v_mul_f32     v78, v14, v78                          \n"   \
"   v_mul_f32     v79, v14, v79                          \n"   \
"   v_mul_f32     v80, v14, v80                          \n"   \
"   v_mul_f32     v81, v14, v81                          \n"   \
"   v_mul_f32     v82, v14, v82                          \n"   \
"   v_mul_f32     v83, v14, v83                          \n"   \
"   v_mul_f32     v84, v14, v84                          \n"   \
"   v_mul_f32     v85, v14, v85                          \n"   \
"   v_mul_f32     v86, v14, v86                          \n"   \
"   v_mul_f32     v87, v14, v87                          \n"   \
"   v_mul_f32     v88, v14, v88                          \n"   \
"   v_mul_f32     v89, v14, v89                          \n"   \
"   v_mul_f32     v90, v14, v90                          \n"   \
"   v_mul_f32     v91, v14, v91                          \n"   \
"   v_mul_f32     v92, v14, v92                          \n"   \
"   v_mul_f32     v93, v14, v93                          \n"   \
"   v_mul_f32     v94, v14, v94                          \n"   \
"   v_mul_f32     v95, v14, v95                          \n"   \
"   v_mul_f32     v96, v14, v96                          \n"   \
"   v_mul_f32     v97, v14, v97                          \n"   \
"   v_mul_f32     v98, v14, v98                          \n"   \
"   v_mul_f32     v99, v14, v99                          \n"   \
"   v_mul_f32     v100, v14, v100                        \n"   \
"   v_mul_f32     v101, v14, v101                        \n"   \
"   v_mul_f32     v102, v14, v102                        \n"   \
"   v_mul_f32     v103, v14, v103                        \n"   \
"   v_mul_f32     v104, v14, v104                        \n"   \
"   v_mul_f32     v105, v14, v105                        \n"   \
"   v_mul_f32     v106, v14, v106                        \n"   \
"   v_mul_f32     v107, v14, v107                        \n"   \
"   v_mul_f32     v108, v14, v108                        \n"   \
"   v_mul_f32     v109, v14, v109                        \n"   \
"   v_mul_f32     v110, v14, v110                        \n"   \
"   v_mul_f32     v111, v14, v111                        \n"   \
"   v_mul_f32     v112, v14, v112                        \n"   \
"   v_mul_f32     v113, v14, v113                        \n"   \
"   v_mul_f32     v114, v14, v114                        \n"   \
"   v_mul_f32     v115, v14, v115                        \n"   \
"   v_mul_f32     v116, v14, v116                        \n"   \
"   v_mul_f32     v117, v14, v117                        \n"   \
"   v_mul_f32     v118, v14, v118                        \n"   \
"   v_mul_f32     v119, v14, v119                        \n"   \
"   v_mul_f32     v120, v14, v120                        \n"   \
"   v_mul_f32     v121, v14, v121                        \n"   \
"   v_mul_f32     v122, v14, v122                        \n"   \
"   v_mul_f32     v123, v14, v123                        \n"   \
"   v_mul_f32     v124, v14, v124                        \n"   \
"   v_mul_f32     v125, v14, v125                        \n"   \
"   v_mul_f32     v126, v14, v126                        \n"   \
"   v_mul_f32     v127, v14, v127                        \n"   \
"   v_mul_f32     v128, v14, v128                        \n"   \
"   v_mul_f32     v129, v14, v129                        \n"   \
"   v_mul_f32     v130, v14, v130                        \n"   \
"   v_mul_f32     v131, v14, v131                        \n"   \
"   v_mul_f32     v132, v14, v132                        \n"   \
"   v_mul_f32     v133, v14, v133                        \n"   \
"   v_mul_f32     v134, v14, v134                        \n"   \
"   v_mul_f32     v135, v14, v135                        \n"   \
"   v_mul_f32     v136, v14, v136                        \n"   \
"   v_mul_f32     v137, v14, v137                        \n"   \
"   v_mul_f32     v138, v14, v138                        \n"   \
"   v_mul_f32     v139, v14, v139                        \n"   \
"   v_mul_f32     v140, v14, v140                        \n"   \
"   v_mul_f32     v141, v14, v141                        \n"   \
"   v_mul_f32     v142, v14, v142                        \n"   \
"   v_mul_f32     v143, v14, v143                        \n"   \
"   v_mul_f32     v144, v14, v144                        \n"   \
"   v_mul_f32     v145, v14, v145                        \n"   \
"   v_mul_f32     v146, v14, v146                        \n"   \
"   v_mul_f32     v147, v14, v147                        \n"   \
"   v_mul_f32     v148, v14, v148                        \n"   \
"   v_mul_f32     v149, v14, v149                        \n"   \
"   v_mul_f32     v150, v14, v150                        \n"   \
"   v_mul_f32     v151, v14, v151                        \n"   \
"   v_mul_f32     v152, v14, v152                        \n"   \
"   v_mul_f32     v153, v14, v153                        \n"   \
"   v_mul_f32     v154, v14, v154                        \n"   \
"   v_mul_f32     v155, v14, v155                        \n"   \
"   v_mul_f32     v156, v14, v156                        \n"   \
"   v_mul_f32     v157, v14, v157                        \n"   \
"   v_mul_f32     v158, v14, v158                        \n"   \
"   v_mul_f32     v159, v14, v159                        \n"   \
"   v_mul_f32     v160, v14, v160                        \n"   \
"   v_mul_f32     v161, v14, v161                        \n"   \
"   v_mul_f32     v162, v14, v162                        \n"   \
"   v_mul_f32     v163, v14, v163                        \n"   \
"   v_mul_f32     v164, v14, v164                        \n"   \
"   v_mul_f32     v165, v14, v165                        \n"   \
"   v_mul_f32     v166, v14, v166                        \n"   \
"   v_mul_f32     v167, v14, v167                        \n"   \
"   s_cmp_le_u32  s67, 1                                 \n"   \
"   s_cbranch_scc0  label_17A5                           \n"   \
"   s_mul_i32     s75, 0x00000400, s65                   \n"   \
"   s_mul_i32     s76, s67, s75                          \n"   \
"   s_add_u32     s56, s80, s79                          \n"   \
"   v_mov_b32     v20, s56                               \n"   \
"   v_mul_lo_u32  v21, s76, v20                          \n"   \
"   v_mul_hi_u32  v22, s76, v20                          \n"   \
"   s_nop         0x0002                                 \n"   \
"   v_readfirstlane_b32  s56, v21                        \n"   \
"   v_readfirstlane_b32  s57, v22                        \n"   \
"   s_nop         0x0004                                 \n"   \
"   s_add_u32     s8, s56, s8                            \n"   \
"   s_addc_u32    s9, s57, s9                            \n"   \
"   s_sub_u32     s56, s81, s80                          \n"   \
"   s_mul_i32     s56, s56, s76                          \n"   \
"   s_mov_b32     s10, s56                               \n"   \
"   v_and_b32     v20, 7, v0                             \n"   \
"   v_lshlrev_b32  v18, 4, v20                           \n"   \
"   v_lshrrev_b32  v20, 3, v0                            \n"   \
"   v_mul_i32_i24  v20, 0x00000400, v20                  \n"   \
"   v_add_u32     v18, v18, v20                          \n"   \
"   s_mul_i32     s56, s4, s75                           \n"   \
"   v_add_u32     v18, v18, s56                          \n"   \
"   s_mul_i32     s56, s7, s76                           \n"   \
"   v_add_u32     v18, v18, s56                          \n"   \
"   v_mov_b32     v19, v18                               \n"   \
"   s_waitcnt     vmcnt(0) & lgkmcnt(0)                  \n"   \
"   s_barrier                                            \n"   \
"   s_mul_i32     s75, 0x00000400, s65                   \n"   \
"   s_mul_i32     s76, s67, s75                          \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v5, 0x00000048, v20                   \n"   \
"   v_and_b32     v20, 15, v0                            \n"   \
"   v_mul_i32_i24  v20, 2, v20                           \n"   \
"   v_add_u32     v5, v20, v5                            \n"   \
"   s_mul_i32     s56, s7, 0x00000480                    \n"   \
"   v_add_u32     v5, s56, v5                            \n"   \
"   v_lshlrev_b32  v5, 2, v5                             \n"   \
"   v_lshrrev_b32  v20, 3, v0                            \n"   \
"   v_mul_i32_i24  v4, 2, v20                            \n"   \
"   v_and_b32     v20, 7, v0                             \n"   \
"   v_mul_i32_i24  v20, 36, v20                          \n"   \
"   v_add_u32     v4, v20, v4                            \n"   \
"   s_mul_i32     s56, s7, 0x00000480                    \n"   \
"   v_add_u32     v4, s56, v4                            \n"   \
"   v_lshlrev_b32  v4, 2, v4                             \n"   \
"   v_mov_b32     v29, 0xffff0000                        \n"   \
"   v_mov_b32     v30, 0x7fff0000                        \n"   \
"   v_mov_b32     v31, 0x00007fff                        \n"   \
"   s_mul_i32     s56, 0, s76                            \n"   \
"   v_add_u32     v19, v19, s56                          \n"   \
"   v_mov_b32     v24, v40                               \n"   \
"   v_mov_b32     v25, v44                               \n"   \
"   v_mov_b32     v26, v48                               \n"   \
"   v_mov_b32     v27, v52                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25]                           \n"   \
"   v_mov_b32     v24, v41                               \n"   \
"   v_mov_b32     v25, v45                               \n"   \
"   v_mov_b32     v26, v49                               \n"   \
"   v_mov_b32     v27, v53                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1152               \n"   \
"   v_mov_b32     v24, v42                               \n"   \
"   v_mov_b32     v25, v46                               \n"   \
"   v_mov_b32     v26, v50                               \n"   \
"   v_mov_b32     v27, v54                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:144                \n"   \
"   v_mov_b32     v24, v43                               \n"   \
"   v_mov_b32     v25, v47                               \n"   \
"   v_mov_b32     v26, v51                               \n"   \
"   v_mov_b32     v27, v55                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1296               \n"   \
"   v_mov_b32     v24, v56                               \n"   \
"   v_mov_b32     v25, v60                               \n"   \
"   v_mov_b32     v26, v64                               \n"   \
"   v_mov_b32     v27, v68                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2304               \n"   \
"   v_mov_b32     v24, v57                               \n"   \
"   v_mov_b32     v25, v61                               \n"   \
"   v_mov_b32     v26, v65                               \n"   \
"   v_mov_b32     v27, v69                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3456               \n"   \
"   v_mov_b32     v24, v58                               \n"   \
"   v_mov_b32     v25, v62                               \n"   \
"   v_mov_b32     v26, v66                               \n"   \
"   v_mov_b32     v27, v70                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2448               \n"   \
"   v_mov_b32     v24, v59                               \n"   \
"   v_mov_b32     v25, v63                               \n"   \
"   v_mov_b32     v26, v67                               \n"   \
"   v_mov_b32     v27, v71                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3600               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[40:41], v4                           \n"   \
"   ds_read_b64   v[44:45], v4 offset:64                 \n"   \
"   ds_read_b64   v[42:43], v4 offset:1152               \n"   \
"   ds_read_b64   v[46:47], v4 offset:1216               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[48:49], v4 offset:2304               \n"   \
"   ds_read_b64   v[52:53], v4 offset:2368               \n"   \
"   ds_read_b64   v[50:51], v4 offset:3456               \n"   \
"   ds_read_b64   v[54:55], v4 offset:3520               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:128\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:128\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v24, v72                               \n"   \
"   v_mov_b32     v25, v76                               \n"   \
"   v_mov_b32     v26, v80                               \n"   \
"   v_mov_b32     v27, v84                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25]                           \n"   \
"   v_mov_b32     v24, v73                               \n"   \
"   v_mov_b32     v25, v77                               \n"   \
"   v_mov_b32     v26, v81                               \n"   \
"   v_mov_b32     v27, v85                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1152               \n"   \
"   v_mov_b32     v24, v74                               \n"   \
"   v_mov_b32     v25, v78                               \n"   \
"   v_mov_b32     v26, v82                               \n"   \
"   v_mov_b32     v27, v86                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:144                \n"   \
"   v_mov_b32     v24, v75                               \n"   \
"   v_mov_b32     v25, v79                               \n"   \
"   v_mov_b32     v26, v83                               \n"   \
"   v_mov_b32     v27, v87                               \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1296               \n"   \
"   v_mov_b32     v24, v88                               \n"   \
"   v_mov_b32     v25, v92                               \n"   \
"   v_mov_b32     v26, v96                               \n"   \
"   v_mov_b32     v27, v100                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2304               \n"   \
"   v_mov_b32     v24, v89                               \n"   \
"   v_mov_b32     v25, v93                               \n"   \
"   v_mov_b32     v26, v97                               \n"   \
"   v_mov_b32     v27, v101                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3456               \n"   \
"   v_mov_b32     v24, v90                               \n"   \
"   v_mov_b32     v25, v94                               \n"   \
"   v_mov_b32     v26, v98                               \n"   \
"   v_mov_b32     v27, v102                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2448               \n"   \
"   v_mov_b32     v24, v91                               \n"   \
"   v_mov_b32     v25, v95                               \n"   \
"   v_mov_b32     v26, v99                               \n"   \
"   v_mov_b32     v27, v103                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3600               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[40:41], v4                           \n"   \
"   ds_read_b64   v[44:45], v4 offset:64                 \n"   \
"   ds_read_b64   v[42:43], v4 offset:1152               \n"   \
"   ds_read_b64   v[46:47], v4 offset:1216               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[48:49], v4 offset:2304               \n"   \
"   ds_read_b64   v[52:53], v4 offset:2368               \n"   \
"   ds_read_b64   v[50:51], v4 offset:3456               \n"   \
"   ds_read_b64   v[54:55], v4 offset:3520               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:256\n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:384\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:256\n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:384\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v24, v104                              \n"   \
"   v_mov_b32     v25, v108                              \n"   \
"   v_mov_b32     v26, v112                              \n"   \
"   v_mov_b32     v27, v116                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25]                           \n"   \
"   v_mov_b32     v24, v105                              \n"   \
"   v_mov_b32     v25, v109                              \n"   \
"   v_mov_b32     v26, v113                              \n"   \
"   v_mov_b32     v27, v117                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1152               \n"   \
"   v_mov_b32     v24, v106                              \n"   \
"   v_mov_b32     v25, v110                              \n"   \
"   v_mov_b32     v26, v114                              \n"   \
"   v_mov_b32     v27, v118                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:144                \n"   \
"   v_mov_b32     v24, v107                              \n"   \
"   v_mov_b32     v25, v111                              \n"   \
"   v_mov_b32     v26, v115                              \n"   \
"   v_mov_b32     v27, v119                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1296               \n"   \
"   v_mov_b32     v24, v120                              \n"   \
"   v_mov_b32     v25, v124                              \n"   \
"   v_mov_b32     v26, v128                              \n"   \
"   v_mov_b32     v27, v132                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2304               \n"   \
"   v_mov_b32     v24, v121                              \n"   \
"   v_mov_b32     v25, v125                              \n"   \
"   v_mov_b32     v26, v129                              \n"   \
"   v_mov_b32     v27, v133                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3456               \n"   \
"   v_mov_b32     v24, v122                              \n"   \
"   v_mov_b32     v25, v126                              \n"   \
"   v_mov_b32     v26, v130                              \n"   \
"   v_mov_b32     v27, v134                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2448               \n"   \
"   v_mov_b32     v24, v123                              \n"   \
"   v_mov_b32     v25, v127                              \n"   \
"   v_mov_b32     v26, v131                              \n"   \
"   v_mov_b32     v27, v135                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3600               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[40:41], v4                           \n"   \
"   ds_read_b64   v[44:45], v4 offset:64                 \n"   \
"   ds_read_b64   v[42:43], v4 offset:1152               \n"   \
"   ds_read_b64   v[46:47], v4 offset:1216               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[48:49], v4 offset:2304               \n"   \
"   ds_read_b64   v[52:53], v4 offset:2368               \n"   \
"   ds_read_b64   v[50:51], v4 offset:3456               \n"   \
"   ds_read_b64   v[54:55], v4 offset:3520               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:640\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:640\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v24, v136                              \n"   \
"   v_mov_b32     v25, v140                              \n"   \
"   v_mov_b32     v26, v144                              \n"   \
"   v_mov_b32     v27, v148                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25]                           \n"   \
"   v_mov_b32     v24, v137                              \n"   \
"   v_mov_b32     v25, v141                              \n"   \
"   v_mov_b32     v26, v145                              \n"   \
"   v_mov_b32     v27, v149                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1152               \n"   \
"   v_mov_b32     v24, v138                              \n"   \
"   v_mov_b32     v25, v142                              \n"   \
"   v_mov_b32     v26, v146                              \n"   \
"   v_mov_b32     v27, v150                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:144                \n"   \
"   v_mov_b32     v24, v139                              \n"   \
"   v_mov_b32     v25, v143                              \n"   \
"   v_mov_b32     v26, v147                              \n"   \
"   v_mov_b32     v27, v151                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:1296               \n"   \
"   v_mov_b32     v24, v152                              \n"   \
"   v_mov_b32     v25, v156                              \n"   \
"   v_mov_b32     v26, v160                              \n"   \
"   v_mov_b32     v27, v164                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2304               \n"   \
"   v_mov_b32     v24, v153                              \n"   \
"   v_mov_b32     v25, v157                              \n"   \
"   v_mov_b32     v26, v161                              \n"   \
"   v_mov_b32     v27, v165                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3456               \n"   \
"   v_mov_b32     v24, v154                              \n"   \
"   v_mov_b32     v25, v158                              \n"   \
"   v_mov_b32     v26, v162                              \n"   \
"   v_mov_b32     v27, v166                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:2448               \n"   \
"   v_mov_b32     v24, v155                              \n"   \
"   v_mov_b32     v25, v159                              \n"   \
"   v_mov_b32     v26, v163                              \n"   \
"   v_mov_b32     v27, v167                              \n"   \
"   v_cmp_u_f32   s[38:39], v24, v24                     \n"   \
"   v_add3_u32    v28, v24, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v25, v25                     \n"   \
"   v_add3_u32    v28, v25, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v24, v21, v20, s52                     \n"   \
"   v_cmp_u_f32   s[38:39], v26, v26                     \n"   \
"   v_add3_u32    v28, v26, v31, 1                       \n"   \
"   v_cndmask_b32  v20, v28, v30, s[38:39]               \n"   \
"   v_cmp_u_f32   s[38:39], v27, v27                     \n"   \
"   v_add3_u32    v28, v27, v31, 1                       \n"   \
"   v_cndmask_b32  v21, v28, v30, s[38:39]               \n"   \
"   v_perm_b32    v25, v21, v20, s52                     \n"   \
"   ds_write_b64  v5, v[24:25] offset:3600               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[40:41], v4                           \n"   \
"   ds_read_b64   v[44:45], v4 offset:64                 \n"   \
"   ds_read_b64   v[42:43], v4 offset:1152               \n"   \
"   ds_read_b64   v[46:47], v4 offset:1216               \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b64   v[48:49], v4 offset:2304               \n"   \
"   ds_read_b64   v[52:53], v4 offset:2368               \n"   \
"   ds_read_b64   v[50:51], v4 offset:3456               \n"   \
"   ds_read_b64   v[54:55], v4 offset:3520               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:768\n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:896\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:768\n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:896\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   s_branch      label_1960                             \n"   \
" label_17A5: \n"   \
"   s_mul_i32     s76, s67, s75                          \n"   \
"   s_add_u32     s56, s80, s79                          \n"   \
"   v_mov_b32     v20, s56                               \n"   \
"   v_mul_lo_u32  v21, s76, v20                          \n"   \
"   v_mul_hi_u32  v22, s76, v20                          \n"   \
"   s_nop         0x0002                                 \n"   \
"   v_readfirstlane_b32  s56, v21                        \n"   \
"   v_readfirstlane_b32  s57, v22                        \n"   \
"   s_nop         0x0004                                 \n"   \
"   s_add_u32     s8, s56, s8                            \n"   \
"   s_addc_u32    s9, s57, s9                            \n"   \
"   s_sub_u32     s56, s81, s80                          \n"   \
"   s_mul_i32     s56, s56, s76                          \n"   \
"   s_mov_b32     s10, s56                               \n"   \
"   v_and_b32     v20, 15, v0                            \n"   \
"   v_lshlrev_b32  v18, 4, v20                           \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v20, 0x00000800, v20                  \n"   \
"   v_add_u32     v18, v18, v20                          \n"   \
"   s_mul_i32     s56, s4, s75                           \n"   \
"   v_add_u32     v18, v18, s56                          \n"   \
"   s_mul_i32     s56, s7, s76                           \n"   \
"   v_add_u32     v18, v18, s56                          \n"   \
"   v_mov_b32     v19, v18                               \n"   \
"   s_mul_i32     s58, 4, s65                            \n"   \
"   s_mul_i32     s77, s67, s58                          \n"   \
"   s_add_u32     s56, s80, s79                          \n"   \
"   s_mul_i32     s56, s56, s77                          \n"   \
"   s_add_u32     s12, s56, s12                          \n"   \
"   s_addc_u32    s13, 0, s13                            \n"   \
"   s_sub_u32     s56, s81, s80                          \n"   \
"   s_mul_i32     s56, s56, s77                          \n"   \
"   s_mov_b32     s14, s56                               \n"   \
"   v_and_b32     v26, 15, v0                            \n"   \
"   v_lshlrev_b32  v26, 2, v26                           \n"   \
"   s_mul_i32     s56, s4, s58                           \n"   \
"   v_add_u32     v26, v26, s56                          \n"   \
"   s_mul_i32     s56, s7, s77                           \n"   \
"   v_add_u32     v26, v26, s56                          \n"   \
"   s_waitcnt     vmcnt(0) & lgkmcnt(0)                  \n"   \
"   s_barrier                                            \n"   \
"   v_lshlrev_b32  v5, 2, v0                             \n"   \
"   s_mul_i32     s56, s7, 0x00000840                    \n"   \
"   v_add_u32     v5, s56, v5                            \n"   \
"   v_lshlrev_b32  v5, 2, v5                             \n"   \
"   v_lshrrev_b32  v20, 4, v0                            \n"   \
"   v_mul_i32_i24  v4, 4, v20                            \n"   \
"   v_and_b32     v20, 3, v0                             \n"   \
"   v_mul_i32_i24  v20, 0x00000108, v20                  \n"   \
"   v_add_u32     v4, v20, v4                            \n"   \
"   v_and_b32     v20, 15, v0                            \n"   \
"   v_lshrrev_b32  v20, 2, v20                           \n"   \
"   v_mul_i32_i24  v20, 64, v20                          \n"   \
"   v_add_u32     v4, v20, v4                            \n"   \
"   s_mul_i32     s56, s7, 0x00000840                    \n"   \
"   v_add_u32     v4, s56, v4                            \n"   \
"   v_lshlrev_b32  v4, 2, v4                             \n"   \
"   s_mul_i32     s56, 0, s76                            \n"   \
"   v_add_u32     v19, v19, s56                          \n"   \
"   v_mov_b32     v20, v40                               \n"   \
"   v_mov_b32     v21, v44                               \n"   \
"   v_mov_b32     v22, v48                               \n"   \
"   v_mov_b32     v23, v52                               \n"   \
"   ds_write_b128  v5, v[20:23]                          \n"   \
"   v_mov_b32     v20, v41                               \n"   \
"   v_mov_b32     v21, v45                               \n"   \
"   v_mov_b32     v22, v49                               \n"   \
"   v_mov_b32     v23, v53                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:1056              \n"   \
"   v_mov_b32     v20, v42                               \n"   \
"   v_mov_b32     v21, v46                               \n"   \
"   v_mov_b32     v22, v50                               \n"   \
"   v_mov_b32     v23, v54                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:2112              \n"   \
"   v_mov_b32     v20, v43                               \n"   \
"   v_mov_b32     v21, v47                               \n"   \
"   v_mov_b32     v22, v51                               \n"   \
"   v_mov_b32     v23, v55                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:3168              \n"   \
"   v_mov_b32     v20, v56                               \n"   \
"   v_mov_b32     v21, v60                               \n"   \
"   v_mov_b32     v22, v64                               \n"   \
"   v_mov_b32     v23, v68                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:4224              \n"   \
"   v_mov_b32     v20, v57                               \n"   \
"   v_mov_b32     v21, v61                               \n"   \
"   v_mov_b32     v22, v65                               \n"   \
"   v_mov_b32     v23, v69                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:5280              \n"   \
"   v_mov_b32     v20, v58                               \n"   \
"   v_mov_b32     v21, v62                               \n"   \
"   v_mov_b32     v22, v66                               \n"   \
"   v_mov_b32     v23, v70                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:6336              \n"   \
"   v_mov_b32     v20, v59                               \n"   \
"   v_mov_b32     v21, v63                               \n"   \
"   v_mov_b32     v22, v67                               \n"   \
"   v_mov_b32     v23, v71                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:7392              \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[40:43], v4                           \n"   \
"   ds_read_b128  v[44:47], v4 offset:64                 \n"   \
"   ds_read_b128  v[48:51], v4 offset:128                \n"   \
"   ds_read_b128  v[52:55], v4 offset:192                \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[56:59], v4 offset:4224               \n"   \
"   ds_read_b128  v[60:63], v4 offset:4288               \n"   \
"   ds_read_b128  v[64:67], v4 offset:4352               \n"   \
"   ds_read_b128  v[68:71], v4 offset:4416               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[56:59], v18, s[8:11], 0 offen offset:256\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[60:63], v18, s[8:11], 0 offen offset:256\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[64:67], v18, s[8:11], 0 offen offset:256\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen\n"   \
"   buffer_store_dwordx4  v[68:71], v18, s[8:11], 0 offen offset:256\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v20, v72                               \n"   \
"   v_mov_b32     v21, v76                               \n"   \
"   v_mov_b32     v22, v80                               \n"   \
"   v_mov_b32     v23, v84                               \n"   \
"   ds_write_b128  v5, v[20:23]                          \n"   \
"   v_mov_b32     v20, v73                               \n"   \
"   v_mov_b32     v21, v77                               \n"   \
"   v_mov_b32     v22, v81                               \n"   \
"   v_mov_b32     v23, v85                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:1056              \n"   \
"   v_mov_b32     v20, v74                               \n"   \
"   v_mov_b32     v21, v78                               \n"   \
"   v_mov_b32     v22, v82                               \n"   \
"   v_mov_b32     v23, v86                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:2112              \n"   \
"   v_mov_b32     v20, v75                               \n"   \
"   v_mov_b32     v21, v79                               \n"   \
"   v_mov_b32     v22, v83                               \n"   \
"   v_mov_b32     v23, v87                               \n"   \
"   ds_write_b128  v5, v[20:23] offset:3168              \n"   \
"   v_mov_b32     v20, v88                               \n"   \
"   v_mov_b32     v21, v92                               \n"   \
"   v_mov_b32     v22, v96                               \n"   \
"   v_mov_b32     v23, v100                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:4224              \n"   \
"   v_mov_b32     v20, v89                               \n"   \
"   v_mov_b32     v21, v93                               \n"   \
"   v_mov_b32     v22, v97                               \n"   \
"   v_mov_b32     v23, v101                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:5280              \n"   \
"   v_mov_b32     v20, v90                               \n"   \
"   v_mov_b32     v21, v94                               \n"   \
"   v_mov_b32     v22, v98                               \n"   \
"   v_mov_b32     v23, v102                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:6336              \n"   \
"   v_mov_b32     v20, v91                               \n"   \
"   v_mov_b32     v21, v95                               \n"   \
"   v_mov_b32     v22, v99                               \n"   \
"   v_mov_b32     v23, v103                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:7392              \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[40:43], v4                           \n"   \
"   ds_read_b128  v[44:47], v4 offset:64                 \n"   \
"   ds_read_b128  v[48:51], v4 offset:128                \n"   \
"   ds_read_b128  v[52:55], v4 offset:192                \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[56:59], v4 offset:4224               \n"   \
"   ds_read_b128  v[60:63], v4 offset:4288               \n"   \
"   ds_read_b128  v[64:67], v4 offset:4352               \n"   \
"   ds_read_b128  v[68:71], v4 offset:4416               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[56:59], v18, s[8:11], 0 offen offset:768\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[60:63], v18, s[8:11], 0 offen offset:768\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[64:67], v18, s[8:11], 0 offen offset:768\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:512\n"   \
"   buffer_store_dwordx4  v[68:71], v18, s[8:11], 0 offen offset:768\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v20, v104                              \n"   \
"   v_mov_b32     v21, v108                              \n"   \
"   v_mov_b32     v22, v112                              \n"   \
"   v_mov_b32     v23, v116                              \n"   \
"   ds_write_b128  v5, v[20:23]                          \n"   \
"   v_mov_b32     v20, v105                              \n"   \
"   v_mov_b32     v21, v109                              \n"   \
"   v_mov_b32     v22, v113                              \n"   \
"   v_mov_b32     v23, v117                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:1056              \n"   \
"   v_mov_b32     v20, v106                              \n"   \
"   v_mov_b32     v21, v110                              \n"   \
"   v_mov_b32     v22, v114                              \n"   \
"   v_mov_b32     v23, v118                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:2112              \n"   \
"   v_mov_b32     v20, v107                              \n"   \
"   v_mov_b32     v21, v111                              \n"   \
"   v_mov_b32     v22, v115                              \n"   \
"   v_mov_b32     v23, v119                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:3168              \n"   \
"   v_mov_b32     v20, v120                              \n"   \
"   v_mov_b32     v21, v124                              \n"   \
"   v_mov_b32     v22, v128                              \n"   \
"   v_mov_b32     v23, v132                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:4224              \n"   \
"   v_mov_b32     v20, v121                              \n"   \
"   v_mov_b32     v21, v125                              \n"   \
"   v_mov_b32     v22, v129                              \n"   \
"   v_mov_b32     v23, v133                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:5280              \n"   \
"   v_mov_b32     v20, v122                              \n"   \
"   v_mov_b32     v21, v126                              \n"   \
"   v_mov_b32     v22, v130                              \n"   \
"   v_mov_b32     v23, v134                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:6336              \n"   \
"   v_mov_b32     v20, v123                              \n"   \
"   v_mov_b32     v21, v127                              \n"   \
"   v_mov_b32     v22, v131                              \n"   \
"   v_mov_b32     v23, v135                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:7392              \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[40:43], v4                           \n"   \
"   ds_read_b128  v[44:47], v4 offset:64                 \n"   \
"   ds_read_b128  v[48:51], v4 offset:128                \n"   \
"   ds_read_b128  v[52:55], v4 offset:192                \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[56:59], v4 offset:4224               \n"   \
"   ds_read_b128  v[60:63], v4 offset:4288               \n"   \
"   ds_read_b128  v[64:67], v4 offset:4352               \n"   \
"   ds_read_b128  v[68:71], v4 offset:4416               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:1024\n"   \
"   buffer_store_dwordx4  v[56:59], v18, s[8:11], 0 offen offset:1280\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:1024\n"   \
"   buffer_store_dwordx4  v[60:63], v18, s[8:11], 0 offen offset:1280\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:1024\n"   \
"   buffer_store_dwordx4  v[64:67], v18, s[8:11], 0 offen offset:1280\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:1024\n"   \
"   buffer_store_dwordx4  v[68:71], v18, s[8:11], 0 offen offset:1280\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   v_mov_b32     v20, v136                              \n"   \
"   v_mov_b32     v21, v140                              \n"   \
"   v_mov_b32     v22, v144                              \n"   \
"   v_mov_b32     v23, v148                              \n"   \
"   ds_write_b128  v5, v[20:23]                          \n"   \
"   v_mov_b32     v20, v137                              \n"   \
"   v_mov_b32     v21, v141                              \n"   \
"   v_mov_b32     v22, v145                              \n"   \
"   v_mov_b32     v23, v149                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:1056              \n"   \
"   v_mov_b32     v20, v138                              \n"   \
"   v_mov_b32     v21, v142                              \n"   \
"   v_mov_b32     v22, v146                              \n"   \
"   v_mov_b32     v23, v150                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:2112              \n"   \
"   v_mov_b32     v20, v139                              \n"   \
"   v_mov_b32     v21, v143                              \n"   \
"   v_mov_b32     v22, v147                              \n"   \
"   v_mov_b32     v23, v151                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:3168              \n"   \
"   v_mov_b32     v20, v152                              \n"   \
"   v_mov_b32     v21, v156                              \n"   \
"   v_mov_b32     v22, v160                              \n"   \
"   v_mov_b32     v23, v164                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:4224              \n"   \
"   v_mov_b32     v20, v153                              \n"   \
"   v_mov_b32     v21, v157                              \n"   \
"   v_mov_b32     v22, v161                              \n"   \
"   v_mov_b32     v23, v165                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:5280              \n"   \
"   v_mov_b32     v20, v154                              \n"   \
"   v_mov_b32     v21, v158                              \n"   \
"   v_mov_b32     v22, v162                              \n"   \
"   v_mov_b32     v23, v166                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:6336              \n"   \
"   v_mov_b32     v20, v155                              \n"   \
"   v_mov_b32     v21, v159                              \n"   \
"   v_mov_b32     v22, v163                              \n"   \
"   v_mov_b32     v23, v167                              \n"   \
"   ds_write_b128  v5, v[20:23] offset:7392              \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[40:43], v4                           \n"   \
"   ds_read_b128  v[44:47], v4 offset:64                 \n"   \
"   ds_read_b128  v[48:51], v4 offset:128                \n"   \
"   ds_read_b128  v[52:55], v4 offset:192                \n"   \
"   s_waitcnt     lgkmcnt(4)                             \n"   \
"   ds_read_b128  v[56:59], v4 offset:4224               \n"   \
"   ds_read_b128  v[60:63], v4 offset:4288               \n"   \
"   ds_read_b128  v[64:67], v4 offset:4352               \n"   \
"   ds_read_b128  v[68:71], v4 offset:4416               \n"   \
"   s_waitcnt     lgkmcnt(0)                             \n"   \
"   v_mov_b32     v18, v19                               \n"   \
"   buffer_store_dwordx4  v[40:43], v18, s[8:11], 0 offen offset:1536\n"   \
"   buffer_store_dwordx4  v[56:59], v18, s[8:11], 0 offen offset:1792\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[44:47], v18, s[8:11], 0 offen offset:1536\n"   \
"   buffer_store_dwordx4  v[60:63], v18, s[8:11], 0 offen offset:1792\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[48:51], v18, s[8:11], 0 offen offset:1536\n"   \
"   buffer_store_dwordx4  v[64:67], v18, s[8:11], 0 offen offset:1792\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dwordx4  v[52:55], v18, s[8:11], 0 offen offset:1536\n"   \
"   buffer_store_dwordx4  v[68:71], v18, s[8:11], 0 offen offset:1792\n"   \
"   v_add_u32     v18, 0x00002000, v18                   \n"   \
"   buffer_store_dword  v24, v26, s[12:15], 0 offen      \n"   \
"   s_mul_i32     s56, 4, s77                            \n"   \
"   v_add_u32     v26, v26, s56                          \n"   \
" label_1960: \n"   \
"   s_waitcnt     0x0000                                 \n"   \
"   s_endpgm                                             \n" 


