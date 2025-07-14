";-------------------------------------------------------------\n"
  "s_and_b32     s1, s1, 0x0000ffff                     \n"// 000000000000: 8601FF01 0000FFFF
  ";s_load_dwordx2  s[8:9], s[0:1], 0x00                 \n"// 000000000008: C0060200 00000000
  ";s_load_dwordx2  s[12:13], s[0:1], 0x10               \n"// 000000000010: C0060300 00000010
  ";s_load_dwordx2  s[16:17], s[0:1], 0x20               \n"// 000000000018: C0060400 00000020
  ";s_load_dwordx2  s[20:21], s[0:1], 0x30               \n"// 000000000020: C0060500 00000030
  ";s_load_dwordx2  s[28:29], s[0:1], 0x40               \n"// 000000000028: C0060700 00000040
  ";s_load_dwordx2  s[24:25], s[0:1], 0x50               \n"// 000000000030: C0060600 00000050
  ";s_load_dwordx2  s[30:31], s[0:1], 0x60               \n"// 000000000038: C0060780 00000060
  ";s_load_dword  s64, s[0:1], 0x70                      \n"// 000000000040: C0021000 00000070
  ";s_load_dword  s65, s[0:1], 0x80                      \n"// 000000000048: C0021040 00000080
  ";s_load_dword  s67, s[0:1], 0x90                      \n"// 000000000050: C00210C0 00000090
  ";s_load_dword  s66, s[0:1], 0xa0                      \n"// 000000000058: C0021080 000000A0
  ";s_load_dword  s68, s[0:1], 0xb0                      \n"// 000000000060: C0021100 000000B0
  ";s_load_dword  s69, s[0:1], 0xc0                      \n"// 000000000068: C0021140 000000C0
  ";s_load_dwordx2  s[32:33], s[0:1], 0xd0               \n"// 000000000070: C0060800 000000D0
  "v_lshrrev_b32  v1, 10, %[threadIdxx]                            \n"// 000000000078: 2002008A
  "v_lshrrev_b32  v2, 10, v1                            \n"// 00000000007C: 2004028A
  "v_and_b32     v2, 0x000003ff, v2                     \n"// 000000000080: 260404FF 000003FF
  "v_and_b32     v1, 0x000003ff, v1                     \n"// 000000000088: 260202FF 000003FF
  "v_and_b32     %[threadIdxx], 0x000003ff, %[threadIdxx]                     \n"// 000000000090: 260000FF 000003FF
  "v_lshrrev_b32  v3, 6, %[threadIdxx]                             \n"// 000000000098: 20060086
  "v_and_b32     %[threadIdxx], 63, %[threadIdxx]                             \n"// 00000000009C: 260000BF
  "s_mov_b32     %[blockIdxx], %[blockIdxx]                                 \n"// 0000000000A0: BE820002
  "s_mov_b32     %[blockIdxy], %[blockIdxy]                                 \n"// 0000000000A4: BE830003
  "s_mov_b32     %[blockIdxz], %[blockIdxz]                                 \n"// 0000000000A8: BE840004
  "v_readfirstlane_b32  s7, v3                          \n"// 0000000000AC: 7E0E0503
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000000B0: BF8CC07F
  "s_mul_i32     s56, %[blockIdxy], 4                             \n"// 0000000000B8: 92388403
  "s_and_b32     %[kv_indptr_res_1], %[kv_indptr_res_1], 0x0000ffff                   \n"// 0000000000BC: 861DFF1D 0000FFFF
  ";s_and_b32     s31, s31, 0x0000ffff                   \n"// 0000000000C4: 861FFF1F 0000FFFF
  "s_add_u32     %[kv_indptr_res_0], s56, %[kv_indptr_res_0]                          \n"// 0000000000CC: 801C1C38
  "s_addc_u32    %[kv_indptr_res_1], 0, %[kv_indptr_res_1]                            \n"// 0000000000D0: 821D1D80
  "s_load_dword  s47, [%[kv_indptr_res_0], %[kv_indptr_res_1]], 0x00                    \n"// 0000000000D4: C0020BCE 00000000
  "s_load_dword  s46, [%[kv_indptr_res_0], %[kv_indptr_res_1]], 0x04                    \n"// 0000000000DC: C0020B8E 00000004
  "s_mul_i32     s56, %[blockIdxy], 4                             \n"// 0000000000E4: 92388403
  "s_and_b32     %[qo_res_1], %[qo_res_1], 0x0000ffff                   \n"// 0000000000E8: 8621FF21 0000FFFF
  "s_add_u32     %[qo_res_0], s56, %[qo_res_0]                          \n"// 0000000000F0: 80202038
  "s_addc_u32    %[qo_res_1], 0, %[qo_res_1]                            \n"// 0000000000F4: 82212180
  "s_load_dword  s79, [%[qo_res_0], %[qo_res_1]], 0x00                    \n"// 0000000000F8: C00213D0 00000000
  "s_load_dword  s78, [%[qo_res_0], %[qo_res_1]], 0x04                    \n"// 000000000100: C0021390 00000004
  "s_mul_i32     s75, 0x00000800, %[s_head_num_q]                   \n"// 000000000108: 924B41FF 00000800
  "s_mul_i32     s74, 0x00000480, %[s_head_num_q]                   \n"// 000000000110: 924A41FF 00000480
  "s_mul_i32     s56, 4, %[s_head_num_q]                            \n"// 000000000118: 92384184
  "s_mov_b32     %[o_res_2], s75                               \n"// 00000000011C: BE8A004B
  "s_mov_b32     %[q_res_2], -16                               \n"// 000000000120: BE9200D0
  "s_mov_b32     %[lse_res_2], s56                               \n"// 000000000124: BE8E0038
  "s_mov_b32     %[kv_res_2], -16                               \n"// 000000000128: BE9600D0
  "s_mov_b32     %[kv_indices_res_2], -16                               \n"// 00000000012C: BE9A00D0
  ";s_mov_b32     s11, 0x00020000                        \n"// 000000000130: BE8B00FF 00020000
  ";s_mov_b32     s19, 0x00020000                        \n"// 000000000138: BE9300FF 00020000
  ";s_mov_b32     s15, 0x00020000                        \n"// 000000000140: BE8F00FF 00020000
  ";s_mov_b32     s23, 0x00020000                        \n"// 000000000148: BE9700FF 00020000
  ";s_mov_b32     s27, 0x00020000                        \n"// 000000000150: BE9B00FF 00020000
  "s_and_b32     %[o_res_1], %[o_res_1], 0x0000ffff                     \n"// 000000000158: 8609FF09 0000FFFF
  "s_and_b32     %[q_res_1], %[q_res_1], 0x0000ffff                   \n"// 000000000160: 8611FF11 0000FFFF
  "s_and_b32     %[lse_res_1], %[lse_res_1], 0x0000ffff                   \n"// 000000000168: 860DFF0D 0000FFFF
  "s_and_b32     %[kv_res_1], %[kv_res_1], 0x0000ffff                   \n"// 000000000170: 8615FF15 0000FFFF
  "s_and_b32     %[kv_indices_res_1], %[kv_indices_res_1], 0x0000ffff                   \n"// 000000000178: 8619FF19 0000FFFF
  "s_or_b32      %[o_res_1], %[o_res_1], 0x00040000                     \n"// 000000000180: 8709FF09 00040000
  "s_or_b32      %[q_res_1], %[q_res_1], 0x00040000                   \n"// 000000000188: 8711FF11 00040000
  "s_or_b32      %[lse_res_1], %[lse_res_1], 0x00040000                   \n"// 000000000190: 870DFF0D 00040000
  "s_or_b32      %[kv_res_1], %[kv_res_1], 0x00040000                   \n"// 000000000198: 8715FF15 00040000
  "s_or_b32      %[kv_indices_res_1], %[kv_indices_res_1], 0x00040000                   \n"// 0000000001A0: 8719FF19 00040000
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000001A8: BF8CC07F
  "s_mul_i32     s80, %[blockIdxx], 8                             \n"// 0000000001AC: 92508802
  "s_sub_u32     s81, s78, s79                          \n"// 0000000001B0: 80D14F4E
  "s_cmp_le_u32  s81, s80                               \n"// 0000000001B4: BF0B5051
  "s_cbranch_scc1  label_1960                           \n"// 0000000001B8: BF8518F1
  "s_lshr_b32    s44, 16, %[s_log2_plen]                           \n"// 0000000001C0: 8F2C4590
  "s_mul_i32     s73, s44, 4                            \n"// 0000000001C4: 9249842C
  "s_mul_i32     s73, s73, %[s_kv_splits]                          \n"// 0000000001C8: 92494349
  "s_mul_i32     s45, %[blockIdxz], s44                           \n"// 0000000001CC: 922D2C04
  "s_sub_u32     s50, s46, s47                          \n"// 0000000001D0: 80B22F2E
  "s_lshl_b32    s56, s50, %[s_log2_plen]                          \n"// 0000000001D4: 8E384532
  "s_sub_u32     s82, s56, s81                          \n"// 0000000001D8: 80D25138
  "s_mul_i32     s58, %[blockIdxx], 8                             \n"// 0000000001DC: 923A8802
  "s_add_u32     s82, s82, s58                          \n"// 0000000001E0: 80523A52
  "s_add_u32     s57, s82, 8                            \n"// 0000000001E4: 80398852
  "s_min_u32     s56, s56, s57                          \n"// 0000000001E8: 83B83938
  "s_lshr_b32    s50, s56, %[s_log2_plen]                          \n"// 0000000001EC: 8F324538
  "s_lshl_b32    s56, s45, %[s_log2_plen]                          \n"// 0000000001F0: 8E38452D
  "s_add_u32     s83, s56, 15                           \n"// 0000000001F4: 80538F38
  "s_mul_i32     s84, %[s_kv_splits], 16                           \n"// 0000000001F8: 92549043
  "s_cmp_le_u32  s50, s45                               \n"// 0000000001FC: BF0B2D32
  "s_cbranch_scc1  label_1960                           \n"// 000000000200: BF8518DF
  "s_mul_i32     s56, s50, 4                            \n"// 000000000204: 92388432
  "s_mov_b32     %[kv_indices_res_2], s56                               \n"// 000000000208: BE9A0038
  "s_mul_i32     s56, s47, 4                            \n"// 00000000020C: 9238842F
  "s_add_u32     %[kv_indices_res_0], s56, %[kv_indices_res_0]                          \n"// 000000000210: 80181838
  "s_addc_u32    %[kv_indices_res_1], 0, %[kv_indices_res_1]                            \n"// 000000000214: 82191980
  "s_mov_b32     s70, 0                                 \n"// 000000000218: BEC60080
  "s_sub_u32     s71, s50, s45                          \n"// 00000000021C: 80C72D32
  "s_mul_i32     s39, %[s_kv_splits], s44                          \n"// 000000000220: 92272C43
  "s_mov_b32     s38, s71                               \n"// 000000000224: BEA60047
  "v_cvt_f32_u32  v20, s39                              \n"// 000000000228: 7E280C27
  "s_sub_i32     s56, 0, s39                            \n"// 00000000022C: 81B82780
  "v_rcp_iflag_f32  v20, v20                            \n"// 000000000230: 7E284714
  "s_nop         0x0000                                 \n"// 000000000234: BF800000
  "v_mul_f32     v20, 0x4f7ffffe, v20                   \n"// 000000000238: 0A2828FF 4F7FFFFE
  "v_cvt_u32_f32  v20, v20                              \n"// 000000000240: 7E280F14
  "v_mul_lo_u32  v21, s56, v20                          \n"// 000000000244: D2850015 00022838
  "v_mul_hi_u32  v21, v20, v21                          \n"// 00000000024C: D2860015 00022B14
  "v_add_u32     v20, v20, v21                          \n"// 000000000254: 68282B14
  "v_mul_hi_u32  v20, s38, v20                          \n"// 000000000258: D2860014 00022826
  "v_mul_lo_u32  v21, v20, s39                          \n"// 000000000260: D2850015 00004F14
  "v_sub_u32     v23, s38, v21                          \n"// 000000000268: 6A2E2A26
  "v_add_u32     v22, 1, v20                            \n"// 00000000026C: 682C2881
  "v_cmp_le_u32  vcc, s39, v23                          \n"// 000000000270: 7D962E27
  "v_subrev_u32  v21, s39, v23                          \n"// 000000000274: 6C2A2E27
  "s_nop         0x0000                                 \n"// 000000000278: BF800000
  "v_cndmask_b32  v20, v20, v22, vcc                    \n"// 00000000027C: 00282D14
  "v_cndmask_b32  v23, v23, v21, vcc                    \n"// 000000000280: 002E2B17
  "v_add_u32     v21, 1, v20                            \n"// 000000000284: 682A2881
  "v_cmp_le_u32  vcc, s39, v23                          \n"// 000000000288: 7D962E27
  "s_nop         0x0001                                 \n"// 00000000028C: BF800001
  "v_cndmask_b32  v23, v20, v21, vcc                    \n"// 000000000290: 002E2B14
  "s_nop         0x0003                                 \n"// 000000000294: BF800003
  "v_readfirstlane_b32  s40, v23                        \n"// 000000000298: 7E500517
  "s_nop         0x0003                                 \n"// 00000000029C: BF800003
  "s_mov_b32     s71, s40                               \n"// 0000000002A0: BEC70028
  "s_mul_i32     s56, s71, s39                          \n"// 0000000002A4: 92382747
  "s_sub_u32     s56, s38, s56                          \n"// 0000000002A8: 80B83826
  "s_mov_b32     s57, 0                                 \n"// 0000000002AC: BEB90080
  "s_cmp_lt_u32  s56, s44                               \n"// 0000000002B0: BF0A2C38
  "s_cselect_b32  s57, s57, 1                           \n"// 0000000002B4: 85398139
  "s_add_u32     s71, s57, s71                          \n"// 0000000002B8: 80474739
  "s_cmpk_eq_u32  s57, 0x0001                           \n"// 0000000002BC: B4390001
  "s_cselect_b32  s49, 0, s56                           \n"// 0000000002C0: 85313880
  "s_mov_b32     s48, s49                               \n"// 0000000002C4: BEB00031
  "v_lshrrev_b32  v20, 3, %[threadIdxx]                            \n"// 0000000002C8: 20280083
  "v_and_b32     v21, 1, v20                            \n"// 0000000002CC: 262A2881
  "v_lshlrev_b32  v8, 3, v21                            \n"// 0000000002D0: 24102A83
  "v_and_b32     v20, 4, v20                            \n"// 0000000002D4: 26282884
  "v_add_u32     v8, v8, v20                            \n"// 0000000002D8: 68102908
  "v_add_u32     v8, v8, s7                             \n"// 0000000002DC: D1340008 00000F08
  "v_add_u32     v8, s45, v8                            \n"// 0000000002E4: 6810102D
  "v_lshlrev_b32  v8, 2, v8                             \n"// 0000000002E8: 24101082
  "buffer_load_dword  v10, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 0000000002EC: E0501000 80060A08
  "v_add_u32     v8, s73, v8                            \n"// 0000000002F4: 68101049
  "buffer_load_dword  v11, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 0000000002F8: E0501000 80060B08
  "v_add_u32     v8, s73, v8                            \n"// 000000000300: 68101049
  "s_add_u32     s56, s80, s79                          \n"// 000000000304: 80384F50
  "v_mov_b32     v20, s56                               \n"// 000000000308: 7E280238
  "v_mul_lo_u32  v21, s74, v20                          \n"// 00000000030C: D2850015 0002284A
  "v_mul_hi_u32  v22, s74, v20                          \n"// 000000000314: D2860016 0002284A
  "s_nop         0x0002                                 \n"// 00000000031C: BF800002
  "v_readfirstlane_b32  s56, v21                        \n"// 000000000320: 7E700515
  "v_readfirstlane_b32  s57, v22                        \n"// 000000000324: 7E720516
  "s_nop         0x0004                                 \n"// 000000000328: BF800004
  "s_add_u32     %[q_res_0], s56, %[q_res_0]                         \n"// 00000000032C: 80101038
  "s_addc_u32    %[q_res_1], s57, %[q_res_1]                         \n"// 000000000330: 82111139
  "s_sub_u32     s56, s81, s80                          \n"// 000000000334: 80B85051
  "s_mul_i32     s56, s56, s74                          \n"// 000000000338: 92384A38
  "s_mov_b32     %[q_res_2], s56                               \n"// 00000000033C: BE920038
  "s_mul_i32     s56, s7, 0x00000480                    \n"// 000000000340: 9238FF07 00000480
  "v_lshlrev_b32  v30, 2, %[threadIdxx]                            \n"// 000000000348: 243C0082
  "v_add_u32     v30, s56, v30                          \n"// 00000000034C: 683C3C38
  "s_mul_i32     s56, s7, 0x00001420                    \n"// 000000000350: 9238FF07 00001420
  "s_add_u32     s34, 0, s56                            \n"// 000000000358: 80223880
  "s_add_u32     s35, 0x00005080, s34                   \n"// 00000000035C: 802322FF 00005080
  "s_add_u32     s36, 0x00005080, s35                   \n"// 000000000364: 802423FF 00005080
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 00000000036C: 20280084
  "v_lshlrev_b32  v21, 2, v20                           \n"// 000000000370: 242A2882
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000000374: 2628008F
  "v_lshrrev_b32  v22, 2, v20                           \n"// 000000000378: 202C2882
  "v_mul_i32_i24  v22, 0x00000140, v22                  \n"// 00000000037C: 0C2C2CFF 00000140
  "v_add_u32     v21, v22, v21                          \n"// 000000000384: 682A2B16
  "v_and_b32     v20, 3, %[threadIdxx]                             \n"// 000000000388: 26280083
  "v_mul_i32_i24  v22, 0x00000508, v20                  \n"// 00000000038C: 0C2C28FF 00000508
  "v_add_u32     v21, v22, v21                          \n"// 000000000394: 682A2B16
  "v_lshlrev_b32  v29, 2, v21                           \n"// 000000000398: 243A2A82
  "s_mov_b32     m0, s34                                \n"// 00000000039C: BEFC0022
  "v_add_u32     v28, 0, v30                            \n"// 0000000003A0: 68383C80
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000003A4: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000003AC: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000003B4: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000003BC: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000003C4: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000003CC: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000003D4: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000003DC: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000003E4: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000003EC: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000003F4: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000003FC: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000404: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 00000000040C: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000414: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 00000000041C: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000424: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 00000000042C: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 000000000434: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 00000000043C: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 000000000444: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 00000000044C: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000454: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 00000000045C: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 000000000464: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 00000000046C: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000474: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 00000000047C: 683838FF 00001200
  "s_mov_b32     m0, s35                                \n"// 000000000484: BEFC0023
  "v_add_u32     v28, 0x00004800, v30                   \n"// 000000000488: 68383CFF 00004800
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000490: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000498: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000004A0: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000004A8: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000004B0: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000004B8: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000004C0: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000004C8: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000004D0: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000004D8: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000004E0: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000004E8: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000004F0: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000004F8: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000500: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000508: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000510: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 000000000518: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 000000000520: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000528: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 000000000530: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000538: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000540: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000548: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 000000000550: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 000000000558: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000560: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 000000000568: 683838FF 00001200
  "s_waitcnt     vmcnt(20)                              \n"// 000000000570: BF8C4F74
  "s_barrier                                            \n"// 000000000574: BF8A0000
  "s_mov_b32     m0, s36                                \n"// 000000000578: BEFC0024
  "v_add_u32     v28, 0x00009000, v30                   \n"// 00000000057C: 68383CFF 00009000
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000584: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 00000000058C: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000594: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 00000000059C: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000005A4: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000005AC: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000005B4: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000005BC: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000005C4: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000005CC: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000005D4: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000005DC: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000005E4: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000005EC: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000005F4: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000005FC: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000604: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 00000000060C: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 000000000614: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 00000000061C: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 000000000624: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 00000000062C: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000634: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 00000000063C: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 000000000644: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 00000000064C: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000654: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 00000000065C: 683838FF 00001200
  "s_cmp_eq_i32  s7, 0                                  \n"// 000000000664: BF008007
  "s_cbranch_scc0  label_01C0                           \n"// 000000000668: BF840025
  "ds_read_b128  acc[0:3], v29                          \n"// 00000000066C: DBFE0000 0000001D
  "ds_read_b128  acc[4:7], v29 offset:64                \n"// 000000000674: DBFE0040 0400001D
  "ds_read_b128  acc[8:11], v29 offset:128              \n"// 00000000067C: DBFE0080 0800001D
  "ds_read_b128  acc[12:15], v29 offset:192             \n"// 000000000684: DBFE00C0 0C00001D
  "ds_read_b128  acc[16:19], v29 offset:256             \n"// 00000000068C: DBFE0100 1000001D
  "ds_read_b128  acc[20:23], v29 offset:320             \n"// 000000000694: DBFE0140 1400001D
  "ds_read_b128  acc[24:27], v29 offset:384             \n"// 00000000069C: DBFE0180 1800001D
  "ds_read_b128  acc[28:31], v29 offset:448             \n"// 0000000006A4: DBFE01C0 1C00001D
  "ds_read_b128  acc[32:35], v29 offset:512             \n"// 0000000006AC: DBFE0200 2000001D
  "ds_read_b128  acc[36:39], v29 offset:576             \n"// 0000000006B4: DBFE0240 2400001D
  "ds_read_b128  acc[40:43], v29 offset:640             \n"// 0000000006BC: DBFE0280 2800001D
  "ds_read_b128  acc[44:47], v29 offset:704             \n"// 0000000006C4: DBFE02C0 2C00001D
  "ds_read_b128  acc[48:51], v29 offset:768             \n"// 0000000006CC: DBFE0300 3000001D
  "ds_read_b128  acc[52:55], v29 offset:832             \n"// 0000000006D4: DBFE0340 3400001D
  "ds_read_b128  acc[56:59], v29 offset:896             \n"// 0000000006DC: DBFE0380 3800001D
  "ds_read_b128  acc[60:63], v29 offset:960             \n"// 0000000006E4: DBFE03C0 3C00001D
  "ds_read_b128  acc[64:67], v29 offset:1024            \n"// 0000000006EC: DBFE0400 4000001D
  "ds_read_b128  acc[68:71], v29 offset:1088            \n"// 0000000006F4: DBFE0440 4400001D
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000006FC: BF8CC07F
"label_01C0: \n"
  "s_waitcnt     vmcnt(20)                              \n"// 000000000700: BF8C4F74
  "s_barrier                                            \n"// 000000000704: BF8A0000
  "s_mov_b32     m0, s34                                \n"// 000000000708: BEFC0022
  "v_add_u32     v28, 0x0000d800, v30                   \n"// 00000000070C: 68383CFF 0000D800
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000714: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 00000000071C: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000724: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 00000000072C: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 000000000734: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 00000000073C: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 000000000744: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 00000000074C: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 000000000754: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 00000000075C: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 000000000764: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 00000000076C: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 000000000774: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 00000000077C: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 000000000784: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 00000000078C: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 000000000794: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 00000000079C: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000007A4: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000007AC: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000007B4: 683838FF 00001200
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen lds    \n"// 0000000007BC: E0511000 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:256 lds\n"// 0000000007C4: E0511100 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:512 lds\n"// 0000000007CC: E0511200 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:768 lds\n"// 0000000007D4: E0511300 8004001C
  "buffer_load_dword   v28, [%[q_res_0], %[q_res_1], %[q_res_2], %[q_res_3]], 0 offen offset:1024 lds\n"// 0000000007DC: E0511400 8004001C
  "s_add_u32     m0, m0, 0x00000500                     \n"// 0000000007E4: 807CFF7C 00000500
  "v_add_u32     v28, 0x00001200, v28                   \n"// 0000000007EC: 683838FF 00001200
  "s_cmp_eq_i32  s7, 1                                  \n"// 0000000007F4: BF008107
  "s_cbranch_scc0  label_0224                           \n"// 0000000007F8: BF840025
  "ds_read_b128  acc[0:3], v29 offset:20608             \n"// 0000000007FC: DBFE5080 0000001D
  "ds_read_b128  acc[4:7], v29 offset:20672             \n"// 000000000804: DBFE50C0 0400001D
  "ds_read_b128  acc[8:11], v29 offset:20736            \n"// 00000000080C: DBFE5100 0800001D
  "ds_read_b128  acc[12:15], v29 offset:20800           \n"// 000000000814: DBFE5140 0C00001D
  "ds_read_b128  acc[16:19], v29 offset:20864           \n"// 00000000081C: DBFE5180 1000001D
  "ds_read_b128  acc[20:23], v29 offset:20928           \n"// 000000000824: DBFE51C0 1400001D
  "ds_read_b128  acc[24:27], v29 offset:20992           \n"// 00000000082C: DBFE5200 1800001D
  "ds_read_b128  acc[28:31], v29 offset:21056           \n"// 000000000834: DBFE5240 1C00001D
  "ds_read_b128  acc[32:35], v29 offset:21120           \n"// 00000000083C: DBFE5280 2000001D
  "ds_read_b128  acc[36:39], v29 offset:21184           \n"// 000000000844: DBFE52C0 2400001D
  "ds_read_b128  acc[40:43], v29 offset:21248           \n"// 00000000084C: DBFE5300 2800001D
  "ds_read_b128  acc[44:47], v29 offset:21312           \n"// 000000000854: DBFE5340 2C00001D
  "ds_read_b128  acc[48:51], v29 offset:21376           \n"// 00000000085C: DBFE5380 3000001D
  "ds_read_b128  acc[52:55], v29 offset:21440           \n"// 000000000864: DBFE53C0 3400001D
  "ds_read_b128  acc[56:59], v29 offset:21504           \n"// 00000000086C: DBFE5400 3800001D
  "ds_read_b128  acc[60:63], v29 offset:21568           \n"// 000000000874: DBFE5440 3C00001D
  "ds_read_b128  acc[64:67], v29 offset:21632           \n"// 00000000087C: DBFE5480 4000001D
  "ds_read_b128  acc[68:71], v29 offset:21696           \n"// 000000000884: DBFE54C0 4400001D
  "s_waitcnt     lgkmcnt(0)                             \n"// 00000000088C: BF8CC07F
"label_0224:\n"
  "s_waitcnt     vmcnt(20)                              \n"// 000000000890: BF8C4F74
  "s_barrier                                            \n"// 000000000894: BF8A0000
  "s_cmp_eq_i32  s7, 2                                  \n"// 000000000898: BF008207
  "s_cbranch_scc0  label_024D                           \n"// 00000000089C: BF840025
  "ds_read_b128  acc[0:3], v29 offset:41216             \n"// 0000000008A0: DBFEA100 0000001D
  "ds_read_b128  acc[4:7], v29 offset:41280             \n"// 0000000008A8: DBFEA140 0400001D
  "ds_read_b128  acc[8:11], v29 offset:41344            \n"// 0000000008B0: DBFEA180 0800001D
  "ds_read_b128  acc[12:15], v29 offset:41408           \n"// 0000000008B8: DBFEA1C0 0C00001D
  "ds_read_b128  acc[16:19], v29 offset:41472           \n"// 0000000008C0: DBFEA200 1000001D
  "ds_read_b128  acc[20:23], v29 offset:41536           \n"// 0000000008C8: DBFEA240 1400001D
  "ds_read_b128  acc[24:27], v29 offset:41600           \n"// 0000000008D0: DBFEA280 1800001D
  "ds_read_b128  acc[28:31], v29 offset:41664           \n"// 0000000008D8: DBFEA2C0 1C00001D
  "ds_read_b128  acc[32:35], v29 offset:41728           \n"// 0000000008E0: DBFEA300 2000001D
  "ds_read_b128  acc[36:39], v29 offset:41792           \n"// 0000000008E8: DBFEA340 2400001D
  "ds_read_b128  acc[40:43], v29 offset:41856           \n"// 0000000008F0: DBFEA380 2800001D
  "ds_read_b128  acc[44:47], v29 offset:41920           \n"// 0000000008F8: DBFEA3C0 2C00001D
  "ds_read_b128  acc[48:51], v29 offset:41984           \n"// 000000000900: DBFEA400 3000001D
  "ds_read_b128  acc[52:55], v29 offset:42048           \n"// 000000000908: DBFEA440 3400001D
  "ds_read_b128  acc[56:59], v29 offset:42112           \n"// 000000000910: DBFEA480 3800001D
  "ds_read_b128  acc[60:63], v29 offset:42176           \n"// 000000000918: DBFEA4C0 3C00001D
  "ds_read_b128  acc[64:67], v29 offset:42240           \n"// 000000000920: DBFEA500 4000001D
  "ds_read_b128  acc[68:71], v29 offset:42304           \n"// 000000000928: DBFEA540 4400001D
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000000930: BF8CC07F
"label_024D: \n"
  "s_waitcnt     vmcnt(0)                               \n"// 000000000934: BF8C0F70
  "s_barrier                                            \n"// 000000000938: BF8A0000
  "s_cmp_eq_i32  s7, 3                                  \n"// 00000000093C: BF008307
  "s_cbranch_scc0  label_0276                           \n"// 000000000940: BF840025
  "ds_read_b128  acc[0:3], v29                          \n"// 000000000944: DBFE0000 0000001D
  "ds_read_b128  acc[4:7], v29 offset:64                \n"// 00000000094C: DBFE0040 0400001D
  "ds_read_b128  acc[8:11], v29 offset:128              \n"// 000000000954: DBFE0080 0800001D
  "ds_read_b128  acc[12:15], v29 offset:192             \n"// 00000000095C: DBFE00C0 0C00001D
  "ds_read_b128  acc[16:19], v29 offset:256             \n"// 000000000964: DBFE0100 1000001D
  "ds_read_b128  acc[20:23], v29 offset:320             \n"// 00000000096C: DBFE0140 1400001D
  "ds_read_b128  acc[24:27], v29 offset:384             \n"// 000000000974: DBFE0180 1800001D
  "ds_read_b128  acc[28:31], v29 offset:448             \n"// 00000000097C: DBFE01C0 1C00001D
  "ds_read_b128  acc[32:35], v29 offset:512             \n"// 000000000984: DBFE0200 2000001D
  "ds_read_b128  acc[36:39], v29 offset:576             \n"// 00000000098C: DBFE0240 2400001D
  "ds_read_b128  acc[40:43], v29 offset:640             \n"// 000000000994: DBFE0280 2800001D
  "ds_read_b128  acc[44:47], v29 offset:704             \n"// 00000000099C: DBFE02C0 2C00001D
  "ds_read_b128  acc[48:51], v29 offset:768             \n"// 0000000009A4: DBFE0300 3000001D
  "ds_read_b128  acc[52:55], v29 offset:832             \n"// 0000000009AC: DBFE0340 3400001D
  "ds_read_b128  acc[56:59], v29 offset:896             \n"// 0000000009B4: DBFE0380 3800001D
  "ds_read_b128  acc[60:63], v29 offset:960             \n"// 0000000009BC: DBFE03C0 3C00001D
  "ds_read_b128  acc[64:67], v29 offset:1024            \n"// 0000000009C4: DBFE0400 4000001D
  "ds_read_b128  acc[68:71], v29 offset:1088            \n"// 0000000009CC: DBFE0440 4400001D
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000009D4: BF8CC07F
"label_0276: \n"
  "s_waitcnt     vmcnt(0)                               \n"// 0000000009D8: BF8C0F70
  "s_barrier                                            \n"// 0000000009DC: BF8A0000
  "s_mov_b32     s52, 0x07060302                        \n"// 0000000009E0: BEB400FF 07060302
  "s_mov_b32     s53, 0x05040100                        \n"// 0000000009E8: BEB500FF 05040100
  "s_mov_b32     s6, 0x3fb8aa3b                         \n"// 0000000009F0: BE8600FF 3FB8AA3B
  "v_mov_b32     v21, s6                                \n"// 0000000009F8: 7E2A0206
  "v_mov_b32     v20, %[s_scalar]                       \n"// 0000000009FC: 7E280240
  "v_mul_f32     v20, s6, v20                           \n"// 000000000A00: 0A282806
  "v_rcp_f32     v21, v21                               \n"// 000000000A04: 7E2A4515
  "v_mov_b32     v12, 0xff7fffff                        \n"// 000000000A08: 7E1802FF FF7FFFFF
  "v_mov_b32     v13, 0xff7fffff                        \n"// 000000000A10: 7E1A02FF FF7FFFFF
  "v_mov_b32     v16, 0                                 \n"// 000000000A18: 7E200280
  "v_mov_b32     v17, 0                                 \n"// 000000000A1C: 7E220280
  "v_mov_b32     v14, 0                                 \n"// 000000000A20: 7E1C0280
  "v_mov_b32     v15, 0                                 \n"// 000000000A24: 7E1E0280
  "v_mov_b32     v9, %[s_page_block_size]                                \n"// 000000000A28: 7E120244
  "v_readfirstlane_b32  s5, v20                         \n"// 000000000A2C: 7E0A0514
  "v_readfirstlane_b32  s63, v21                        \n"// 000000000A30: 7E7E0515
  "v_and_b32     v2, 15, %[threadIdxx]                             \n"// 000000000A34: 2604008F
  "v_lshlrev_b32  v2, 2, v2                             \n"// 000000000A38: 24040482
  "s_mul_i32     s56, 0x00000100, s7                    \n"// 000000000A3C: 923807FF 00000100
  "v_add_u32     v2, s56, v2                            \n"// 000000000A44: 68040438
  "v_lshlrev_b32  v3, 2, %[threadIdxx]                             \n"// 000000000A48: 24060082
  "s_mul_i32     s56, 0x00000100, s7                    \n"// 000000000A4C: 923807FF 00000100
  "v_add_u32     v3, s56, v3                            \n"// 000000000A54: 68060638
  "v_and_b32     v20, 31, %[threadIdxx]                            \n"// 000000000A58: 2628009F
  "v_lshlrev_b32  v1, 2, v20                            \n"// 000000000A5C: 24022882
  "s_mul_i32     s34, s7, 0x00001220                    \n"// 000000000A60: 9222FF07 00001220
  "s_add_u32     s34, 0, s34                            \n"// 000000000A68: 80222280
  "s_add_u32     s35, 0x00000900, s34                   \n"// 000000000A6C: 802322FF 00000900
  "s_add_u32     s36, 0x00004880, s34                   \n"// 000000000A74: 802422FF 00004880
  "s_add_u32     s37, 0x00004880, s35                   \n"// 000000000A7C: 802523FF 00004880
  "s_waitcnt     vmcnt(0)                               \n"// 000000000A84: BF8C0F70
  "v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"// 000000000A88: 102412FA FF01500A
  "v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"// 000000000A90: 102612FA FF01580A
  "v_add_u32     v18, v18, v1                           \n"// 000000000A98: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 000000000A9C: 68260313
  "s_mov_b32     m0, s34                                \n"// 000000000AA0: BEFC0022
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000000AA4: E0511000 80050012
  "s_add_u32     m0, 0, s35                             \n"// 000000000AAC: 807C2380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000000AB0: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s34                    \n"// 000000000AB8: 807C22FF 00000080
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000000AC0: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s35                    \n"// 000000000AC8: 807C23FF 00000080
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000000AD0: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s34                    \n"// 000000000AD8: 807C22FF 00000100
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000000AE0: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s35                    \n"// 000000000AE8: 807C23FF 00000100
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000000AF0: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s34                    \n"// 000000000AF8: 807C22FF 00000180
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000000B00: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s35                    \n"// 000000000B08: 807C23FF 00000180
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000000B10: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s34                    \n"// 000000000B18: 807C22FF 00000200
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000000B20: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s35                    \n"// 000000000B28: 807C23FF 00000200
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000000B30: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s34                    \n"// 000000000B38: 807C22FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000000B40: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s35                    \n"// 000000000B48: 807C23FF 00000280
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000000B50: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s34                    \n"// 000000000B58: 807C22FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000000B60: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s35                    \n"// 000000000B68: 807C23FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000000B70: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s34                    \n"// 000000000B78: 807C22FF 00000380
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000000B80: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s35                    \n"// 000000000B88: 807C23FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000000B90: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s34                    \n"// 000000000B98: 807C22FF 00000400
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000000BA0: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s35                    \n"// 000000000BA8: 807C23FF 00000400
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000000BB0: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s34                    \n"// 000000000BB8: 807C22FF 00000480
  "buffer_load_dword  v10, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000000BC0: E0501000 80060A08
  "v_add_u32     v8, s73, v8                            \n"// 000000000BC8: 68101049
  "v_mov_b32     %[o_regs_0], 0                                 \n"// 000000000BCC: 7E500280
  "v_mov_b32     %[o_regs_1], 0                                 \n"// 000000000BD0: 7E520280
  "v_mov_b32     %[o_regs_2], 0                                 \n"// 000000000BD4: 7E540280
  "v_mov_b32     %[o_regs_3], 0                                 \n"// 000000000BD8: 7E560280
  "v_mov_b32     %[o_regs_4], 0                                 \n"// 000000000BDC: 7E580280
  "v_mov_b32     %[o_regs_5], 0                                 \n"// 000000000BE0: 7E5A0280
  "v_mov_b32     %[o_regs_6], 0                                 \n"// 000000000BE4: 7E5C0280
  "v_mov_b32     %[o_regs_7], 0                                 \n"// 000000000BE8: 7E5E0280
  "v_mov_b32     %[o_regs_8], 0                                 \n"// 000000000BEC: 7E600280
  "v_mov_b32     %[o_regs_9], 0                                 \n"// 000000000BF0: 7E620280
  "v_mov_b32     %[o_regs_10], 0                                 \n"// 000000000BF4: 7E640280
  "v_mov_b32     %[o_regs_11], 0                                 \n"// 000000000BF8: 7E660280
  "v_mov_b32     %[o_regs_12], 0                                 \n"// 000000000BFC: 7E680280
  "v_mov_b32     %[o_regs_13], 0                                 \n"// 000000000C00: 7E6A0280
  "v_mov_b32     %[o_regs_14], 0                                 \n"// 000000000C04: 7E6C0280
  "v_mov_b32     %[o_regs_15], 0                                 \n"// 000000000C08: 7E6E0280
  "v_mov_b32     %[o_regs_16], 0                                 \n"// 000000000C0C: 7E700280
  "v_mov_b32     %[o_regs_17], 0                                 \n"// 000000000C10: 7E720280
  "v_mov_b32     %[o_regs_18], 0                                 \n"// 000000000C14: 7E740280
  "v_mov_b32     %[o_regs_19], 0                                 \n"// 000000000C18: 7E760280
  "v_mov_b32     %[o_regs_20], 0                                 \n"// 000000000C1C: 7E780280
  "v_mov_b32     %[o_regs_21], 0                                 \n"// 000000000C20: 7E7A0280
  "v_mov_b32     %[o_regs_22], 0                                 \n"// 000000000C24: 7E7C0280
  "v_mov_b32     %[o_regs_23], 0                                 \n"// 000000000C28: 7E7E0280
  "v_mov_b32     %[o_regs_24], 0                                 \n"// 000000000C2C: 7E800280
  "v_mov_b32     %[o_regs_25], 0                                 \n"// 000000000C30: 7E820280
  "v_mov_b32     %[o_regs_26], 0                                 \n"// 000000000C34: 7E840280
  "v_mov_b32     %[o_regs_27], 0                                 \n"// 000000000C38: 7E860280
  "v_mov_b32     %[o_regs_28], 0                                 \n"// 000000000C3C: 7E880280
  "v_mov_b32     %[o_regs_29], 0                                 \n"// 000000000C40: 7E8A0280
  "v_mov_b32     %[o_regs_30], 0                                 \n"// 000000000C44: 7E8C0280
  "v_mov_b32     %[o_regs_31], 0                                 \n"// 000000000C48: 7E8E0280
  "v_mov_b32     %[o_regs_32], 0                                 \n"// 000000000C4C: 7E900280
  "v_mov_b32     %[o_regs_33], 0                                 \n"// 000000000C50: 7E920280
  "v_mov_b32     %[o_regs_34], 0                                 \n"// 000000000C54: 7E940280
  "v_mov_b32     %[o_regs_35], 0                                 \n"// 000000000C58: 7E960280
  "v_mov_b32     %[o_regs_36], 0                                 \n"// 000000000C5C: 7E980280
  "v_mov_b32     %[o_regs_37], 0                                 \n"// 000000000C60: 7E9A0280
  "v_mov_b32     %[o_regs_38], 0                                 \n"// 000000000C64: 7E9C0280
  "v_mov_b32     %[o_regs_39], 0                                 \n"// 000000000C68: 7E9E0280
  "v_mov_b32     %[o_regs_40], 0                                 \n"// 000000000C6C: 7EA00280
  "v_mov_b32     %[o_regs_41], 0                                 \n"// 000000000C70: 7EA20280
  "v_mov_b32     %[o_regs_42], 0                                 \n"// 000000000C74: 7EA40280
  "v_mov_b32     %[o_regs_43], 0                                 \n"// 000000000C78: 7EA60280
  "v_mov_b32     %[o_regs_44], 0                                 \n"// 000000000C7C: 7EA80280
  "v_mov_b32     %[o_regs_45], 0                                 \n"// 000000000C80: 7EAA0280
  "v_mov_b32     %[o_regs_46], 0                                 \n"// 000000000C84: 7EAC0280
  "v_mov_b32     %[o_regs_47], 0                                 \n"// 000000000C88: 7EAE0280
  "v_mov_b32     %[o_regs_48], 0                                 \n"// 000000000C8C: 7EB00280
  "v_mov_b32     %[o_regs_49], 0                                 \n"// 000000000C90: 7EB20280
  "v_mov_b32     %[o_regs_50], 0                                 \n"// 000000000C94: 7EB40280
  "v_mov_b32     %[o_regs_51], 0                                 \n"// 000000000C98: 7EB60280
  "v_mov_b32     %[o_regs_52], 0                                 \n"// 000000000C9C: 7EB80280
  "v_mov_b32     %[o_regs_53], 0                                 \n"// 000000000CA0: 7EBA0280
  "v_mov_b32     %[o_regs_54], 0                                 \n"// 000000000CA4: 7EBC0280
  "v_mov_b32     %[o_regs_55], 0                                 \n"// 000000000CA8: 7EBE0280
  "v_mov_b32     %[o_regs_56], 0                                 \n"// 000000000CAC: 7EC00280
  "v_mov_b32     %[o_regs_57], 0                                 \n"// 000000000CB0: 7EC20280
  "v_mov_b32     %[o_regs_58], 0                                 \n"// 000000000CB4: 7EC40280
  "v_mov_b32     %[o_regs_59], 0                                 \n"// 000000000CB8: 7EC60280
  "v_mov_b32     %[o_regs_60], 0                                \n"// 000000000CBC: 7EC80280
  "v_mov_b32     %[o_regs_61], 0                                \n"// 000000000CC0: 7ECA0280
  "v_mov_b32     %[o_regs_62], 0                                \n"// 000000000CC4: 7ECC0280
  "v_mov_b32     %[o_regs_63], 0                                \n"// 000000000CC8: 7ECE0280
  "v_mov_b32     %[o_regs_64], 0                                \n"// 000000000CCC: 7ED00280
  "v_mov_b32     %[o_regs_65], 0                                \n"// 000000000CD0: 7ED20280
  "v_mov_b32     %[o_regs_66], 0                                \n"// 000000000CD4: 7ED40280
  "v_mov_b32     %[o_regs_67], 0                                \n"// 000000000CD8: 7ED60280
  "v_mov_b32     %[o_regs_68], 0                                \n"// 000000000CDC: 7ED80280
  "v_mov_b32     %[o_regs_69], 0                                \n"// 000000000CE0: 7EDA0280
  "v_mov_b32     %[o_regs_70], 0                                \n"// 000000000CE4: 7EDC0280
  "v_mov_b32     %[o_regs_71], 0                                \n"// 000000000CE8: 7EDE0280
  "v_mov_b32     %[o_regs_72], 0                                \n"// 000000000CEC: 7EE00280
  "v_mov_b32     %[o_regs_73], 0                                \n"// 000000000CF0: 7EE20280
  "v_mov_b32     %[o_regs_74], 0                                \n"// 000000000CF4: 7EE40280
  "v_mov_b32     %[o_regs_75], 0                                \n"// 000000000CF8: 7EE60280
  "v_mov_b32     %[o_regs_76], 0                                \n"// 000000000CFC: 7EE80280
  "v_mov_b32     %[o_regs_77], 0                                \n"// 000000000D00: 7EEA0280
  "v_mov_b32     %[o_regs_78], 0                                \n"// 000000000D04: 7EEC0280
  "v_mov_b32     %[o_regs_79], 0                                \n"// 000000000D08: 7EEE0280
  "v_mov_b32     %[o_regs_80], 0                                \n"// 000000000D0C: 7EF00280
  "v_mov_b32     %[o_regs_81], 0                                \n"// 000000000D10: 7EF20280
  "v_mov_b32     %[o_regs_82], 0                                \n"// 000000000D14: 7EF40280
  "v_mov_b32     %[o_regs_83], 0                                \n"// 000000000D18: 7EF60280
  "v_mov_b32     %[o_regs_84], 0                                \n"// 000000000D1C: 7EF80280
  "v_mov_b32     %[o_regs_85], 0                                \n"// 000000000D20: 7EFA0280
  "v_mov_b32     %[o_regs_86], 0                                \n"// 000000000D24: 7EFC0280
  "v_mov_b32     %[o_regs_87], 0                                \n"// 000000000D28: 7EFE0280
  "v_mov_b32     %[o_regs_88], 0                                \n"// 000000000D2C: 7F000280
  "v_mov_b32     %[o_regs_89], 0                                \n"// 000000000D30: 7F020280
  "v_mov_b32     %[o_regs_90], 0                                \n"// 000000000D34: 7F040280
  "v_mov_b32     %[o_regs_91], 0                                \n"// 000000000D38: 7F060280
  "v_mov_b32     %[o_regs_92], 0                                \n"// 000000000D3C: 7F080280
  "v_mov_b32     %[o_regs_93], 0                                \n"// 000000000D40: 7F0A0280
  "v_mov_b32     %[o_regs_94], 0                                \n"// 000000000D44: 7F0C0280
  "v_mov_b32     %[o_regs_95], 0                                \n"// 000000000D48: 7F0E0280
  "v_mov_b32     %[o_regs_96], 0                                \n"// 000000000D4C: 7F100280
  "v_mov_b32     %[o_regs_97], 0                                \n"// 000000000D50: 7F120280
  "v_mov_b32     %[o_regs_98], 0                                \n"// 000000000D54: 7F140280
  "v_mov_b32     %[o_regs_99], 0                                \n"// 000000000D58: 7F160280
  "v_mov_b32     %[o_regs_100], 0                                \n"// 000000000D5C: 7F180280
  "v_mov_b32     %[o_regs_101], 0                                \n"// 000000000D60: 7F1A0280
  "v_mov_b32     %[o_regs_102], 0                                \n"// 000000000D64: 7F1C0280
  "v_mov_b32     %[o_regs_103], 0                                \n"// 000000000D68: 7F1E0280
  "v_mov_b32     %[o_regs_104], 0                                \n"// 000000000D6C: 7F200280
  "v_mov_b32     %[o_regs_105], 0                                \n"// 000000000D70: 7F220280
  "v_mov_b32     %[o_regs_106], 0                                \n"// 000000000D74: 7F240280
  "v_mov_b32     %[o_regs_107], 0                                \n"// 000000000D78: 7F260280
  "v_mov_b32     %[o_regs_108], 0                                \n"// 000000000D7C: 7F280280
  "v_mov_b32     %[o_regs_109], 0                                \n"// 000000000D80: 7F2A0280
  "v_mov_b32     %[o_regs_110], 0                                \n"// 000000000D84: 7F2C0280
  "v_mov_b32     %[o_regs_111], 0                                \n"// 000000000D88: 7F2E0280
  "v_mov_b32     %[o_regs_112], 0                                \n"// 000000000D8C: 7F300280
  "v_mov_b32     %[o_regs_113], 0                                \n"// 000000000D90: 7F320280
  "v_mov_b32     %[o_regs_114], 0                                \n"// 000000000D94: 7F340280
  "v_mov_b32     %[o_regs_115], 0                                \n"// 000000000D98: 7F360280
  "v_mov_b32     %[o_regs_116], 0                                \n"// 000000000D9C: 7F380280
  "v_mov_b32     %[o_regs_117], 0                                \n"// 000000000DA0: 7F3A0280
  "v_mov_b32     %[o_regs_118], 0                                \n"// 000000000DA4: 7F3C0280
  "v_mov_b32     %[o_regs_119], 0                                \n"// 000000000DA8: 7F3E0280
  "v_mov_b32     %[o_regs_120], 0                                \n"// 000000000DAC: 7F400280
  "v_mov_b32     %[o_regs_121], 0                                \n"// 000000000DB0: 7F420280
  "v_mov_b32     %[o_regs_122], 0                                \n"// 000000000DB4: 7F440280
  "v_mov_b32     %[o_regs_123], 0                                \n"// 000000000DB8: 7F460280
  "v_mov_b32     %[o_regs_124], 0                                \n"// 000000000DBC: 7F480280
  "v_mov_b32     %[o_regs_125], 0                                \n"// 000000000DC0: 7F4A0280
  "v_mov_b32     %[o_regs_126], 0                                \n"// 000000000DC4: 7F4C0280
  "v_mov_b32     %[o_regs_127], 0                                \n"// 000000000DC8: 7F4E0280
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000000DCC: 20280084
  "v_mul_i32_i24  v21, 4, v20                           \n"// 000000000DD0: 0C2A2884
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000000DD4: 2628008F
  "v_and_b32     v22, 3, v20                            \n"// 000000000DD8: 262C2883
  "v_mul_i32_i24  v22, 0x00000488, v22                  \n"// 000000000DDC: 0C2C2CFF 00000488
  "v_add_u32     v4, v22, v21                           \n"// 000000000DE4: 68082B16
  "v_lshrrev_b32  v20, 2, v20                           \n"// 000000000DE8: 20282882
  "v_and_b32     v21, 1, v20                            \n"// 000000000DEC: 262A2881
  "v_mul_i32_i24  v21, 32, v21                          \n"// 000000000DF0: 0C2A2AA0
  "v_add_u32     v4, v4, v21                            \n"// 000000000DF4: 68082B04
  "v_and_b32     v21, 2, v20                            \n"// 000000000DF8: 262A2882
  "v_mul_i32_i24  v21, 0x00000120, v21                  \n"// 000000000DFC: 0C2A2AFF 00000120
  "v_add_u32     v4, v4, v21                            \n"// 000000000E04: 68082B04
  "v_lshlrev_b32  v4, 2, v4                             \n"// 000000000E08: 24080882
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000000E0C: 20280084
  "v_and_b32     v21, 1, v20                            \n"// 000000000E10: 262A2881
  "v_mul_i32_i24  v5, 32, v21                           \n"// 000000000E14: 0C0A2AA0
  "v_and_b32     v21, 2, v20                            \n"// 000000000E18: 262A2882
  "v_mul_i32_i24  v21, 0x00000120, v21                  \n"// 000000000E1C: 0C2A2AFF 00000120
  "v_add_u32     v5, v5, v21                            \n"// 000000000E24: 680A2B05
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000000E28: 2628008F
  "v_mul_i32_i24  v21, 2, v20                           \n"// 000000000E2C: 0C2A2882
  "v_add_u32     v5, v5, v21                            \n"// 000000000E30: 680A2B05
  "s_mul_i32     s56, 64, s7                            \n"// 000000000E34: 923807C0
  "v_add_u32     v5, v5, s56                            \n"// 000000000E38: D1340005 00007105
  "v_lshlrev_b32  v5, 2, v5                             \n"// 000000000E40: 240A0A82
  "v_lshlrev_b32  v6, 2, %[threadIdxx]                             \n"// 000000000E44: 240C0082
  "s_mul_i32     s56, 0x00000200, s7                    \n"// 000000000E48: 923807FF 00000200
  "v_add_u32     v6, v6, s56                            \n"// 000000000E50: D1340006 00007106
  "v_lshlrev_b32  v6, 2, v6                             \n"// 000000000E58: 240C0C82
  "v_lshlrev_b32  v7, 4, %[threadIdxx]                             \n"// 000000000E5C: 240E0084
  "v_mul_u32_u24  v18, v11, v9 row_newbcast:0           \n"// 000000000E60: 102412FA FF01500B
  "v_mul_u32_u24  v19, v11, v9 row_newbcast:8           \n"// 000000000E68: 102612FA FF01580B
  "v_add_u32     v18, v18, v1                           \n"// 000000000E70: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 000000000E74: 68260313
  "s_mov_b32     m0, s36                                \n"// 000000000E78: BEFC0024
  "buffer_load_dword  v11, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000000E7C: E0501000 80060B08
  "v_add_u32     v8, s73, v8                            \n"// 000000000E84: 68101049
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000000E88: E0511000 80050012
  "s_add_u32     m0, 0, s37                             \n"// 000000000E90: 807C2580
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000000E94: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s36                    \n"// 000000000E9C: 807C24FF 00000080
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000000EA4: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s37                    \n"// 000000000EAC: 807C25FF 00000080
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000000EB4: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s36                    \n"// 000000000EBC: 807C24FF 00000100
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000000EC4: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s37                    \n"// 000000000ECC: 807C25FF 00000100
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000000ED4: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s36                    \n"// 000000000EDC: 807C24FF 00000180
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000000EE4: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s37                    \n"// 000000000EEC: 807C25FF 00000180
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000000EF4: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s36                    \n"// 000000000EFC: 807C24FF 00000200
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000000F04: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s37                    \n"// 000000000F0C: 807C25FF 00000200
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000000F14: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s36                    \n"// 000000000F1C: 807C24FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000000F24: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s37                    \n"// 000000000F2C: 807C25FF 00000280
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000000F34: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s36                    \n"// 000000000F3C: 807C24FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000000F44: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s37                    \n"// 000000000F4C: 807C25FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000000F54: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s36                    \n"// 000000000F5C: 807C24FF 00000380
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000000F64: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s37                    \n"// 000000000F6C: 807C25FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000000F74: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s36                    \n"// 000000000F7C: 807C24FF 00000400
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000000F84: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s37                    \n"// 000000000F8C: 807C25FF 00000400
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000000F94: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s36                    \n"// 000000000F9C: 807C24FF 00000480
  "s_waitcnt     vmcnt(19) & lgkmcnt(0)                 \n"// 000000000FA4: BF8C4073
  "s_barrier                                            \n"// 000000000FA8: BF8A0000
  "v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"// 000000000FAC: 102412FA FF01500A
  "v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"// 000000000FB4: 102612FA FF01580A
  "v_add_u32     v18, v18, v1                           \n"// 000000000FBC: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 000000000FC0: 68260313
  "s_mov_b32     m0, s34                                \n"// 000000000FC4: BEFC0022
  "ds_read_b128  acc[144:147], v4                       \n"// 000000000FC8: DBFE0000 90000004
  "ds_read_b128  acc[148:151], v4 offset:64             \n"// 000000000FD0: DBFE0040 94000004
  "ds_read_b128  acc[152:155], v4 offset:256            \n"// 000000000FD8: DBFE0100 98000004
  "ds_read_b128  acc[156:159], v4 offset:320            \n"// 000000000FE0: DBFE0140 9C000004
  "ds_read_b128  acc[160:163], v4 offset:512            \n"// 000000000FE8: DBFE0200 A0000004
  "ds_read_b128  acc[164:167], v4 offset:576            \n"// 000000000FF0: DBFE0240 A4000004
  "ds_read_b128  acc[168:171], v4 offset:768            \n"// 000000000FF8: DBFE0300 A8000004
  "ds_read_b128  acc[172:175], v4 offset:832            \n"// 000000001000: DBFE0340 AC000004
  "ds_read_b128  acc[176:179], v4 offset:1024           \n"// 000000001008: DBFE0400 B0000004
  "ds_read_b128  acc[180:183], v4 offset:1088           \n"// 000000001010: DBFE0440 B4000004
  "ds_read_b128  acc[184:187], v4 offset:1280           \n"// 000000001018: DBFE0500 B8000004
  "ds_read_b128  acc[188:191], v4 offset:1344           \n"// 000000001020: DBFE0540 BC000004
  "ds_read_b128  acc[192:195], v4 offset:1536           \n"// 000000001028: DBFE0600 C0000004
  "ds_read_b128  acc[196:199], v4 offset:1600           \n"// 000000001030: DBFE0640 C4000004
  "ds_read_b128  acc[200:203], v4 offset:1792           \n"// 000000001038: DBFE0700 C8000004
  "ds_read_b128  acc[204:207], v4 offset:1856           \n"// 000000001040: DBFE0740 CC000004
  "ds_read_b128  acc[208:211], v4 offset:2048           \n"// 000000001048: DBFE0800 D0000004
  "ds_read_b128  acc[212:215], v4 offset:2112           \n"// 000000001050: DBFE0840 D4000004
  "ds_read_b64   v[20:21], v5                           \n"// 000000001058: D8EC0000 14000005
  "ds_read_b64   v[22:23], v5 offset:4640               \n"// 000000001060: D8EC1220 16000005
  "ds_read_b64   v[24:25], v5 offset:9280               \n"// 000000001068: D8EC2440 18000005
  "ds_read_b64   v[26:27], v5 offset:13920              \n"// 000000001070: D8EC3660 1A000005
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001078: BF8CC07F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 00000000107C: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000001084: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 00000000108C: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000001094: D1ED00AB 00D2311A
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 00000000109C: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 0000000010A4: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 0000000010AC: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 0000000010B4: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 0000000010BC: D1ED00AB 00D2331B
  "ds_write_b128  v6, v[168:171] offset:38144           \n"// 0000000010C4: D9BE9500 0000A806
  "ds_read_b64   v[20:21], v5 offset:1024               \n"// 0000000010CC: D8EC0400 14000005
  "ds_read_b64   v[22:23], v5 offset:5664               \n"// 0000000010D4: D8EC1620 16000005
  "ds_read_b64   v[24:25], v5 offset:10304              \n"// 0000000010DC: D8EC2840 18000005
  "ds_read_b64   v[26:27], v5 offset:14944              \n"// 0000000010E4: D8EC3A60 1A000005
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000010EC: BF8CC07F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 0000000010F0: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 0000000010F8: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000001100: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000001108: D1ED00AB 00D2311A
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 000000001110: D9BEB100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000001118: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000001120: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000001128: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000001130: D1ED00AB 00D2331B
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000001138: D9BEB500 0000A806
  "s_nop         0x0000                                 \n"// 000000001140: BF800000
  "s_cmp_lt_u32  s71, 1                                 \n"// 000000001144: BF0A8147
  "s_cbranch_scc1  label_0DEC                           \n"// 000000001148: BF850999
  "s_cmp_lt_i32  s7, 2                                  \n"// 00000000114C: BF048207
  "s_cbranch_scc0  label_0921                           \n"// 000000001150: BF8404CC
"label_0455: \n"
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001154: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 000000001158: D3E10020 1A020190

  "ds_read_b128  acc[176:179], v4 offset:1024           \n"// 000000001160: DBFE0400 B0000004
  "ds_read_b128  acc[180:183], v4 offset:1088           \n"// 000000001168: DBFE0440 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 000000001170: D3E10020 1C820592
  "buffer_load_dword  v10, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000001178: E0501000 80060A08
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 000000001180: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 000000001188: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 000000001190: D3E10020 1C821198
  "ds_read_b128  acc[184:187], v4 offset:1280           \n"// 000000001198: DBFE0500 B8000004
  "ds_read_b128  acc[188:191], v4 offset:1344           \n"// 0000000011A0: DBFE0540 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 0000000011A8: D3E10020 1C82159A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 0000000011B0: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 0000000011B8: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000011C0: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 0000000011C4: D3E10020 1C8221A0
  "ds_read_b128  acc[192:195], v4 offset:1536           \n"// 0000000011CC: DBFE0600 C0000004
  "ds_read_b128  acc[196:199], v4 offset:1600           \n"// 0000000011D4: DBFE0640 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 0000000011DC: D3E10020 1C8225A2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 0000000011E4: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 0000000011EC: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 0000000011F4: D3E10020 1C8231A8
  "ds_read_b128  acc[200:203], v4 offset:1792           \n"// 0000000011FC: DBFE0700 C8000004
  "ds_read_b128  acc[204:207], v4 offset:1856           \n"// 000000001204: DBFE0740 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 00000000120C: D3E10020 1C8235AA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 000000001214: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 00000000121C: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001224: BF8CC47F
  "s_barrier                                            \n"// 000000001228: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 00000000122C: D3E10020 1C8241B0
  "ds_read_b128  acc[208:211], v4 offset:2048           \n"// 000000001234: DBFE0800 D0000004
  "ds_read_b128  acc[212:215], v4 offset:2112           \n"// 00000000123C: DBFE0840 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 000000001244: D3E10020 1C8245B2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 00000000124C: D3E10020 1C8249B4
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000001254: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 00000000125C: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000001264: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 00000000126C: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 000000001274: D3E10020 1C824DB6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 00000000127C: E0511000 80050012
  "s_add_u32     m0, 0, s35                             \n"// 000000001284: 807C2380
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 000000001288: D3E10020 1C8251B8
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 000000001290: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 000000001298: D3E10020 1C8255BA
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 0000000012A0: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s34                    \n"// 0000000012A8: 807C22FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 0000000012B0: D3E10020 1C8259BC
  "v_perm_b32    v168, v23, v21, s53                    \n"// 0000000012B8: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 0000000012C0: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 0000000012C8: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 0000000012D0: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 0000000012D8: D3E10020 1C825DBE
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 0000000012E0: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s35                    \n"// 0000000012E8: 807C23FF 00000080
  "s_waitcnt     lgkmcnt(1)                             \n"// 0000000012F0: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 0000000012F4: D3E10020 1C8261C0
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 0000000012FC: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 000000001304: D3E10020 1C8265C2
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 00000000130C: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s34                    \n"// 000000001314: 807C22FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 00000000131C: D3E10020 1C8269C4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000001324: D3E10020 1C826DC6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 00000000132C: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s35                    \n"// 000000001334: 807C23FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 00000000133C: D3E10020 1C8271C8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000001344: D3E10020 1C8275CA
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 00000000134C: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s34                    \n"// 000000001354: 807C22FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 00000000135C: D3E10020 1C8279CC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 000000001364: D3E10020 1C827DCE
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 00000000136C: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s35                    \n"// 000000001374: 807C23FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 00000000137C: D3E10020 1C8281D0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 000000001384: D3E10020 1C8285D2
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 00000000138C: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s34                    \n"// 000000001394: 807C22FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 00000000139C: D3E10020 1C8289D4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 0000000013A4: D3E10020 1C828DD6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 0000000013AC: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s35                    \n"// 0000000013B4: 807C23FF 00000200
  "v_add_u32     v8, s73, v8                            \n"// 0000000013BC: 68101049
  "s_cmp_le_i32  s83, s82                               \n"// 0000000013C0: BF055253
  "s_cbranch_scc1  label_0516                           \n"// 0000000013C4: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 0000000013C8: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 0000000013D0: 80398052
  "v_mov_b32     v24, s57                               \n"// 0000000013D4: 7E300239
  "v_add_u32     v24, s7, v24                           \n"// 0000000013D8: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 0000000013DC: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 0000000013E0: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 0000000013E4: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 0000000013E8: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 0000000013EC: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 0000000013F0: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 0000000013F4: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 0000000013F8: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 000000001400: 682828C0
  "s_nop         0x0000                                 \n"// 000000001404: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 000000001408: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 000000001410: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 000000001418: 682A2AC0
  "s_nop         0x0000                                 \n"// 00000000141C: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 000000001420: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 000000001428: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000001430: 682C2CC0
  "s_nop         0x0000                                 \n"// 000000001434: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000001438: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000001440: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000001448: 682E2EC0
  "s_nop         0x0000                                 \n"// 00000000144C: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000001450: D1000023 009A4719
"label_0516: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001458: BF8CC07F
  "s_barrier                                            \n"// 00000000145C: BF8A0000
  "v_max3_f32    v24, v32, v33, v32                     \n"// 000000001460: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 000000001468: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 000000001470: D81AD100 00001803
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000001478: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s34                    \n"// 000000001480: 807C22FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000001488: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s35                    \n"// 000000001490: 807C23FF 00000280
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001498: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 00000000149C: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 0000000014A4: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 0000000014AC: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 0000000014B4: D86CD1C0 17000002
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 0000000014BC: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s34                    \n"// 0000000014C4: 807C22FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 0000000014CC: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s35                    \n"// 0000000014D4: 807C23FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 0000000014DC: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s34                    \n"// 0000000014E4: 807C22FF 00000380
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000014EC: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 0000000014F0: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 0000000014F8: D1D30018 04622F16
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000001500: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s35                    \n"// 000000001508: 807C23FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000001510: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s34                    \n"// 000000001518: 807C22FF 00000400
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 000000001520: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 000000001528: DBFE9500 94000007
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000001530: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s35                    \n"// 000000001538: 807C23FF 00000400
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000001540: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000001548: DBFE9D00 9C000007
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000001550: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s34                    \n"// 000000001558: 807C22FF 00000480
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000001560: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000001568: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 000000001570: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 000000001578: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 000000001580: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 000000001588: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 000000001590: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 000000001594: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 000000001598: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 0000000015A0: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 0000000015A4: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 0000000015A8: 0A202005
  "v_exp_f32     v16, v16                               \n"// 0000000015AC: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 0000000015B0: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 0000000015B8: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 0000000015C0: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 0000000015C8: D1CB0023 84540B23
  "v_exp_f32     v32, v32                               \n"// 0000000015D0: 7E404120
  "v_exp_f32     v33, v33                               \n"// 0000000015D4: 7E424121
  "v_exp_f32     v34, v34                               \n"// 0000000015D8: 7E444122
  "v_exp_f32     v35, v35                               \n"// 0000000015DC: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 0000000015E0: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 0000000015E4: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 0000000015E8: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 0000000015EC: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 0000000015F0: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 0000000015F4: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 0000000015F8: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 000000001600: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 000000001608: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 000000001610: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 000000001618: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000001620: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 000000001628: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 000000001630: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000001638: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000001640: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000001648: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000001650: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000001658: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000001660: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000001668: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000001670: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 000000001678: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 000000001680: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 000000001684: 80535354
  "s_nop         0x0000                                 \n"// 000000001688: BF800000
  "v_mul_u32_u24  v18, v11, v9 row_newbcast:0           \n"// 00000000168C: 102412FA FF01500B
  "v_mul_u32_u24  v19, v11, v9 row_newbcast:8           \n"// 000000001694: 102612FA FF01580B
  "v_add_u32     v18, v18, v1                           \n"// 00000000169C: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 0000000016A0: 68260313
  "s_mov_b32     m0, s36                                \n"// 0000000016A4: BEFC0024
  "v_mov_b32     v22, v16                               \n"// 0000000016A8: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 0000000016AC: 7E2E0310
  "v_pk_mul_f32  v[40:41], v[22:23], v[40:41]           \n"// 0000000016B0: D3B14028 18025116
  "v_pk_mul_f32  v[42:43], v[22:23], v[42:43]           \n"// 0000000016B8: D3B1402A 18025516
  "v_pk_mul_f32  v[44:45], v[22:23], v[44:45]           \n"// 0000000016C0: D3B1402C 18025916
  "v_pk_mul_f32  v[46:47], v[22:23], v[46:47]           \n"// 0000000016C8: D3B1402E 18025D16
  "v_pk_mul_f32  v[48:49], v[22:23], v[48:49]           \n"// 0000000016D0: D3B14030 18026116
  "v_pk_mul_f32  v[50:51], v[22:23], v[50:51]           \n"// 0000000016D8: D3B14032 18026516
  "v_pk_mul_f32  v[52:53], v[22:23], v[52:53]           \n"// 0000000016E0: D3B14034 18026916
  "v_pk_mul_f32  v[54:55], v[22:23], v[54:55]           \n"// 0000000016E8: D3B14036 18026D16
  "v_pk_mul_f32  v[56:57], v[22:23], v[56:57]           \n"// 0000000016F0: D3B14038 18027116
  "v_pk_mul_f32  v[58:59], v[22:23], v[58:59]           \n"// 0000000016F8: D3B1403A 18027516
  "v_pk_mul_f32  v[60:61], v[22:23], v[60:61]           \n"// 000000001700: D3B1403C 18027916
  "v_pk_mul_f32  v[62:63], v[22:23], v[62:63]           \n"// 000000001708: D3B1403E 18027D16
  "v_pk_mul_f32  v[64:65], v[22:23], v[64:65]           \n"// 000000001710: D3B14040 18028116
  "v_pk_mul_f32  v[66:67], v[22:23], v[66:67]           \n"// 000000001718: D3B14042 18028516
  "v_pk_mul_f32  v[68:69], v[22:23], v[68:69]           \n"// 000000001720: D3B14044 18028916
  "v_pk_mul_f32  v[70:71], v[22:23], v[70:71]           \n"// 000000001728: D3B14046 18028D16
  "v_pk_mul_f32  v[72:73], v[22:23], v[72:73]           \n"// 000000001730: D3B14048 18029116
  "v_pk_mul_f32  v[74:75], v[22:23], v[74:75]           \n"// 000000001738: D3B1404A 18029516
  "v_pk_mul_f32  v[76:77], v[22:23], v[76:77]           \n"// 000000001740: D3B1404C 18029916
  "v_pk_mul_f32  v[78:79], v[22:23], v[78:79]           \n"// 000000001748: D3B1404E 18029D16
  "v_pk_mul_f32  v[80:81], v[22:23], v[80:81]           \n"// 000000001750: D3B14050 1802A116
  "v_pk_mul_f32  v[82:83], v[22:23], v[82:83]           \n"// 000000001758: D3B14052 1802A516
  "v_pk_mul_f32  v[84:85], v[22:23], v[84:85]           \n"// 000000001760: D3B14054 1802A916
  "v_pk_mul_f32  v[86:87], v[22:23], v[86:87]           \n"// 000000001768: D3B14056 1802AD16
  "v_pk_mul_f32  v[88:89], v[22:23], v[88:89]           \n"// 000000001770: D3B14058 1802B116
  "v_pk_mul_f32  v[90:91], v[22:23], v[90:91]           \n"// 000000001778: D3B1405A 1802B516
  "v_pk_mul_f32  v[92:93], v[22:23], v[92:93]           \n"// 000000001780: D3B1405C 1802B916
  "v_pk_mul_f32  v[94:95], v[22:23], v[94:95]           \n"// 000000001788: D3B1405E 1802BD16
  "v_pk_mul_f32  v[96:97], v[22:23], v[96:97]           \n"// 000000001790: D3B14060 1802C116
  "v_pk_mul_f32  v[98:99], v[22:23], v[98:99]           \n"// 000000001798: D3B14062 1802C516
  "v_pk_mul_f32  v[100:101], v[22:23], v[100:101]       \n"// 0000000017A0: D3B14064 1802C916
  "v_pk_mul_f32  v[102:103], v[22:23], v[102:103]       \n"// 0000000017A8: D3B14066 1802CD16
  "v_pk_mul_f32  v[104:105], v[22:23], v[104:105]       \n"// 0000000017B0: D3B14068 1802D116
  "v_pk_mul_f32  v[106:107], v[22:23], v[106:107]       \n"// 0000000017B8: D3B1406A 1802D516
  "v_pk_mul_f32  v[108:109], v[22:23], v[108:109]       \n"// 0000000017C0: D3B1406C 1802D916
  "v_pk_mul_f32  v[110:111], v[22:23], v[110:111]       \n"// 0000000017C8: D3B1406E 1802DD16
  "v_pk_mul_f32  v[112:113], v[22:23], v[112:113]       \n"// 0000000017D0: D3B14070 1802E116
  "v_pk_mul_f32  v[114:115], v[22:23], v[114:115]       \n"// 0000000017D8: D3B14072 1802E516
  "v_pk_mul_f32  v[116:117], v[22:23], v[116:117]       \n"// 0000000017E0: D3B14074 1802E916
  "v_pk_mul_f32  v[118:119], v[22:23], v[118:119]       \n"// 0000000017E8: D3B14076 1802ED16
  "v_pk_mul_f32  v[120:121], v[22:23], v[120:121]       \n"// 0000000017F0: D3B14078 1802F116
  "v_pk_mul_f32  v[122:123], v[22:23], v[122:123]       \n"// 0000000017F8: D3B1407A 1802F516
  "v_pk_mul_f32  v[124:125], v[22:23], v[124:125]       \n"// 000000001800: D3B1407C 1802F916
  "v_pk_mul_f32  v[126:127], v[22:23], v[126:127]       \n"// 000000001808: D3B1407E 1802FD16
  "v_pk_mul_f32  v[128:129], v[22:23], v[128:129]       \n"// 000000001810: D3B14080 18030116
  "v_pk_mul_f32  v[130:131], v[22:23], v[130:131]       \n"// 000000001818: D3B14082 18030516
  "v_pk_mul_f32  v[132:133], v[22:23], v[132:133]       \n"// 000000001820: D3B14084 18030916
  "v_pk_mul_f32  v[134:135], v[22:23], v[134:135]       \n"// 000000001828: D3B14086 18030D16
  "v_pk_mul_f32  v[136:137], v[22:23], v[136:137]       \n"// 000000001830: D3B14088 18031116
  "v_pk_mul_f32  v[138:139], v[22:23], v[138:139]       \n"// 000000001838: D3B1408A 18031516
  "v_pk_mul_f32  v[140:141], v[22:23], v[140:141]       \n"// 000000001840: D3B1408C 18031916
  "v_pk_mul_f32  v[142:143], v[22:23], v[142:143]       \n"// 000000001848: D3B1408E 18031D16
  "v_pk_mul_f32  v[144:145], v[22:23], v[144:145]       \n"// 000000001850: D3B14090 18032116
  "v_pk_mul_f32  v[146:147], v[22:23], v[146:147]       \n"// 000000001858: D3B14092 18032516
  "v_pk_mul_f32  v[148:149], v[22:23], v[148:149]       \n"// 000000001860: D3B14094 18032916
  "v_pk_mul_f32  v[150:151], v[22:23], v[150:151]       \n"// 000000001868: D3B14096 18032D16
  "v_pk_mul_f32  v[152:153], v[22:23], v[152:153]       \n"// 000000001870: D3B14098 18033116
  "v_pk_mul_f32  v[154:155], v[22:23], v[154:155]       \n"// 000000001878: D3B1409A 18033516
  "v_pk_mul_f32  v[156:157], v[22:23], v[156:157]       \n"// 000000001880: D3B1409C 18033916
  "v_pk_mul_f32  v[158:159], v[22:23], v[158:159]       \n"// 000000001888: D3B1409E 18033D16
  "v_pk_mul_f32  v[160:161], v[22:23], v[160:161]       \n"// 000000001890: D3B140A0 18034116
  "v_pk_mul_f32  v[162:163], v[22:23], v[162:163]       \n"// 000000001898: D3B140A2 18034516
  "v_pk_mul_f32  v[164:165], v[22:23], v[164:165]       \n"// 0000000018A0: D3B140A4 18034916
  "v_pk_mul_f32  v[166:167], v[22:23], v[166:167]       \n"// 0000000018A8: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000018B0: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  v[40:43], acc[144:145], v[32:33], v[40:43]\n"// 0000000018B4: D3E10028 0CA24190
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 0000000018BC: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 0000000018C4: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  v[44:47], acc[146:147], v[32:33], v[44:47]\n"// 0000000018CC: D3E1002C 0CB24192
  "v_mfma_f32_16x16x16_bf16  v[48:51], acc[148:149], v[32:33], v[48:51]\n"// 0000000018D4: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  v[52:55], acc[150:151], v[32:33], v[52:55]\n"// 0000000018DC: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  v[56:59], acc[152:153], v[32:33], v[56:59]\n"// 0000000018E4: D3E10038 0CE24198
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 0000000018EC: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 0000000018F4: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  v[60:63], acc[154:155], v[32:33], v[60:63]\n"// 0000000018FC: D3E1003C 0CF2419A
  "v_mfma_f32_16x16x16_bf16  v[64:67], acc[156:157], v[32:33], v[64:67]\n"// 000000001904: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  v[68:71], acc[158:159], v[32:33], v[68:71]\n"// 00000000190C: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  v[72:75], acc[160:161], v[32:33], v[72:75]\n"// 000000001914: D3E10048 0D2241A0
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 00000000191C: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 000000001924: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  v[76:79], acc[162:163], v[32:33], v[76:79]\n"// 00000000192C: D3E1004C 0D3241A2
  "v_mfma_f32_16x16x16_bf16  v[80:83], acc[164:165], v[32:33], v[80:83]\n"// 000000001934: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  v[84:87], acc[166:167], v[32:33], v[84:87]\n"// 00000000193C: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  v[88:91], acc[168:169], v[32:33], v[88:91]\n"// 000000001944: D3E10058 0D6241A8
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 00000000194C: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 000000001954: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  v[92:95], acc[170:171], v[32:33], v[92:95]\n"// 00000000195C: D3E1005C 0D7241AA
  "v_mfma_f32_16x16x16_bf16  v[96:99], acc[172:173], v[32:33], v[96:99]\n"// 000000001964: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  v[100:103], acc[174:175], v[32:33], v[100:103]\n"// 00000000196C: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001974: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[104:107], acc[176:177], v[32:33], v[104:107]\n"// 000000001978: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  v[108:111], acc[178:179], v[32:33], v[108:111]\n"// 000000001980: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  v[112:115], acc[180:181], v[32:33], v[112:115]\n"// 000000001988: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000001990: BF8C4072
  "s_barrier                                            \n"// 000000001994: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[116:119], acc[182:183], v[32:33], v[116:119]\n"// 000000001998: D3E10074 0DD241B6
  "ds_read_b64   v[20:21], v5 offset:18560              \n"// 0000000019A0: D8EC4880 14000005
  "ds_read_b64   v[22:23], v5 offset:23200              \n"// 0000000019A8: D8EC5AA0 16000005
  "v_mfma_f32_16x16x16_bf16  v[120:123], acc[184:185], v[32:33], v[120:123]\n"// 0000000019B0: D3E10078 0DE241B8
  "ds_read_b64   v[24:25], v5 offset:27840              \n"// 0000000019B8: D8EC6CC0 18000005
  "ds_read_b64   v[26:27], v5 offset:32480              \n"// 0000000019C0: D8EC7EE0 1A000005
  "v_mfma_f32_16x16x16_bf16  v[124:127], acc[186:187], v[32:33], v[124:127]\n"// 0000000019C8: D3E1007C 0DF241BA
  "ds_read_b128  acc[144:147], v4 offset:18560          \n"// 0000000019D0: DBFE4880 90000004
  "v_mfma_f32_16x16x16_bf16  v[128:131], acc[188:189], v[32:33], v[128:131]\n"// 0000000019D8: D3E10080 0E0241BC
  "ds_read_b128  acc[148:151], v4 offset:18624          \n"// 0000000019E0: DBFE48C0 94000004
  "v_mfma_f32_16x16x16_bf16  v[132:135], acc[190:191], v[32:33], v[132:135]\n"// 0000000019E8: D3E10084 0E1241BE
  "ds_read_b128  acc[152:155], v4 offset:18816          \n"// 0000000019F0: DBFE4980 98000004
  "v_mfma_f32_16x16x16_bf16  v[136:139], acc[192:193], v[32:33], v[136:139]\n"// 0000000019F8: D3E10088 0E2241C0
  "ds_read_b128  acc[156:159], v4 offset:18880          \n"// 000000001A00: DBFE49C0 9C000004
  "v_mfma_f32_16x16x16_bf16  v[140:143], acc[194:195], v[32:33], v[140:143]\n"// 000000001A08: D3E1008C 0E3241C2
  "ds_read_b128  acc[160:163], v4 offset:19072          \n"// 000000001A10: DBFE4A80 A0000004
  "v_mfma_f32_16x16x16_bf16  v[144:147], acc[196:197], v[32:33], v[144:147]\n"// 000000001A18: D3E10090 0E4241C4
  "ds_read_b128  acc[164:167], v4 offset:19136          \n"// 000000001A20: DBFE4AC0 A4000004
  "v_mfma_f32_16x16x16_bf16  v[148:151], acc[198:199], v[32:33], v[148:151]\n"// 000000001A28: D3E10094 0E5241C6
  "ds_read_b128  acc[168:171], v4 offset:19328          \n"// 000000001A30: DBFE4B80 A8000004
  "v_mfma_f32_16x16x16_bf16  v[152:155], acc[200:201], v[32:33], v[152:155]\n"// 000000001A38: D3E10098 0E6241C8
  "ds_read_b128  acc[172:175], v4 offset:19392          \n"// 000000001A40: DBFE4BC0 AC000004
  "v_mfma_f32_16x16x16_bf16  v[156:159], acc[202:203], v[32:33], v[156:159]\n"// 000000001A48: D3E1009C 0E7241CA
  "s_waitcnt     lgkmcnt(8)                             \n"// 000000001A50: BF8CC87F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000001A54: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000001A5C: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000001A64: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000001A6C: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[160:163], acc[204:205], v[32:33], v[160:163]\n"// 000000001A74: D3E100A0 0E8241CC
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 000000001A7C: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000001A84: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000001A8C: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000001A94: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000001A9C: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  v[164:167], acc[206:207], v[32:33], v[164:167]\n"// 000000001AA4: D3E100A4 0E9241CE
  "ds_write_b128  v6, v[168:171] offset:38144           \n"// 000000001AAC: D9BE9500 0000A806
  "ds_read_b64   v[20:21], v5 offset:19584              \n"// 000000001AB4: D8EC4C80 14000005
  "ds_read_b64   v[22:23], v5 offset:24224              \n"// 000000001ABC: D8EC5EA0 16000005
  "ds_read_b64   v[24:25], v5 offset:28864              \n"// 000000001AC4: D8EC70C0 18000005
  "ds_read_b64   v[26:27], v5 offset:33504              \n"// 000000001ACC: D8EC82E0 1A000005
  "s_nop         0x0000                                 \n"// 000000001AD4: BF800000
  "s_addk_i32    s70, 0x0001                            \n"// 000000001AD8: B7460001
  "s_cmp_lt_i32  s70, s71                               \n"// 000000001ADC: BF044746
  "s_cbranch_scc0  label_091E                           \n"// 000000001AE0: BF840265
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001AE4: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 000000001AE8: D3E10020 1A020190
  "ds_read_b128  acc[176:179], v4 offset:19584          \n"// 000000001AF0: DBFE4C80 B0000004
  "ds_read_b128  acc[180:183], v4 offset:19648          \n"// 000000001AF8: DBFE4CC0 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 000000001B00: D3E10020 1C820592
  "buffer_load_dword  v11, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000001B08: E0501000 80060B08
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 000000001B10: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 000000001B18: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 000000001B20: D3E10020 1C821198
  "ds_read_b128  acc[184:187], v4 offset:19840          \n"// 000000001B28: DBFE4D80 B8000004
  "ds_read_b128  acc[188:191], v4 offset:19904          \n"// 000000001B30: DBFE4DC0 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 000000001B38: D3E10020 1C82159A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 000000001B40: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 000000001B48: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001B50: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 000000001B54: D3E10020 1C8221A0
  "ds_read_b128  acc[192:195], v4 offset:20096          \n"// 000000001B5C: DBFE4E80 C0000004
  "ds_read_b128  acc[196:199], v4 offset:20160          \n"// 000000001B64: DBFE4EC0 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 000000001B6C: D3E10020 1C8225A2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 000000001B74: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 000000001B7C: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 000000001B84: D3E10020 1C8231A8
  "ds_read_b128  acc[200:203], v4 offset:20352          \n"// 000000001B8C: DBFE4F80 C8000004
  "ds_read_b128  acc[204:207], v4 offset:20416          \n"// 000000001B94: DBFE4FC0 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 000000001B9C: D3E10020 1C8235AA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 000000001BA4: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 000000001BAC: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001BB4: BF8CC47F
  "s_barrier                                            \n"// 000000001BB8: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 000000001BBC: D3E10020 1C8241B0
  "ds_read_b128  acc[208:211], v4 offset:20608          \n"// 000000001BC4: DBFE5080 D0000004
  "ds_read_b128  acc[212:215], v4 offset:20672          \n"// 000000001BCC: DBFE50C0 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 000000001BD4: D3E10020 1C8245B2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 000000001BDC: D3E10020 1C8249B4
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000001BE4: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000001BEC: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000001BF4: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000001BFC: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 000000001C04: D3E10020 1C824DB6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000001C0C: E0511000 80050012
  "s_add_u32     m0, 0, s37                             \n"// 000000001C14: 807C2580
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 000000001C18: D3E10020 1C8251B8
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 000000001C20: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 000000001C28: D3E10020 1C8255BA
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000001C30: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s36                    \n"// 000000001C38: 807C24FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 000000001C40: D3E10020 1C8259BC
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000001C48: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000001C50: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000001C58: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000001C60: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 000000001C68: D3E10020 1C825DBE
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000001C70: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s37                    \n"// 000000001C78: 807C25FF 00000080
  "s_waitcnt     lgkmcnt(1)                             \n"// 000000001C80: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 000000001C84: D3E10020 1C8261C0
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000001C8C: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 000000001C94: D3E10020 1C8265C2
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000001C9C: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s36                    \n"// 000000001CA4: 807C24FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 000000001CAC: D3E10020 1C8269C4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000001CB4: D3E10020 1C826DC6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000001CBC: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s37                    \n"// 000000001CC4: 807C25FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 000000001CCC: D3E10020 1C8271C8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000001CD4: D3E10020 1C8275CA
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000001CDC: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s36                    \n"// 000000001CE4: 807C24FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 000000001CEC: D3E10020 1C8279CC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 000000001CF4: D3E10020 1C827DCE
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000001CFC: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s37                    \n"// 000000001D04: 807C25FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 000000001D0C: D3E10020 1C8281D0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 000000001D14: D3E10020 1C8285D2
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000001D1C: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s36                    \n"// 000000001D24: 807C24FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 000000001D2C: D3E10020 1C8289D4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 000000001D34: D3E10020 1C828DD6
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000001D3C: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s37                    \n"// 000000001D44: 807C25FF 00000200
  "v_add_u32     v8, s73, v8                            \n"// 000000001D4C: 68101049
  "s_cmp_le_i32  s83, s82                               \n"// 000000001D50: BF055253
  "s_cbranch_scc1  label_077A                           \n"// 000000001D54: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 000000001D58: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 000000001D60: 80398052
  "v_mov_b32     v24, s57                               \n"// 000000001D64: 7E300239
  "v_add_u32     v24, s7, v24                           \n"// 000000001D68: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 000000001D6C: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000001D70: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 000000001D74: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 000000001D78: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 000000001D7C: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 000000001D80: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 000000001D84: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 000000001D88: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 000000001D90: 682828C0
  "s_nop         0x0000                                 \n"// 000000001D94: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 000000001D98: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 000000001DA0: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 000000001DA8: 682A2AC0
  "s_nop         0x0000                                 \n"// 000000001DAC: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 000000001DB0: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 000000001DB8: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000001DC0: 682C2CC0
  "s_nop         0x0000                                 \n"// 000000001DC4: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000001DC8: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000001DD0: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000001DD8: 682E2EC0
  "s_nop         0x0000                                 \n"// 000000001DDC: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000001DE0: D1000023 009A4719
"label_077A: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001DE8: BF8CC07F
  "s_barrier                                            \n"// 000000001DEC: BF8A0000
  "v_max3_f32    v24, v32, v33, v32                     \n"// 000000001DF0: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 000000001DF8: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 000000001E00: D81AD100 00001803
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000001E08: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s36                    \n"// 000000001E10: 807C24FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000001E18: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s37                    \n"// 000000001E20: 807C25FF 00000280
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001E28: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 000000001E2C: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 000000001E34: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 000000001E3C: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 000000001E44: D86CD1C0 17000002
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000001E4C: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s36                    \n"// 000000001E54: 807C24FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000001E5C: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s37                    \n"// 000000001E64: 807C25FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 000000001E6C: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s36                    \n"// 000000001E74: 807C24FF 00000380
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000001E7C: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 000000001E80: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 000000001E88: D1D30018 04622F16
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000001E90: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s37                    \n"// 000000001E98: 807C25FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000001EA0: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s36                    \n"// 000000001EA8: 807C24FF 00000400
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 000000001EB0: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 000000001EB8: DBFE9500 94000007
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000001EC0: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s37                    \n"// 000000001EC8: 807C25FF 00000400
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000001ED0: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000001ED8: DBFE9D00 9C000007
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000001EE0: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s36                    \n"// 000000001EE8: 807C24FF 00000480
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000001EF0: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000001EF8: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 000000001F00: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 000000001F08: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 000000001F10: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 000000001F18: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 000000001F20: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 000000001F24: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 000000001F28: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 000000001F30: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 000000001F34: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 000000001F38: 0A202005
  "v_exp_f32     v16, v16                               \n"// 000000001F3C: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 000000001F40: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 000000001F48: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 000000001F50: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 000000001F58: D1CB0023 84540B23
