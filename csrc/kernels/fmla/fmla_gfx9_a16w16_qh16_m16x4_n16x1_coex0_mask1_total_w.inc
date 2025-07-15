

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
  ";v_lshrrev_b32  v3, 6, %[threadIdxx]                             \n"// 000000000098: 20060086
  "v_and_b32     %[threadIdxx], 63, %[threadIdxx]                             \n"// 00000000009C: 260000BF
  "s_mov_b32     %[blockIdxx], %[blockIdxx]                                 \n"// 0000000000A0: BE820002
  "s_mov_b32     %[blockIdxy], %[blockIdxy]                                 \n"// 0000000000A4: BE830003
  "s_mov_b32     %[blockIdxz], %[blockIdxz]                                 \n"// 0000000000A8: BE840004
  ";v_readfirstlane_b32  %[wave_id], v3                          \n"// 0000000000AC: 7E0E0503
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000000B0: BF8CC07F
  "s_mul_i32     s56, %[blockIdxy], 4                             \n"// 0000000000B8: 92388403
  "s_and_b32     %[kv_indptr_res_1], %[kv_indptr_res_1], 0x0000ffff                   \n"// 0000000000BC: 861DFF1D 0000FFFF
  ";s_and_b32     s31, s31, 0x0000ffff                   \n"// 0000000000C4: 861FFF1F 0000FFFF
  "s_add_u32     %[kv_indptr_res_0], s56, %[kv_indptr_res_0]                          \n"// 0000000000CC: 801C1C38
  "s_addc_u32    %[kv_indptr_res_1], 0, %[kv_indptr_res_1]                            \n"// 0000000000D0: 821D1D80
  "s_load_dword  s47, [%[kv_indptr_res_0], %[kv_indptr_res_1]], 0x00                    \n"// 0000000000D4: C0020BCE 00000000
  "s_load_dword  s46, [%[kv_indptr_res_0], %[kv_indptr_res_1]], 0x04                    \n"// 0000000000DC: C0020B8E 00000004
  ";s_mul_i32     s56, %[blockIdxy], 4                             \n"// 0000000000E4: 92388403
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
  "v_add_u32     v8, v8, %[wave_id]                             \n"// 0000000002DC: D1340008 00000F08
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
  "s_mul_i32     s56, %[wave_id], 0x00000480                    \n"// 000000000340: 9238FF07 00000480
  "v_lshlrev_b32  v30, 2, %[threadIdxx]                            \n"// 000000000348: 243C0082
  "v_add_u32     v30, s56, v30                          \n"// 00000000034C: 683C3C38
  "s_mul_i32     s56, %[wave_id], 0x00001420                    \n"// 000000000350: 9238FF07 00001420
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
  "s_cmp_eq_i32  %[wave_id], 0                                  \n"// 000000000664: BF008007
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
  "s_cmp_eq_i32  %[wave_id], 1                                  \n"// 0000000007F4: BF008107
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
  "s_cmp_eq_i32  %[wave_id], 2                                  \n"// 000000000898: BF008207
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
  "s_cmp_eq_i32  %[wave_id], 3                                  \n"// 00000000093C: BF008307
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
  "s_mul_i32     s56, 0x00000100, %[wave_id]                    \n"// 000000000A3C: 923807FF 00000100
  "v_add_u32     v2, s56, v2                            \n"// 000000000A44: 68040438
  "v_lshlrev_b32  v3, 2, %[threadIdxx]                             \n"// 000000000A48: 24060082
  "s_mul_i32     s56, 0x00000100, %[wave_id]                    \n"// 000000000A4C: 923807FF 00000100
  "v_add_u32     v3, s56, v3                            \n"// 000000000A54: 68060638
  "v_and_b32     v20, 31, %[threadIdxx]                            \n"// 000000000A58: 2628009F
  "v_lshlrev_b32  v1, 2, v20                            \n"// 000000000A5C: 24022882
  "s_mul_i32     s34, %[wave_id], 0x00001220                    \n"// 000000000A60: 9222FF07 00001220
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
  "s_mul_i32     s56, 64, %[wave_id]                            \n"// 000000000E34: 923807C0
  "v_add_u32     v5, v5, s56                            \n"// 000000000E38: D1340005 00007105
  "v_lshlrev_b32  v5, 2, v5                             \n"// 000000000E40: 240A0A82
  "v_lshlrev_b32  v6, 2, %[threadIdxx]                             \n"// 000000000E44: 240C0082
  "s_mul_i32     s56, 0x00000200, %[wave_id]                    \n"// 000000000E48: 923807FF 00000200
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
  "s_cmp_lt_i32  %[wave_id], 2                                  \n"// 00000000114C: BF048207
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
  "v_add_u32     v24, %[wave_id], v24                           \n"// 0000000013D8: 68303007
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
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 0000000016B0: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 0000000016B8: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 0000000016C0: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 0000000016C8: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 0000000016D0: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 0000000016D8: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 0000000016E0: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 0000000016E8: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 0000000016F0: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 0000000016F8: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 000000001700: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 000000001708: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 000000001710: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 000000001718: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 000000001720: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 000000001728: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 000000001730: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 000000001738: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 000000001740: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 000000001748: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 000000001750: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 000000001758: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 000000001760: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 000000001768: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000001770: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 000000001778: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000001780: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 000000001788: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000001790: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 000000001798: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 0000000017A0: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 0000000017A8: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 0000000017B0: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 0000000017B8: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 0000000017C0: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 0000000017C8: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 0000000017D0: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 0000000017D8: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 0000000017E0: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 0000000017E8: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 0000000017F0: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 0000000017F8: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 000000001800: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 000000001808: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 000000001810: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 000000001818: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 000000001820: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 000000001828: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 000000001830: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 000000001838: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 000000001840: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 000000001848: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 000000001850: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 000000001858: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 000000001860: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 000000001868: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000001870: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 000000001878: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000001880: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 000000001888: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000001890: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 000000001898: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 0000000018A0: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 0000000018A8: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000018B0: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 0000000018B4: D3E10028 0CA24190
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 0000000018BC: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 0000000018C4: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 0000000018CC: D3E1002C 0CB24192
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 0000000018D4: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 0000000018DC: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 0000000018E4: D3E10038 0CE24198
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 0000000018EC: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 0000000018F4: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 0000000018FC: D3E1003C 0CF2419A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 000000001904: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 00000000190C: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 000000001914: D3E10048 0D2241A0
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 00000000191C: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 000000001924: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 00000000192C: D3E1004C 0D3241A2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 000000001934: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 00000000193C: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 000000001944: D3E10058 0D6241A8
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 00000000194C: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 000000001954: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 00000000195C: D3E1005C 0D7241AA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 000000001964: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 00000000196C: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000001974: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 000000001978: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000001980: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 000000001988: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000001990: BF8C4072
  "s_barrier                                            \n"// 000000001994: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 000000001998: D3E10074 0DD241B6
  "ds_read_b64   v[20:21], v5 offset:18560              \n"// 0000000019A0: D8EC4880 14000005
  "ds_read_b64   v[22:23], v5 offset:23200              \n"// 0000000019A8: D8EC5AA0 16000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 0000000019B0: D3E10078 0DE241B8
  "ds_read_b64   v[24:25], v5 offset:27840              \n"// 0000000019B8: D8EC6CC0 18000005
  "ds_read_b64   v[26:27], v5 offset:32480              \n"// 0000000019C0: D8EC7EE0 1A000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 0000000019C8: D3E1007C 0DF241BA
  "ds_read_b128  acc[144:147], v4 offset:18560          \n"// 0000000019D0: DBFE4880 90000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 0000000019D8: D3E10080 0E0241BC
  "ds_read_b128  acc[148:151], v4 offset:18624          \n"// 0000000019E0: DBFE48C0 94000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 0000000019E8: D3E10084 0E1241BE
  "ds_read_b128  acc[152:155], v4 offset:18816          \n"// 0000000019F0: DBFE4980 98000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 0000000019F8: D3E10088 0E2241C0
  "ds_read_b128  acc[156:159], v4 offset:18880          \n"// 000000001A00: DBFE49C0 9C000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 000000001A08: D3E1008C 0E3241C2
  "ds_read_b128  acc[160:163], v4 offset:19072          \n"// 000000001A10: DBFE4A80 A0000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 000000001A18: D3E10090 0E4241C4
  "ds_read_b128  acc[164:167], v4 offset:19136          \n"// 000000001A20: DBFE4AC0 A4000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 000000001A28: D3E10094 0E5241C6
  "ds_read_b128  acc[168:171], v4 offset:19328          \n"// 000000001A30: DBFE4B80 A8000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 000000001A38: D3E10098 0E6241C8
  "ds_read_b128  acc[172:175], v4 offset:19392          \n"// 000000001A40: DBFE4BC0 AC000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 000000001A48: D3E1009C 0E7241CA
  "s_waitcnt     lgkmcnt(8)                             \n"// 000000001A50: BF8CC87F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000001A54: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000001A5C: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000001A64: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000001A6C: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000001A74: D3E100A0 0E8241CC
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 000000001A7C: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000001A84: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000001A8C: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000001A94: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000001A9C: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 000000001AA4: D3E100A4 0E9241CE
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
  "v_add_u32     v24, %[wave_id], v24                           \n"// 000000001D68: 68303007
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
  "v_exp_f32     v32, v32                               \n"// 000000001F60: 7E404120
  "v_exp_f32     v33, v33                               \n"// 000000001F64: 7E424121
  "v_exp_f32     v34, v34                               \n"// 000000001F68: 7E444122
  "v_exp_f32     v35, v35                               \n"// 000000001F6C: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 000000001F70: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 000000001F74: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 000000001F78: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 000000001F7C: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 000000001F80: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 000000001F84: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 000000001F88: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 000000001F90: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 000000001F98: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 000000001FA0: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 000000001FA8: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000001FB0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 000000001FB8: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 000000001FC0: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000001FC8: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000001FD0: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000001FD8: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000001FE0: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000001FE8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000001FF0: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000001FF8: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000002000: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 000000002008: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 000000002010: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 000000002014: 80535354
  "s_nop         0x0000                                 \n"// 000000002018: BF800000
  "v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"// 00000000201C: 102412FA FF01500A
  "v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"// 000000002024: 102612FA FF01580A
  "v_add_u32     v18, v18, v1                           \n"// 00000000202C: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 000000002030: 68260313
  "s_mov_b32     m0, s34                                \n"// 000000002034: BEFC0022
  "v_mov_b32     v22, v16                               \n"// 000000002038: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 00000000203C: 7E2E0310
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 000000002040: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 000000002048: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 000000002050: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 000000002058: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 000000002060: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 000000002068: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 000000002070: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 000000002078: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 000000002080: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 000000002088: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 000000002090: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 000000002098: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 0000000020A0: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 0000000020A8: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 0000000020B0: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 0000000020B8: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 0000000020C0: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 0000000020C8: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 0000000020D0: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 0000000020D8: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 0000000020E0: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 0000000020E8: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 0000000020F0: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 0000000020F8: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000002100: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 000000002108: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000002110: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 000000002118: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000002120: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 000000002128: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 000000002130: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 000000002138: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 000000002140: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 000000002148: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 000000002150: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 000000002158: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 000000002160: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 000000002168: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 000000002170: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 000000002178: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 000000002180: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 000000002188: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 000000002190: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 000000002198: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 0000000021A0: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 0000000021A8: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 0000000021B0: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 0000000021B8: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 0000000021C0: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 0000000021C8: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 0000000021D0: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 0000000021D8: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 0000000021E0: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 0000000021E8: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 0000000021F0: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 0000000021F8: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000002200: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 000000002208: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000002210: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 000000002218: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000002220: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 000000002228: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 000000002230: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 000000002238: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000002240: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 000000002244: D3E10028 0CA24190
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 00000000224C: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 000000002254: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 00000000225C: D3E1002C 0CB24192
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 000000002264: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 00000000226C: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 000000002274: D3E10038 0CE24198
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 00000000227C: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 000000002284: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 00000000228C: D3E1003C 0CF2419A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 000000002294: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 00000000229C: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 0000000022A4: D3E10048 0D2241A0
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 0000000022AC: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 0000000022B4: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 0000000022BC: D3E1004C 0D3241A2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 0000000022C4: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 0000000022CC: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 0000000022D4: D3E10058 0D6241A8
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 0000000022DC: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 0000000022E4: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 0000000022EC: D3E1005C 0D7241AA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 0000000022F4: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 0000000022FC: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002304: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 000000002308: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000002310: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 000000002318: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000002320: BF8C4072
  "s_barrier                                            \n"// 000000002324: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 000000002328: D3E10074 0DD241B6
  "ds_read_b64   v[20:21], v5                           \n"// 000000002330: D8EC0000 14000005
  "ds_read_b64   v[22:23], v5 offset:4640               \n"// 000000002338: D8EC1220 16000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 000000002340: D3E10078 0DE241B8
  "ds_read_b64   v[24:25], v5 offset:9280               \n"// 000000002348: D8EC2440 18000005
  "ds_read_b64   v[26:27], v5 offset:13920              \n"// 000000002350: D8EC3660 1A000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 000000002358: D3E1007C 0DF241BA
  "ds_read_b128  acc[144:147], v4                       \n"// 000000002360: DBFE0000 90000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 000000002368: D3E10080 0E0241BC
  "ds_read_b128  acc[148:151], v4 offset:64             \n"// 000000002370: DBFE0040 94000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 000000002378: D3E10084 0E1241BE
  "ds_read_b128  acc[152:155], v4 offset:256            \n"// 000000002380: DBFE0100 98000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 000000002388: D3E10088 0E2241C0
  "ds_read_b128  acc[156:159], v4 offset:320            \n"// 000000002390: DBFE0140 9C000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 000000002398: D3E1008C 0E3241C2
  "ds_read_b128  acc[160:163], v4 offset:512            \n"// 0000000023A0: DBFE0200 A0000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 0000000023A8: D3E10090 0E4241C4
  "ds_read_b128  acc[164:167], v4 offset:576            \n"// 0000000023B0: DBFE0240 A4000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 0000000023B8: D3E10094 0E5241C6
  "ds_read_b128  acc[168:171], v4 offset:768            \n"// 0000000023C0: DBFE0300 A8000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 0000000023C8: D3E10098 0E6241C8
  "ds_read_b128  acc[172:175], v4 offset:832            \n"// 0000000023D0: DBFE0340 AC000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 0000000023D8: D3E1009C 0E7241CA
  "s_waitcnt     lgkmcnt(8)                             \n"// 0000000023E0: BF8CC87F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 0000000023E4: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 0000000023EC: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 0000000023F4: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 0000000023FC: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000002404: D3E100A0 0E8241CC
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 00000000240C: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000002414: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 00000000241C: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000002424: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 00000000242C: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 000000002434: D3E100A4 0E9241CE
  "ds_write_b128  v6, v[168:171] offset:38144           \n"// 00000000243C: D9BE9500 0000A806
  "ds_read_b64   v[20:21], v5 offset:1024               \n"// 000000002444: D8EC0400 14000005
  "ds_read_b64   v[22:23], v5 offset:5664               \n"// 00000000244C: D8EC1620 16000005
  "ds_read_b64   v[24:25], v5 offset:10304              \n"// 000000002454: D8EC2840 18000005
  "ds_read_b64   v[26:27], v5 offset:14944              \n"// 00000000245C: D8EC3A60 1A000005
  "s_nop         0x0000                                 \n"// 000000002464: BF800000
  "s_addk_i32    s70, 0x0001                            \n"// 000000002468: B7460001
  "s_cmp_lt_i32  s70, s71                               \n"// 00000000246C: BF044746
  "s_cbranch_scc0  label_091E                           \n"// 000000002470: BF840001
  "s_branch      label_0455                             \n"// 000000002474: BF82FB37
"label_091E: \n"
  "s_nop         0x0000                                 \n"// 000000002478: BF800000
  "s_nop         0x0000                                 \n"// 00000000247C: BF800000
  "s_branch      label_0DEA                             \n"// 000000002480: BF8204C9
"label_0921: \n"
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002484: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 000000002488: D3E10020 1A020190
  "buffer_load_dword  v10, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000002490: E0501000 80060A08
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 000000002498: D3E10020 1C820592
  "ds_read_b128  acc[176:179], v4 offset:1024           \n"// 0000000024A0: DBFE0400 B0000004
  "ds_read_b128  acc[180:183], v4 offset:1088           \n"// 0000000024A8: DBFE0440 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 0000000024B0: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 0000000024B8: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 0000000024C0: D3E10020 1C821198
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 0000000024C8: D3E10020 1C82159A
  "ds_read_b128  acc[184:187], v4 offset:1280           \n"// 0000000024D0: DBFE0500 B8000004
  "ds_read_b128  acc[188:191], v4 offset:1344           \n"// 0000000024D8: DBFE0540 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 0000000024E0: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 0000000024E8: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000024F0: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 0000000024F4: D3E10020 1C8221A0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 0000000024FC: D3E10020 1C8225A2
  "ds_read_b128  acc[192:195], v4 offset:1536           \n"// 000000002504: DBFE0600 C0000004
  "ds_read_b128  acc[196:199], v4 offset:1600           \n"// 00000000250C: DBFE0640 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 000000002514: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 00000000251C: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 000000002524: D3E10020 1C8231A8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 00000000252C: D3E10020 1C8235AA
  "ds_read_b128  acc[200:203], v4 offset:1792           \n"// 000000002534: DBFE0700 C8000004
  "ds_read_b128  acc[204:207], v4 offset:1856           \n"// 00000000253C: DBFE0740 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 000000002544: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 00000000254C: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002554: BF8CC47F
  "s_barrier                                            \n"// 000000002558: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 00000000255C: D3E10020 1C8241B0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 000000002564: D3E10020 1C8245B2
  "ds_read_b128  acc[208:211], v4 offset:2048           \n"// 00000000256C: DBFE0800 D0000004
  "ds_read_b128  acc[212:215], v4 offset:2112           \n"// 000000002574: DBFE0840 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 00000000257C: D3E10020 1C8249B4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000002584: E0511000 80050012
  "s_add_u32     m0, 0, s35                             \n"// 00000000258C: 807C2380
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 000000002590: D3E10020 1C824DB6
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000002598: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 0000000025A0: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 0000000025A8: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 0000000025B0: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 0000000025B8: D3E10020 1C8251B8
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 0000000025C0: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s34                    \n"// 0000000025C8: 807C22FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 0000000025D0: D3E10020 1C8255BA
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 0000000025D8: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 0000000025E0: D3E10020 1C8259BC
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 0000000025E8: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s35                    \n"// 0000000025F0: 807C23FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 0000000025F8: D3E10020 1C825DBE
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000002600: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000002608: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000002610: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000002618: D1ED00AB 00D2331B
  "s_waitcnt     lgkmcnt(1)                             \n"// 000000002620: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 000000002624: D3E10020 1C8261C0
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 00000000262C: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s34                    \n"// 000000002634: 807C22FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 00000000263C: D3E10020 1C8265C2
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000002644: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 00000000264C: D3E10020 1C8269C4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000002654: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s35                    \n"// 00000000265C: 807C23FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000002664: D3E10020 1C826DC6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 00000000266C: D3E10020 1C8271C8
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000002674: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s34                    \n"// 00000000267C: 807C22FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000002684: D3E10020 1C8275CA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 00000000268C: D3E10020 1C8279CC
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000002694: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s35                    \n"// 00000000269C: 807C23FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 0000000026A4: D3E10020 1C827DCE
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 0000000026AC: D3E10020 1C8281D0
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 0000000026B4: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s34                    \n"// 0000000026BC: 807C22FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 0000000026C4: D3E10020 1C8285D2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 0000000026CC: D3E10020 1C8289D4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 0000000026D4: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s35                    \n"// 0000000026DC: 807C23FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 0000000026E4: D3E10020 1C828DD6
  "v_add_u32     v8, s73, v8                            \n"// 0000000026EC: 68101049
  "s_cmp_le_i32  s83, s82                               \n"// 0000000026F0: BF055253
  "s_cbranch_scc1  label_09E2                           \n"// 0000000026F4: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 0000000026F8: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 000000002700: 80398052
  "v_mov_b32     v24, s57                               \n"// 000000002704: 7E300239
  "v_add_u32     v24, %[wave_id], v24                           \n"// 000000002708: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 00000000270C: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000002710: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 000000002714: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 000000002718: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 00000000271C: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 000000002720: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 000000002724: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 000000002728: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 000000002730: 682828C0
  "s_nop         0x0000                                 \n"// 000000002734: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 000000002738: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 000000002740: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 000000002748: 682A2AC0
  "s_nop         0x0000                                 \n"// 00000000274C: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 000000002750: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 000000002758: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000002760: 682C2CC0
  "s_nop         0x0000                                 \n"// 000000002764: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000002768: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000002770: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000002778: 682E2EC0
  "s_nop         0x0000                                 \n"// 00000000277C: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000002780: D1000023 009A4719
"label_09E2: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000002788: BF8CC07F
  "s_barrier                                            \n"// 00000000278C: BF8A0000
  "v_max3_f32    v24, v32, v33, v32                     \n"// 000000002790: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 000000002798: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 0000000027A0: D81AD100 00001803
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 0000000027A8: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s34                    \n"// 0000000027B0: 807C22FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 0000000027B8: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s35                    \n"// 0000000027C0: 807C23FF 00000280
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000027C8: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 0000000027CC: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 0000000027D4: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 0000000027DC: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 0000000027E4: D86CD1C0 17000002
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 0000000027EC: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s34                    \n"// 0000000027F4: 807C22FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 0000000027FC: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s35                    \n"// 000000002804: 807C23FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 00000000280C: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s34                    \n"// 000000002814: 807C22FF 00000380
  "s_waitcnt     lgkmcnt(0)                             \n"// 00000000281C: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 000000002820: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 000000002828: D1D30018 04622F16
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000002830: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s35                    \n"// 000000002838: 807C23FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 000000002840: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s34                    \n"// 000000002848: 807C22FF 00000400
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000002850: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s35                    \n"// 000000002858: 807C23FF 00000400
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 000000002860: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 000000002868: DBFE9500 94000007
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000002870: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s34                    \n"// 000000002878: 807C22FF 00000480
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000002880: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000002888: DBFE9D00 9C000007
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000002890: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000002898: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 0000000028A0: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 0000000028A8: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 0000000028B0: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 0000000028B8: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 0000000028C0: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 0000000028C4: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 0000000028C8: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 0000000028D0: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 0000000028D4: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 0000000028D8: 0A202005
  "v_exp_f32     v16, v16                               \n"// 0000000028DC: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 0000000028E0: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 0000000028E8: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 0000000028F0: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 0000000028F8: D1CB0023 84540B23
  "v_exp_f32     v32, v32                               \n"// 000000002900: 7E404120
  "v_exp_f32     v33, v33                               \n"// 000000002904: 7E424121
  "v_exp_f32     v34, v34                               \n"// 000000002908: 7E444122
  "v_exp_f32     v35, v35                               \n"// 00000000290C: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 000000002910: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 000000002914: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 000000002918: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 00000000291C: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 000000002920: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 000000002924: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 000000002928: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 000000002930: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 000000002938: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 000000002940: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 000000002948: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000002950: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 000000002958: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 000000002960: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000002968: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000002970: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000002978: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000002980: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000002988: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000002990: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000002998: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000029A0: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 0000000029A8: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 0000000029B0: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 0000000029B4: 80535354
  "s_nop         0x0000                                 \n"// 0000000029B8: BF800000
  "v_mul_u32_u24  v18, v11, v9 row_newbcast:0           \n"// 0000000029BC: 102412FA FF01500B
  "v_mul_u32_u24  v19, v11, v9 row_newbcast:8           \n"// 0000000029C4: 102612FA FF01580B
  "v_add_u32     v18, v18, v1                           \n"// 0000000029CC: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 0000000029D0: 68260313
  "s_mov_b32     m0, s36                                \n"// 0000000029D4: BEFC0024
  "v_mov_b32     v22, v16                               \n"// 0000000029D8: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 0000000029DC: 7E2E0310
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 0000000029E0: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 0000000029E8: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 0000000029F0: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 0000000029F8: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 000000002A00: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 000000002A08: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 000000002A10: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 000000002A18: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 000000002A20: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 000000002A28: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 000000002A30: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 000000002A38: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 000000002A40: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 000000002A48: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 000000002A50: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 000000002A58: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 000000002A60: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 000000002A68: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 000000002A70: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 000000002A78: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 000000002A80: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 000000002A88: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 000000002A90: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 000000002A98: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000002AA0: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 000000002AA8: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000002AB0: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 000000002AB8: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000002AC0: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 000000002AC8: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 000000002AD0: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 000000002AD8: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 000000002AE0: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 000000002AE8: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 000000002AF0: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 000000002AF8: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 000000002B00: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 000000002B08: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 000000002B10: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 000000002B18: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 000000002B20: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 000000002B28: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 000000002B30: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 000000002B38: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 000000002B40: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 000000002B48: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 000000002B50: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 000000002B58: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 000000002B60: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 000000002B68: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 000000002B70: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 000000002B78: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 000000002B80: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 000000002B88: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 000000002B90: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 000000002B98: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000002BA0: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 000000002BA8: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000002BB0: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 000000002BB8: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000002BC0: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 000000002BC8: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 000000002BD0: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 000000002BD8: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000002BE0: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 000000002BE4: D3E10028 0CA24190
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 000000002BEC: D3E1002C 0CB24192
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 000000002BF4: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 000000002BFC: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 000000002C04: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 000000002C0C: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 000000002C14: D3E10038 0CE24198
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 000000002C1C: D3E1003C 0CF2419A
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 000000002C24: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 000000002C2C: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 000000002C34: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 000000002C3C: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 000000002C44: D3E10048 0D2241A0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 000000002C4C: D3E1004C 0D3241A2
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 000000002C54: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 000000002C5C: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 000000002C64: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 000000002C6C: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 000000002C74: D3E10058 0D6241A8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 000000002C7C: D3E1005C 0D7241AA
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 000000002C84: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 000000002C8C: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 000000002C94: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 000000002C9C: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002CA4: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 000000002CA8: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000002CB0: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 000000002CB8: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000002CC0: BF8C4072
  "s_barrier                                            \n"// 000000002CC4: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 000000002CC8: D3E10074 0DD241B6
  "ds_read_b64   v[20:21], v5 offset:18560              \n"// 000000002CD0: D8EC4880 14000005
  "ds_read_b64   v[22:23], v5 offset:23200              \n"// 000000002CD8: D8EC5AA0 16000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 000000002CE0: D3E10078 0DE241B8
  "ds_read_b64   v[24:25], v5 offset:27840              \n"// 000000002CE8: D8EC6CC0 18000005
  "ds_read_b64   v[26:27], v5 offset:32480              \n"// 000000002CF0: D8EC7EE0 1A000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 000000002CF8: D3E1007C 0DF241BA
  "ds_read_b128  acc[144:147], v4 offset:18560          \n"// 000000002D00: DBFE4880 90000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 000000002D08: D3E10080 0E0241BC
  "ds_read_b128  acc[148:151], v4 offset:18624          \n"// 000000002D10: DBFE48C0 94000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 000000002D18: D3E10084 0E1241BE
  "ds_read_b128  acc[152:155], v4 offset:18816          \n"// 000000002D20: DBFE4980 98000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 000000002D28: D3E10088 0E2241C0
  "ds_read_b128  acc[156:159], v4 offset:18880          \n"// 000000002D30: DBFE49C0 9C000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 000000002D38: D3E1008C 0E3241C2
  "ds_read_b128  acc[160:163], v4 offset:19072          \n"// 000000002D40: DBFE4A80 A0000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 000000002D48: D3E10090 0E4241C4
  "ds_read_b128  acc[164:167], v4 offset:19136          \n"// 000000002D50: DBFE4AC0 A4000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 000000002D58: D3E10094 0E5241C6
  "ds_read_b128  acc[168:171], v4 offset:19328          \n"// 000000002D60: DBFE4B80 A8000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 000000002D68: D3E10098 0E6241C8
  "ds_read_b128  acc[172:175], v4 offset:19392          \n"// 000000002D70: DBFE4BC0 AC000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 000000002D78: D3E1009C 0E7241CA
  "s_waitcnt     lgkmcnt(8)                             \n"// 000000002D80: BF8CC87F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000002D84: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000002D8C: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000002D94: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000002D9C: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000002DA4: D3E100A0 0E8241CC
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 000000002DAC: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000002DB4: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000002DBC: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000002DC4: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000002DCC: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 000000002DD4: D3E100A4 0E9241CE
  "ds_write_b128  v6, v[168:171] offset:38144           \n"// 000000002DDC: D9BE9500 0000A806
  "ds_read_b64   v[20:21], v5 offset:19584              \n"// 000000002DE4: D8EC4C80 14000005
  "ds_read_b64   v[22:23], v5 offset:24224              \n"// 000000002DEC: D8EC5EA0 16000005
  "ds_read_b64   v[24:25], v5 offset:28864              \n"// 000000002DF4: D8EC70C0 18000005
  "ds_read_b64   v[26:27], v5 offset:33504              \n"// 000000002DFC: D8EC82E0 1A000005
  "s_nop         0x0000                                 \n"// 000000002E04: BF800000
  "s_addk_i32    s70, 0x0001                            \n"// 000000002E08: B7460001
  "s_cmp_lt_i32  s70, s71                               \n"// 000000002E0C: BF044746
  "s_cbranch_scc0  label_091E                           \n"// 000000002E10: BF84FD99
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002E14: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 000000002E18: D3E10020 1A020190
  "buffer_load_dword  v11, v8, [%[kv_indices_res_0], %[kv_indices_res_1], %[kv_indices_res_2], %[kv_indices_res_3]], 0 offen        \n"// 000000002E20: E0501000 80060B08
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 000000002E28: D3E10020 1C820592
  "ds_read_b128  acc[176:179], v4 offset:19584          \n"// 000000002E30: DBFE4C80 B0000004
  "ds_read_b128  acc[180:183], v4 offset:19648          \n"// 000000002E38: DBFE4CC0 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 000000002E40: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 000000002E48: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 000000002E50: D3E10020 1C821198
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 000000002E58: D3E10020 1C82159A
  "ds_read_b128  acc[184:187], v4 offset:19840          \n"// 000000002E60: DBFE4D80 B8000004
  "ds_read_b128  acc[188:191], v4 offset:19904          \n"// 000000002E68: DBFE4DC0 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 000000002E70: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 000000002E78: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002E80: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 000000002E84: D3E10020 1C8221A0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 000000002E8C: D3E10020 1C8225A2
  "ds_read_b128  acc[192:195], v4 offset:20096          \n"// 000000002E94: DBFE4E80 C0000004
  "ds_read_b128  acc[196:199], v4 offset:20160          \n"// 000000002E9C: DBFE4EC0 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 000000002EA4: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 000000002EAC: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 000000002EB4: D3E10020 1C8231A8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 000000002EBC: D3E10020 1C8235AA
  "ds_read_b128  acc[200:203], v4 offset:20352          \n"// 000000002EC4: DBFE4F80 C8000004
  "ds_read_b128  acc[204:207], v4 offset:20416          \n"// 000000002ECC: DBFE4FC0 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 000000002ED4: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 000000002EDC: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000002EE4: BF8CC47F
  "s_barrier                                            \n"// 000000002EE8: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 000000002EEC: D3E10020 1C8241B0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 000000002EF4: D3E10020 1C8245B2
  "ds_read_b128  acc[208:211], v4 offset:20608          \n"// 000000002EFC: DBFE5080 D0000004
  "ds_read_b128  acc[212:215], v4 offset:20672          \n"// 000000002F04: DBFE50C0 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 000000002F0C: D3E10020 1C8249B4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000002F14: E0511000 80050012
  "s_add_u32     m0, 0, s37                             \n"// 000000002F1C: 807C2580
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 000000002F20: D3E10020 1C824DB6
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000002F28: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 000000002F30: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000002F38: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 000000002F40: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 000000002F48: D3E10020 1C8251B8
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen lds    \n"// 000000002F50: E0511000 80050013
  "s_add_u32     m0, 0x00000080, s36                    \n"// 000000002F58: 807C24FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 000000002F60: D3E10020 1C8255BA
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 000000002F68: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 000000002F70: D3E10020 1C8259BC
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000002F78: E0511080 80050012
  "s_add_u32     m0, 0x00000080, s37                    \n"// 000000002F80: 807C25FF 00000080
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 000000002F88: D3E10020 1C825DBE
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000002F90: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000002F98: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000002FA0: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000002FA8: D1ED00AB 00D2331B
  "s_waitcnt     lgkmcnt(1)                             \n"// 000000002FB0: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 000000002FB4: D3E10020 1C8261C0
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:128 lds\n"// 000000002FBC: E0511080 80050013
  "s_add_u32     m0, 0x00000100, s36                    \n"// 000000002FC4: 807C24FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 000000002FCC: D3E10020 1C8265C2
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000002FD4: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 000000002FDC: D3E10020 1C8269C4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000002FE4: E0511100 80050012
  "s_add_u32     m0, 0x00000100, s37                    \n"// 000000002FEC: 807C25FF 00000100
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000002FF4: D3E10020 1C826DC6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 000000002FFC: D3E10020 1C8271C8
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:256 lds\n"// 000000003004: E0511100 80050013
  "s_add_u32     m0, 0x00000180, s36                    \n"// 00000000300C: 807C24FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000003014: D3E10020 1C8275CA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 00000000301C: D3E10020 1C8279CC
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000003024: E0511180 80050012
  "s_add_u32     m0, 0x00000180, s37                    \n"// 00000000302C: 807C25FF 00000180
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 000000003034: D3E10020 1C827DCE
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 00000000303C: D3E10020 1C8281D0
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:384 lds\n"// 000000003044: E0511180 80050013
  "s_add_u32     m0, 0x00000200, s36                    \n"// 00000000304C: 807C24FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 000000003054: D3E10020 1C8285D2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 00000000305C: D3E10020 1C8289D4
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000003064: E0511200 80050012
  "s_add_u32     m0, 0x00000200, s37                    \n"// 00000000306C: 807C25FF 00000200
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 000000003074: D3E10020 1C828DD6
  "v_add_u32     v8, s73, v8                            \n"// 00000000307C: 68101049
  "s_cmp_le_i32  s83, s82                               \n"// 000000003080: BF055253
  "s_cbranch_scc1  label_0C46                           \n"// 000000003084: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 000000003088: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 000000003090: 80398052
  "v_mov_b32     v24, s57                               \n"// 000000003094: 7E300239
  "v_add_u32     v24, %[wave_id], v24                           \n"// 000000003098: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 00000000309C: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 0000000030A0: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 0000000030A4: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 0000000030A8: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 0000000030AC: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 0000000030B0: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 0000000030B4: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 0000000030B8: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 0000000030C0: 682828C0
  "s_nop         0x0000                                 \n"// 0000000030C4: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 0000000030C8: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 0000000030D0: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 0000000030D8: 682A2AC0
  "s_nop         0x0000                                 \n"// 0000000030DC: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 0000000030E0: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 0000000030E8: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 0000000030F0: 682C2CC0
  "s_nop         0x0000                                 \n"// 0000000030F4: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 0000000030F8: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000003100: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000003108: 682E2EC0
  "s_nop         0x0000                                 \n"// 00000000310C: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000003110: D1000023 009A4719
"label_0C46: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003118: BF8CC07F
  "s_barrier                                            \n"// 00000000311C: BF8A0000
  "v_max3_f32    v24, v32, v33, v32                     \n"// 000000003120: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 000000003128: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 000000003130: D81AD100 00001803
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:512 lds\n"// 000000003138: E0511200 80050013
  "s_add_u32     m0, 0x00000280, s36                    \n"// 000000003140: 807C24FF 00000280
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 000000003148: E0511280 80050012
  "s_add_u32     m0, 0x00000280, s37                    \n"// 000000003150: 807C25FF 00000280
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003158: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 00000000315C: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 000000003164: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 00000000316C: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 000000003174: D86CD1C0 17000002
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:640 lds\n"// 00000000317C: E0511280 80050013
  "s_add_u32     m0, 0x00000300, s36                    \n"// 000000003184: 807C24FF 00000300
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 00000000318C: E0511300 80050012
  "s_add_u32     m0, 0x00000300, s37                    \n"// 000000003194: 807C25FF 00000300
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:768 lds\n"// 00000000319C: E0511300 80050013
  "s_add_u32     m0, 0x00000380, s36                    \n"// 0000000031A4: 807C24FF 00000380
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000031AC: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 0000000031B0: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 0000000031B8: D1D30018 04622F16
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 0000000031C0: E0511380 80050012
  "s_add_u32     m0, 0x00000380, s37                    \n"// 0000000031C8: 807C25FF 00000380
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:896 lds\n"// 0000000031D0: E0511380 80050013
  "s_add_u32     m0, 0x00000400, s36                    \n"// 0000000031D8: 807C24FF 00000400
  "buffer_load_dword   v18, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 0000000031E0: E0511400 80050012
  "s_add_u32     m0, 0x00000400, s37                    \n"// 0000000031E8: 807C25FF 00000400
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 0000000031F0: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 0000000031F8: DBFE9500 94000007
  "buffer_load_dword   v19, [%[kv_res_0], %[kv_res_1], %[kv_res_2], %[kv_res_3]], 0 offen offset:1024 lds\n"// 000000003200: E0511400 80050013
  "s_add_u32     m0, 0x00000480, s36                    \n"// 000000003208: 807C24FF 00000480
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000003210: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000003218: DBFE9D00 9C000007
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000003220: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000003228: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 000000003230: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 000000003238: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 000000003240: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 000000003248: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 000000003250: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 000000003254: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 000000003258: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 000000003260: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 000000003264: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 000000003268: 0A202005
  "v_exp_f32     v16, v16                               \n"// 00000000326C: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 000000003270: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 000000003278: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 000000003280: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 000000003288: D1CB0023 84540B23
  "v_exp_f32     v32, v32                               \n"// 000000003290: 7E404120
  "v_exp_f32     v33, v33                               \n"// 000000003294: 7E424121
  "v_exp_f32     v34, v34                               \n"// 000000003298: 7E444122
  "v_exp_f32     v35, v35                               \n"// 00000000329C: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 0000000032A0: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 0000000032A4: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 0000000032A8: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 0000000032AC: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 0000000032B0: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 0000000032B4: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 0000000032B8: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 0000000032C0: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 0000000032C8: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 0000000032D0: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 0000000032D8: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000032E0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 0000000032E8: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 0000000032F0: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000032F8: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000003300: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000003308: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000003310: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000003318: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000003320: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000003328: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000003330: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 000000003338: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 000000003340: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 000000003344: 80535354
  "s_nop         0x0000                                 \n"// 000000003348: BF800000
  "v_mul_u32_u24  v18, v10, v9 row_newbcast:0           \n"// 00000000334C: 102412FA FF01500A
  "v_mul_u32_u24  v19, v10, v9 row_newbcast:8           \n"// 000000003354: 102612FA FF01580A
  "v_add_u32     v18, v18, v1                           \n"// 00000000335C: 68240312
  "v_add_u32     v19, v19, v1                           \n"// 000000003360: 68260313
  "s_mov_b32     m0, s34                                \n"// 000000003364: BEFC0022
  "v_mov_b32     v22, v16                               \n"// 000000003368: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 00000000336C: 7E2E0310
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 000000003370: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 000000003378: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 000000003380: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 000000003388: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 000000003390: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 000000003398: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 0000000033A0: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 0000000033A8: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 0000000033B0: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 0000000033B8: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 0000000033C0: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 0000000033C8: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 0000000033D0: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 0000000033D8: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 0000000033E0: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 0000000033E8: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 0000000033F0: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 0000000033F8: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 000000003400: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 000000003408: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 000000003410: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 000000003418: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 000000003420: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 000000003428: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000003430: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 000000003438: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000003440: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 000000003448: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000003450: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 000000003458: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 000000003460: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 000000003468: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 000000003470: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 000000003478: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 000000003480: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 000000003488: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 000000003490: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 000000003498: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 0000000034A0: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 0000000034A8: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 0000000034B0: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 0000000034B8: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 0000000034C0: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 0000000034C8: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 0000000034D0: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 0000000034D8: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 0000000034E0: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 0000000034E8: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 0000000034F0: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 0000000034F8: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 000000003500: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 000000003508: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 000000003510: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 000000003518: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 000000003520: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 000000003528: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000003530: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 000000003538: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000003540: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 000000003548: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000003550: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 000000003558: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 000000003560: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 000000003568: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003570: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 000000003574: D3E10028 0CA24190
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 00000000357C: D3E1002C 0CB24192
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 000000003584: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 00000000358C: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 000000003594: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 00000000359C: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 0000000035A4: D3E10038 0CE24198
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 0000000035AC: D3E1003C 0CF2419A
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 0000000035B4: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 0000000035BC: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 0000000035C4: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 0000000035CC: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 0000000035D4: D3E10048 0D2241A0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 0000000035DC: D3E1004C 0D3241A2
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 0000000035E4: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 0000000035EC: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 0000000035F4: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 0000000035FC: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 000000003604: D3E10058 0D6241A8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 00000000360C: D3E1005C 0D7241AA
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 000000003614: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 00000000361C: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 000000003624: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 00000000362C: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000003634: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 000000003638: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000003640: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 000000003648: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000003650: BF8C4072
  "s_barrier                                            \n"// 000000003654: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 000000003658: D3E10074 0DD241B6
  "ds_read_b64   v[20:21], v5                           \n"// 000000003660: D8EC0000 14000005
  "ds_read_b64   v[22:23], v5 offset:4640               \n"// 000000003668: D8EC1220 16000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 000000003670: D3E10078 0DE241B8
  "ds_read_b64   v[24:25], v5 offset:9280               \n"// 000000003678: D8EC2440 18000005
  "ds_read_b64   v[26:27], v5 offset:13920              \n"// 000000003680: D8EC3660 1A000005
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 000000003688: D3E1007C 0DF241BA
  "ds_read_b128  acc[144:147], v4                       \n"// 000000003690: DBFE0000 90000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 000000003698: D3E10080 0E0241BC
  "ds_read_b128  acc[148:151], v4 offset:64             \n"// 0000000036A0: DBFE0040 94000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 0000000036A8: D3E10084 0E1241BE
  "ds_read_b128  acc[152:155], v4 offset:256            \n"// 0000000036B0: DBFE0100 98000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 0000000036B8: D3E10088 0E2241C0
  "ds_read_b128  acc[156:159], v4 offset:320            \n"// 0000000036C0: DBFE0140 9C000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 0000000036C8: D3E1008C 0E3241C2
  "ds_read_b128  acc[160:163], v4 offset:512            \n"// 0000000036D0: DBFE0200 A0000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 0000000036D8: D3E10090 0E4241C4
  "ds_read_b128  acc[164:167], v4 offset:576            \n"// 0000000036E0: DBFE0240 A4000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 0000000036E8: D3E10094 0E5241C6
  "ds_read_b128  acc[168:171], v4 offset:768            \n"// 0000000036F0: DBFE0300 A8000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 0000000036F8: D3E10098 0E6241C8
  "ds_read_b128  acc[172:175], v4 offset:832            \n"// 000000003700: DBFE0340 AC000004
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 000000003708: D3E1009C 0E7241CA
  "s_waitcnt     lgkmcnt(8)                             \n"// 000000003710: BF8CC87F
  "v_perm_b32    v168, v22, v20, s53                    \n"// 000000003714: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 00000000371C: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 000000003724: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 00000000372C: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000003734: D3E100A0 0E8241CC
  "ds_write_b128  v6, v[168:171] offset:37120           \n"// 00000000373C: D9BE9100 0000A806
  "v_perm_b32    v168, v23, v21, s53                    \n"// 000000003744: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 00000000374C: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000003754: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 00000000375C: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 000000003764: D3E100A4 0E9241CE
  "ds_write_b128  v6, v[168:171] offset:38144           \n"// 00000000376C: D9BE9500 0000A806
  "ds_read_b64   v[20:21], v5 offset:1024               \n"// 000000003774: D8EC0400 14000005
  "ds_read_b64   v[22:23], v5 offset:5664               \n"// 00000000377C: D8EC1620 16000005
  "ds_read_b64   v[24:25], v5 offset:10304              \n"// 000000003784: D8EC2840 18000005
  "ds_read_b64   v[26:27], v5 offset:14944              \n"// 00000000378C: D8EC3A60 1A000005
  "s_nop         0x0000                                 \n"// 000000003794: BF800000
  "s_addk_i32    s70, 0x0001                            \n"// 000000003798: B7460001
  "s_cmp_lt_i32  s70, s71                               \n"// 00000000379C: BF044746
  "s_cbranch_scc0  label_091E                           \n"// 0000000037A0: BF84FB35
  "s_branch      label_0921                             \n"// 0000000037A4: BF82FB37
"label_0DEA: \n"
  "s_cmp_eq_i32  s48, 0                                 \n"// 0000000037A8: BF008030
  "s_cbranch_scc1  label_11EB                           \n"// 0000000037AC: BF8503FF
"label_0DEC: \n"
  "s_and_b32     s56, s71, 1                            \n"// 0000000037B0: 86388147
  "s_cmp_eq_i32  s56, 1                                 \n"// 0000000037B4: BF008138
  "s_cbranch_scc1  label_0FED                           \n"// 0000000037B8: BF8501FE
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000037BC: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 0000000037C0: D3E10020 1A020190
  "ds_read_b128  acc[176:179], v4 offset:1024           \n"// 0000000037C8: DBFE0400 B0000004
  "ds_read_b128  acc[180:183], v4 offset:1088           \n"// 0000000037D0: DBFE0440 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 0000000037D8: D3E10020 1C820592
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 0000000037E0: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 0000000037E8: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 0000000037F0: D3E10020 1C821198
  "ds_read_b128  acc[184:187], v4 offset:1280           \n"// 0000000037F8: DBFE0500 B8000004
  "ds_read_b128  acc[188:191], v4 offset:1344           \n"// 000000003800: DBFE0540 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 000000003808: D3E10020 1C82159A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 000000003810: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 000000003818: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000003820: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 000000003824: D3E10020 1C8221A0
  "ds_read_b128  acc[192:195], v4 offset:1536           \n"// 00000000382C: DBFE0600 C0000004
  "ds_read_b128  acc[196:199], v4 offset:1600           \n"// 000000003834: DBFE0640 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 00000000383C: D3E10020 1C8225A2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 000000003844: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 00000000384C: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 000000003854: D3E10020 1C8231A8
  "ds_read_b128  acc[200:203], v4 offset:1792           \n"// 00000000385C: DBFE0700 C8000004
  "ds_read_b128  acc[204:207], v4 offset:1856           \n"// 000000003864: DBFE0740 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 00000000386C: D3E10020 1C8235AA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 000000003874: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 00000000387C: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000003884: BF8CC47F
  "s_barrier                                            \n"// 000000003888: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 00000000388C: D3E10020 1C8241B0
  "ds_read_b128  acc[208:211], v4 offset:2048           \n"// 000000003894: DBFE0800 D0000004
  "ds_read_b128  acc[212:215], v4 offset:2112           \n"// 00000000389C: DBFE0840 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 0000000038A4: D3E10020 1C8245B2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 0000000038AC: D3E10020 1C8249B4
  "v_perm_b32    v168, v22, v20, s53                    \n"// 0000000038B4: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 0000000038BC: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 0000000038C4: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 0000000038CC: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 0000000038D4: D3E10020 1C824DB6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 0000000038DC: D3E10020 1C8251B8
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 0000000038E4: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 0000000038EC: D3E10020 1C8255BA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 0000000038F4: D3E10020 1C8259BC
  "v_perm_b32    v168, v23, v21, s53                    \n"// 0000000038FC: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 000000003904: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 00000000390C: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 000000003914: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 00000000391C: D3E10020 1C825DBE
  "s_waitcnt     lgkmcnt(1)                             \n"// 000000003924: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 000000003928: D3E10020 1C8261C0
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000003930: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 000000003938: D3E10020 1C8265C2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 000000003940: D3E10020 1C8269C4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000003948: D3E10020 1C826DC6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 000000003950: D3E10020 1C8271C8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000003958: D3E10020 1C8275CA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 000000003960: D3E10020 1C8279CC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 000000003968: D3E10020 1C827DCE
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 000000003970: D3E10020 1C8281D0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 000000003978: D3E10020 1C8285D2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 000000003980: D3E10020 1C8289D4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 000000003988: D3E10020 1C828DD6
  "s_cmp_le_i32  s83, s82                               \n"// 000000003990: BF055253
  "s_cbranch_scc1  label_0E8A                           \n"// 000000003994: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 000000003998: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 0000000039A0: 80398052
  "v_mov_b32     v24, s57                               \n"// 0000000039A4: 7E300239
  "v_add_u32     v24, %[wave_id], v24                           \n"// 0000000039A8: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 0000000039AC: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 0000000039B0: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 0000000039B4: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 0000000039B8: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 0000000039BC: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 0000000039C0: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 0000000039C4: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 0000000039C8: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 0000000039D0: 682828C0
  "s_nop         0x0000                                 \n"// 0000000039D4: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 0000000039D8: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 0000000039E0: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 0000000039E8: 682A2AC0
  "s_nop         0x0000                                 \n"// 0000000039EC: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 0000000039F0: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 0000000039F8: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000003A00: 682C2CC0
  "s_nop         0x0000                                 \n"// 000000003A04: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000003A08: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000003A10: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000003A18: 682E2EC0
  "s_nop         0x0000                                 \n"// 000000003A1C: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000003A20: D1000023 009A4719
"label_0E8A: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003A28: BF8CC07F
  "s_barrier                                            \n"// 000000003A2C: BF8A0000
  "v_mov_b32     v25, 0xff800000                        \n"// 000000003A30: 7E3202FF FF800000
  "s_and_b32     s56, s48, 0x000000ff                   \n"// 000000003A38: 8638FF30 000000FF
  "v_mov_b32     v24, s56                               \n"// 000000003A40: 7E300238
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000003A44: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 000000003A48: 0C282884
  "v_add_u32     v21, 1, v20                            \n"// 000000003A4C: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 000000003A50: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 000000003A54: 682E2883
  "v_cmp_lt_u32  s[38:39], v20, v24                     \n"// 000000003A58: D0C90026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 000000003A60: 682828C0
  "s_nop         0x0000                                 \n"// 000000003A64: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 000000003A68: D1000020 009A4119
  "v_cmp_lt_u32  s[38:39], v21, v24                     \n"// 000000003A70: D0C90026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 000000003A78: 682A2AC0
  "s_nop         0x0000                                 \n"// 000000003A7C: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 000000003A80: D1000021 009A4319
  "v_cmp_lt_u32  s[38:39], v22, v24                     \n"// 000000003A88: D0C90026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000003A90: 682C2CC0
  "s_nop         0x0000                                 \n"// 000000003A94: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000003A98: D1000022 009A4519
  "v_cmp_lt_u32  s[38:39], v23, v24                     \n"// 000000003AA0: D0C90026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000003AA8: 682E2EC0
  "s_nop         0x0000                                 \n"// 000000003AAC: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000003AB0: D1000023 009A4719
  "v_max3_f32    v24, v32, v33, v32                     \n"// 000000003AB8: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 000000003AC0: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 000000003AC8: D81AD100 00001803
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003AD0: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 000000003AD4: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 000000003ADC: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 000000003AE4: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 000000003AEC: D86CD1C0 17000002
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003AF4: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 000000003AF8: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 000000003B00: D1D30018 04622F16
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 000000003B08: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 000000003B10: DBFE9500 94000007
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000003B18: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000003B20: DBFE9D00 9C000007
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000003B28: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000003B30: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 000000003B38: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 000000003B40: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 000000003B48: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 000000003B50: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 000000003B58: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 000000003B5C: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 000000003B60: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 000000003B68: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 000000003B6C: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 000000003B70: 0A202005
  "v_exp_f32     v16, v16                               \n"// 000000003B74: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 000000003B78: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 000000003B80: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 000000003B88: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 000000003B90: D1CB0023 84540B23
  "v_exp_f32     v32, v32                               \n"// 000000003B98: 7E404120
  "v_exp_f32     v33, v33                               \n"// 000000003B9C: 7E424121
  "v_exp_f32     v34, v34                               \n"// 000000003BA0: 7E444122
  "v_exp_f32     v35, v35                               \n"// 000000003BA4: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 000000003BA8: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 000000003BAC: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 000000003BB0: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 000000003BB4: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 000000003BB8: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 000000003BBC: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 000000003BC0: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 000000003BC8: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 000000003BD0: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 000000003BD8: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 000000003BE0: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000003BE8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 000000003BF0: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 000000003BF8: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000003C00: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000003C08: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000003C10: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000003C18: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000003C20: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000003C28: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000003C30: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000003C38: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 000000003C40: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 000000003C48: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 000000003C4C: 80535354
  "s_nop         0x0000                                 \n"// 000000003C50: BF800000
  "v_mov_b32     v22, v16                               \n"// 000000003C54: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 000000003C58: 7E2E0310
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 000000003C5C: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 000000003C64: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 000000003C6C: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 000000003C74: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 000000003C7C: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 000000003C84: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 000000003C8C: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 000000003C94: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 000000003C9C: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 000000003CA4: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 000000003CAC: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 000000003CB4: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 000000003CBC: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 000000003CC4: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 000000003CCC: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 000000003CD4: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 000000003CDC: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 000000003CE4: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 000000003CEC: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 000000003CF4: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 000000003CFC: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 000000003D04: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 000000003D0C: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 000000003D14: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000003D1C: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 000000003D24: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000003D2C: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 000000003D34: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000003D3C: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 000000003D44: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 000000003D4C: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 000000003D54: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 000000003D5C: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 000000003D64: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 000000003D6C: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 000000003D74: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 000000003D7C: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 000000003D84: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 000000003D8C: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 000000003D94: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 000000003D9C: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 000000003DA4: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 000000003DAC: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 000000003DB4: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 000000003DBC: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 000000003DC4: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 000000003DCC: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 000000003DD4: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 000000003DDC: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 000000003DE4: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 000000003DEC: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 000000003DF4: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 000000003DFC: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 000000003E04: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 000000003E0C: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 000000003E14: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000003E1C: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 000000003E24: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000003E2C: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 000000003E34: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000003E3C: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 000000003E44: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 000000003E4C: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 000000003E54: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000003E5C: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 000000003E60: D3E10028 0CA24190
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 000000003E68: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 000000003E70: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 000000003E78: D3E1002C 0CB24192
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 000000003E80: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 000000003E88: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 000000003E90: D3E10038 0CE24198
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 000000003E98: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 000000003EA0: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 000000003EA8: D3E1003C 0CF2419A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 000000003EB0: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 000000003EB8: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 000000003EC0: D3E10048 0D2241A0
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 000000003EC8: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 000000003ED0: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 000000003ED8: D3E1004C 0D3241A2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 000000003EE0: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 000000003EE8: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 000000003EF0: D3E10058 0D6241A8
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 000000003EF8: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 000000003F00: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 000000003F08: D3E1005C 0D7241AA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 000000003F10: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 000000003F18: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000003F20: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 000000003F24: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000003F2C: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 000000003F34: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000003F3C: BF8C4072
  "s_barrier                                            \n"// 000000003F40: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 000000003F44: D3E10074 0DD241B6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 000000003F4C: D3E10078 0DE241B8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 000000003F54: D3E1007C 0DF241BA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 000000003F5C: D3E10080 0E0241BC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 000000003F64: D3E10084 0E1241BE
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 000000003F6C: D3E10088 0E2241C0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 000000003F74: D3E1008C 0E3241C2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 000000003F7C: D3E10090 0E4241C4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 000000003F84: D3E10094 0E5241C6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 000000003F8C: D3E10098 0E6241C8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 000000003F94: D3E1009C 0E7241CA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000003F9C: D3E100A0 0E8241CC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 000000003FA4: D3E100A4 0E9241CE
  "s_nop         0x0008                                 \n"// 000000003FAC: BF800008
  "s_branch      label_11EB                             \n"// 000000003FB0: BF8201FE
"label_0FED: \n"
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000003FB4: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[144:145], acc[0:1], 0\n"// 000000003FB8: D3E10020 1A020190
  "ds_read_b128  acc[176:179], v4 offset:19584          \n"// 000000003FC0: DBFE4C80 B0000004
  "ds_read_b128  acc[180:183], v4 offset:19648          \n"// 000000003FC8: DBFE4CC0 B4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[146:147], acc[2:3], v[32:35]\n"// 000000003FD0: D3E10020 1C820592
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[148:149], acc[4:5], v[32:35]\n"// 000000003FD8: D3E10020 1C820994
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[150:151], acc[6:7], v[32:35]\n"// 000000003FE0: D3E10020 1C820D96
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[152:153], acc[8:9], v[32:35]\n"// 000000003FE8: D3E10020 1C821198
  "ds_read_b128  acc[184:187], v4 offset:19840          \n"// 000000003FF0: DBFE4D80 B8000004
  "ds_read_b128  acc[188:191], v4 offset:19904          \n"// 000000003FF8: DBFE4DC0 BC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[154:155], acc[10:11], v[32:35]\n"// 000000004000: D3E10020 1C82159A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[156:157], acc[12:13], v[32:35]\n"// 000000004008: D3E10020 1C82199C
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[158:159], acc[14:15], v[32:35]\n"// 000000004010: D3E10020 1C821D9E
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000004018: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[160:161], acc[16:17], v[32:35]\n"// 00000000401C: D3E10020 1C8221A0
  "ds_read_b128  acc[192:195], v4 offset:20096          \n"// 000000004024: DBFE4E80 C0000004
  "ds_read_b128  acc[196:199], v4 offset:20160          \n"// 00000000402C: DBFE4EC0 C4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[162:163], acc[18:19], v[32:35]\n"// 000000004034: D3E10020 1C8225A2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[164:165], acc[20:21], v[32:35]\n"// 00000000403C: D3E10020 1C8229A4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[166:167], acc[22:23], v[32:35]\n"// 000000004044: D3E10020 1C822DA6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[168:169], acc[24:25], v[32:35]\n"// 00000000404C: D3E10020 1C8231A8
  "ds_read_b128  acc[200:203], v4 offset:20352          \n"// 000000004054: DBFE4F80 C8000004
  "ds_read_b128  acc[204:207], v4 offset:20416          \n"// 00000000405C: DBFE4FC0 CC000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[170:171], acc[26:27], v[32:35]\n"// 000000004064: D3E10020 1C8235AA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[172:173], acc[28:29], v[32:35]\n"// 00000000406C: D3E10020 1C8239AC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[174:175], acc[30:31], v[32:35]\n"// 000000004074: D3E10020 1C823DAE
  "s_waitcnt     lgkmcnt(4)                             \n"// 00000000407C: BF8CC47F
  "s_barrier                                            \n"// 000000004080: BF8A0000
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[176:177], acc[32:33], v[32:35]\n"// 000000004084: D3E10020 1C8241B0
  "ds_read_b128  acc[208:211], v4 offset:20608          \n"// 00000000408C: DBFE5080 D0000004
  "ds_read_b128  acc[212:215], v4 offset:20672          \n"// 000000004094: DBFE50C0 D4000004
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[178:179], acc[34:35], v[32:35]\n"// 00000000409C: D3E10020 1C8245B2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[180:181], acc[36:37], v[32:35]\n"// 0000000040A4: D3E10020 1C8249B4
  "v_perm_b32    v168, v22, v20, s53                    \n"// 0000000040AC: D1ED00A8 00D62916
  "v_perm_b32    v170, v22, v20, s52                    \n"// 0000000040B4: D1ED00AA 00D22916
  "v_perm_b32    v169, v26, v24, s53                    \n"// 0000000040BC: D1ED00A9 00D6311A
  "v_perm_b32    v171, v26, v24, s52                    \n"// 0000000040C4: D1ED00AB 00D2311A
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[182:183], acc[38:39], v[32:35]\n"// 0000000040CC: D3E10020 1C824DB6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[184:185], acc[40:41], v[32:35]\n"// 0000000040D4: D3E10020 1C8251B8
  "ds_write_b128  v6, v[168:171] offset:45312           \n"// 0000000040DC: D9BEB100 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[186:187], acc[42:43], v[32:35]\n"// 0000000040E4: D3E10020 1C8255BA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[188:189], acc[44:45], v[32:35]\n"// 0000000040EC: D3E10020 1C8259BC
  "v_perm_b32    v168, v23, v21, s53                    \n"// 0000000040F4: D1ED00A8 00D62B17
  "v_perm_b32    v170, v23, v21, s52                    \n"// 0000000040FC: D1ED00AA 00D22B17
  "v_perm_b32    v169, v27, v25, s53                    \n"// 000000004104: D1ED00A9 00D6331B
  "v_perm_b32    v171, v27, v25, s52                    \n"// 00000000410C: D1ED00AB 00D2331B
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[190:191], acc[46:47], v[32:35]\n"// 000000004114: D3E10020 1C825DBE
  "s_waitcnt     lgkmcnt(1)                             \n"// 00000000411C: BF8CC17F
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[192:193], acc[48:49], v[32:35]\n"// 000000004120: D3E10020 1C8261C0
  "ds_write_b128  v6, v[168:171] offset:46336           \n"// 000000004128: D9BEB500 0000A806
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[194:195], acc[50:51], v[32:35]\n"// 000000004130: D3E10020 1C8265C2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[196:197], acc[52:53], v[32:35]\n"// 000000004138: D3E10020 1C8269C4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[198:199], acc[54:55], v[32:35]\n"// 000000004140: D3E10020 1C826DC6
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[200:201], acc[56:57], v[32:35]\n"// 000000004148: D3E10020 1C8271C8
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[202:203], acc[58:59], v[32:35]\n"// 000000004150: D3E10020 1C8275CA
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[204:205], acc[60:61], v[32:35]\n"// 000000004158: D3E10020 1C8279CC
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[206:207], acc[62:63], v[32:35]\n"// 000000004160: D3E10020 1C827DCE
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[208:209], acc[64:65], v[32:35]\n"// 000000004168: D3E10020 1C8281D0
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[210:211], acc[66:67], v[32:35]\n"// 000000004170: D3E10020 1C8285D2
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[212:213], acc[68:69], v[32:35]\n"// 000000004178: D3E10020 1C8289D4
  "v_mfma_f32_16x16x16_bf16  v[32:35], acc[214:215], acc[70:71], v[32:35]\n"// 000000004180: D3E10020 1C828DD6
  "s_cmp_le_i32  s83, s82                               \n"// 000000004188: BF055253
  "s_cbranch_scc1  label_1088                           \n"// 00000000418C: BF850024
  "v_mov_b32     v25, 0xff800000                        \n"// 000000004190: 7E3202FF FF800000
  "s_add_u32     s57, s82, 0                            \n"// 000000004198: 80398052
  "v_mov_b32     v24, s57                               \n"// 00000000419C: 7E300239
  "v_add_u32     v24, %[wave_id], v24                           \n"// 0000000041A0: 68303007
  "s_sub_u32     s56, s83, 15                           \n"// 0000000041A4: 80B88F53
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 0000000041A8: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 0000000041AC: 0C282884
  "v_add_u32     v20, s56, v20                          \n"// 0000000041B0: 68282838
  "v_add_u32     v21, 1, v20                            \n"// 0000000041B4: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 0000000041B8: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 0000000041BC: 682E2883
  "v_cmp_le_u32  s[38:39], v20, v24                     \n"// 0000000041C0: D0CB0026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 0000000041C8: 682828C0
  "s_nop         0x0000                                 \n"// 0000000041CC: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 0000000041D0: D1000020 009A4119
  "v_cmp_le_u32  s[38:39], v21, v24                     \n"// 0000000041D8: D0CB0026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 0000000041E0: 682A2AC0
  "s_nop         0x0000                                 \n"// 0000000041E4: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 0000000041E8: D1000021 009A4319
  "v_cmp_le_u32  s[38:39], v22, v24                     \n"// 0000000041F0: D0CB0026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 0000000041F8: 682C2CC0
  "s_nop         0x0000                                 \n"// 0000000041FC: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000004200: D1000022 009A4519
  "v_cmp_le_u32  s[38:39], v23, v24                     \n"// 000000004208: D0CB0026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 000000004210: 682E2EC0
  "s_nop         0x0000                                 \n"// 000000004214: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 000000004218: D1000023 009A4719
"label_1088: \n"
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000004220: BF8CC07F
  "s_barrier                                            \n"// 000000004224: BF8A0000
  "v_mov_b32     v25, 0xff800000                        \n"// 000000004228: 7E3202FF FF800000
  "s_and_b32     s56, s48, 0x000000ff                   \n"// 000000004230: 8638FF30 000000FF
  "v_mov_b32     v24, s56                               \n"// 000000004238: 7E300238
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 00000000423C: 20280084
  "v_mul_i32_i24  v20, 4, v20                           \n"// 000000004240: 0C282884
  "v_add_u32     v21, 1, v20                            \n"// 000000004244: 682A2881
  "v_add_u32     v22, 2, v20                            \n"// 000000004248: 682C2882
  "v_add_u32     v23, 3, v20                            \n"// 00000000424C: 682E2883
  "v_cmp_lt_u32  s[38:39], v20, v24                     \n"// 000000004250: D0C90026 00023114
  "v_add_u32     v20, 64, v20                           \n"// 000000004258: 682828C0
  "s_nop         0x0000                                 \n"// 00000000425C: BF800000
  "v_cndmask_b32  v32, v25, v32, s[38:39]               \n"// 000000004260: D1000020 009A4119
  "v_cmp_lt_u32  s[38:39], v21, v24                     \n"// 000000004268: D0C90026 00023115
  "v_add_u32     v21, 64, v21                           \n"// 000000004270: 682A2AC0
  "s_nop         0x0000                                 \n"// 000000004274: BF800000
  "v_cndmask_b32  v33, v25, v33, s[38:39]               \n"// 000000004278: D1000021 009A4319
  "v_cmp_lt_u32  s[38:39], v22, v24                     \n"// 000000004280: D0C90026 00023116
  "v_add_u32     v22, 64, v22                           \n"// 000000004288: 682C2CC0
  "s_nop         0x0000                                 \n"// 00000000428C: BF800000
  "v_cndmask_b32  v34, v25, v34, s[38:39]               \n"// 000000004290: D1000022 009A4519
  "v_cmp_lt_u32  s[38:39], v23, v24                     \n"// 000000004298: D0C90026 00023117
  "v_add_u32     v23, 64, v23                           \n"// 0000000042A0: 682E2EC0
  "s_nop         0x0000                                 \n"// 0000000042A4: BF800000
  "v_cndmask_b32  v35, v25, v35, s[38:39]               \n"// 0000000042A8: D1000023 009A4719
  "v_max3_f32    v24, v32, v33, v32                     \n"// 0000000042B0: D1D30018 04824320
  "v_max3_f32    v24, v34, v35, v24                     \n"// 0000000042B8: D1D30018 04624722
  "ds_write_b32  v3, v24 offset:53504                   \n"// 0000000042C0: D81AD100 00001803
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000042C8: BF8CC07F
  "ds_read_b32   v20, v2 offset:53504                   \n"// 0000000042CC: D86CD100 14000002
  "ds_read_b32   v21, v2 offset:53568                   \n"// 0000000042D4: D86CD140 15000002
  "ds_read_b32   v22, v2 offset:53632                   \n"// 0000000042DC: D86CD180 16000002
  "ds_read_b32   v23, v2 offset:53696                   \n"// 0000000042E4: D86CD1C0 17000002
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000042EC: BF8CC07F
  "v_max3_f32    v24, v20, v21, v24                     \n"// 0000000042F0: D1D30018 04622B14
  "v_max3_f32    v24, v22, v23, v24                     \n"// 0000000042F8: D1D30018 04622F16
  "ds_read_b128  acc[144:147], v7 offset:37120          \n"// 000000004300: DBFE9100 90000007
  "ds_read_b128  acc[148:151], v7 offset:38144          \n"// 000000004308: DBFE9500 94000007
  "ds_read_b128  acc[152:155], v7 offset:39168          \n"// 000000004310: DBFE9900 98000007
  "ds_read_b128  acc[156:159], v7 offset:40192          \n"// 000000004318: DBFE9D00 9C000007
  "ds_read_b128  acc[160:163], v7 offset:41216          \n"// 000000004320: DBFEA100 A0000007
  "ds_read_b128  acc[164:167], v7 offset:42240          \n"// 000000004328: DBFEA500 A4000007
  "ds_read_b128  acc[168:171], v7 offset:43264          \n"// 000000004330: DBFEA900 A8000007
  "ds_read_b128  acc[172:175], v7 offset:44288          \n"// 000000004338: DBFEAD00 AC000007
  "v_mov_b32     v25, 0xff7fffff                        \n"// 000000004340: 7E3202FF FF7FFFFF
  "v_cmp_eq_u32  s[38:39], v25, v12                     \n"// 000000004348: D0CA0026 00021919
  "v_max_f32     v20, v24, v12                          \n"// 000000004350: 16281918
  "v_sub_f32     v16, v12, v20                          \n"// 000000004354: 0420290C
  "v_cndmask_b32  v16, v16, 0, s[38:39]                 \n"// 000000004358: D1000010 00990110
  "v_mov_b32     v12, v20                               \n"// 000000004360: 7E180314
  "v_mul_f32     v21, s5, v20                           \n"// 000000004364: 0A2A2805
  "v_mul_f32     v16, s5, v16                           \n"// 000000004368: 0A202005
  "v_exp_f32     v16, v16                               \n"// 00000000436C: 7E204110
  "v_fma_f32     v32, v32, s5, -v21                     \n"// 000000004370: D1CB0020 84540B20
  "v_fma_f32     v33, v33, s5, -v21                     \n"// 000000004378: D1CB0021 84540B21
  "v_fma_f32     v34, v34, s5, -v21                     \n"// 000000004380: D1CB0022 84540B22
  "v_fma_f32     v35, v35, s5, -v21                     \n"// 000000004388: D1CB0023 84540B23
  "v_exp_f32     v32, v32                               \n"// 000000004390: 7E404120
  "v_exp_f32     v33, v33                               \n"// 000000004394: 7E424121
  "v_exp_f32     v34, v34                               \n"// 000000004398: 7E444122
  "v_exp_f32     v35, v35                               \n"// 00000000439C: 7E464123
  "v_mul_f32     v14, v16, v14                          \n"// 0000000043A0: 0A1C1D10
  "v_mov_b32     v22, v32                               \n"// 0000000043A4: 7E2C0320
  "v_add_f32     v22, v33, v22                          \n"// 0000000043A8: 022C2D21
  "v_add_f32     v22, v34, v22                          \n"// 0000000043AC: 022C2D22
  "v_add_f32     v22, v35, v22                          \n"// 0000000043B0: 022C2D23
  "v_add_f32     v14, v22, v14                          \n"// 0000000043B4: 021C1D16
  "v_mov_b32     v29, 0xffff0000                        \n"// 0000000043B8: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 0000000043C0: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 0000000043C8: 7E3E02FF 00007FFF
  "v_cmp_u_f32   s[38:39], v32, v32                     \n"// 0000000043D0: D0480026 00024120
  "v_add3_u32    v28, v32, v31, 1                       \n"// 0000000043D8: D1FF001C 02063F20
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000043E0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v33, v33                     \n"// 0000000043E8: D0480026 00024321
  "v_add3_u32    v28, v33, v31, 1                       \n"// 0000000043F0: D1FF001C 02063F21
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000043F8: D1000015 009A3D1C
  "v_perm_b32    v32, v21, v20, s52                     \n"// 000000004400: D1ED0020 00D22915
  "v_cmp_u_f32   s[38:39], v34, v34                     \n"// 000000004408: D0480026 00024522
  "v_add3_u32    v28, v34, v31, 1                       \n"// 000000004410: D1FF001C 02063F22
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004418: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v35, v35                     \n"// 000000004420: D0480026 00024723
  "v_add3_u32    v28, v35, v31, 1                       \n"// 000000004428: D1FF001C 02063F23
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004430: D1000015 009A3D1C
  "v_perm_b32    v33, v21, v20, s52                     \n"// 000000004438: D1ED0021 00D22915
  "s_nop         0x0002                                 \n"// 000000004440: BF800002
  "s_add_u32     s83, s84, s83                          \n"// 000000004444: 80535354
  "s_nop         0x0000                                 \n"// 000000004448: BF800000
  "v_mov_b32     v22, v16                               \n"// 00000000444C: 7E2C0310
  "v_mov_b32     v23, v16                               \n"// 000000004450: 7E2E0310
  "v_pk_mul_f32  [%[o_regs_0], %[o_regs_1]], v[22:23], [%[o_regs_0], %[o_regs_1]]           \n"// 000000004454: D3B14028 18025116
  "v_pk_mul_f32  [%[o_regs_2], %[o_regs_3]], v[22:23], [%[o_regs_2], %[o_regs_3]]           \n"// 00000000445C: D3B1402A 18025516
  "v_pk_mul_f32  [%[o_regs_4], %[o_regs_5]], v[22:23], [%[o_regs_4], %[o_regs_5]]           \n"// 000000004464: D3B1402C 18025916
  "v_pk_mul_f32  [%[o_regs_6], %[o_regs_7]], v[22:23], [%[o_regs_6], %[o_regs_7]]           \n"// 00000000446C: D3B1402E 18025D16
  "v_pk_mul_f32  [%[o_regs_8], %[o_regs_9]], v[22:23], [%[o_regs_8], %[o_regs_9]]           \n"// 000000004474: D3B14030 18026116
  "v_pk_mul_f32  [%[o_regs_10], %[o_regs_11]], v[22:23], [%[o_regs_10], %[o_regs_11]]           \n"// 00000000447C: D3B14032 18026516
  "v_pk_mul_f32  [%[o_regs_12], %[o_regs_13]], v[22:23], [%[o_regs_12], %[o_regs_13]]           \n"// 000000004484: D3B14034 18026916
  "v_pk_mul_f32  [%[o_regs_14], %[o_regs_15]], v[22:23], [%[o_regs_14], %[o_regs_15]]           \n"// 00000000448C: D3B14036 18026D16
  "v_pk_mul_f32  [%[o_regs_16], %[o_regs_17]], v[22:23], [%[o_regs_16], %[o_regs_17]]           \n"// 000000004494: D3B14038 18027116
  "v_pk_mul_f32  [%[o_regs_18], %[o_regs_19]], v[22:23], [%[o_regs_18], %[o_regs_19]]           \n"// 00000000449C: D3B1403A 18027516
  "v_pk_mul_f32  [%[o_regs_20], %[o_regs_21]], v[22:23], [%[o_regs_20], %[o_regs_21]]           \n"// 0000000044A4: D3B1403C 18027916
  "v_pk_mul_f32  [%[o_regs_22], %[o_regs_23]], v[22:23], [%[o_regs_22], %[o_regs_23]]           \n"// 0000000044AC: D3B1403E 18027D16
  "v_pk_mul_f32  [%[o_regs_24], %[o_regs_25]], v[22:23], [%[o_regs_24], %[o_regs_25]]           \n"// 0000000044B4: D3B14040 18028116
  "v_pk_mul_f32  [%[o_regs_26], %[o_regs_27]], v[22:23], [%[o_regs_26], %[o_regs_27]]           \n"// 0000000044BC: D3B14042 18028516
  "v_pk_mul_f32  [%[o_regs_28], %[o_regs_29]], v[22:23], [%[o_regs_28], %[o_regs_29]]           \n"// 0000000044C4: D3B14044 18028916
  "v_pk_mul_f32  [%[o_regs_30], %[o_regs_31]], v[22:23], [%[o_regs_30], %[o_regs_31]]           \n"// 0000000044CC: D3B14046 18028D16
  "v_pk_mul_f32  [%[o_regs_32], %[o_regs_33]], v[22:23], [%[o_regs_32], %[o_regs_33]]           \n"// 0000000044D4: D3B14048 18029116
  "v_pk_mul_f32  [%[o_regs_34], %[o_regs_35]], v[22:23], [%[o_regs_34], %[o_regs_35]]           \n"// 0000000044DC: D3B1404A 18029516
  "v_pk_mul_f32  [%[o_regs_36], %[o_regs_37]], v[22:23], [%[o_regs_36], %[o_regs_37]]           \n"// 0000000044E4: D3B1404C 18029916
  "v_pk_mul_f32  [%[o_regs_38], %[o_regs_39]], v[22:23], [%[o_regs_38], %[o_regs_39]]           \n"// 0000000044EC: D3B1404E 18029D16
  "v_pk_mul_f32  [%[o_regs_40], %[o_regs_41]], v[22:23], [%[o_regs_40], %[o_regs_41]]           \n"// 0000000044F4: D3B14050 1802A116
  "v_pk_mul_f32  [%[o_regs_42], %[o_regs_43]], v[22:23], [%[o_regs_42], %[o_regs_43]]           \n"// 0000000044FC: D3B14052 1802A516
  "v_pk_mul_f32  [%[o_regs_44], %[o_regs_45]], v[22:23], [%[o_regs_44], %[o_regs_45]]           \n"// 000000004504: D3B14054 1802A916
  "v_pk_mul_f32  [%[o_regs_46], %[o_regs_47]], v[22:23], [%[o_regs_46], %[o_regs_47]]           \n"// 00000000450C: D3B14056 1802AD16
  "v_pk_mul_f32  [%[o_regs_48], %[o_regs_49]], v[22:23], [%[o_regs_48], %[o_regs_49]]           \n"// 000000004514: D3B14058 1802B116
  "v_pk_mul_f32  [%[o_regs_50], %[o_regs_51]], v[22:23], [%[o_regs_50], %[o_regs_51]]           \n"// 00000000451C: D3B1405A 1802B516
  "v_pk_mul_f32  [%[o_regs_52], %[o_regs_53]], v[22:23], [%[o_regs_52], %[o_regs_53]]           \n"// 000000004524: D3B1405C 1802B916
  "v_pk_mul_f32  [%[o_regs_54], %[o_regs_55]], v[22:23], [%[o_regs_54], %[o_regs_55]]           \n"// 00000000452C: D3B1405E 1802BD16
  "v_pk_mul_f32  [%[o_regs_56], %[o_regs_57]], v[22:23], [%[o_regs_56], %[o_regs_57]]           \n"// 000000004534: D3B14060 1802C116
  "v_pk_mul_f32  [%[o_regs_58], %[o_regs_59]], v[22:23], [%[o_regs_58], %[o_regs_59]]           \n"// 00000000453C: D3B14062 1802C516
  "v_pk_mul_f32  [%[o_regs_60], %[o_regs_61]], v[22:23], [%[o_regs_60], %[o_regs_61]]       \n"// 000000004544: D3B14064 1802C916
  "v_pk_mul_f32  [%[o_regs_62], %[o_regs_63]], v[22:23], [%[o_regs_62], %[o_regs_63]]       \n"// 00000000454C: D3B14066 1802CD16
  "v_pk_mul_f32  [%[o_regs_64], %[o_regs_65]], v[22:23], [%[o_regs_64], %[o_regs_65]]       \n"// 000000004554: D3B14068 1802D116
  "v_pk_mul_f32  [%[o_regs_66], %[o_regs_67]], v[22:23], [%[o_regs_66], %[o_regs_67]]       \n"// 00000000455C: D3B1406A 1802D516
  "v_pk_mul_f32  [%[o_regs_68], %[o_regs_69]], v[22:23], [%[o_regs_68], %[o_regs_69]]       \n"// 000000004564: D3B1406C 1802D916
  "v_pk_mul_f32  [%[o_regs_70], %[o_regs_71]], v[22:23], [%[o_regs_70], %[o_regs_71]]       \n"// 00000000456C: D3B1406E 1802DD16
  "v_pk_mul_f32  [%[o_regs_72], %[o_regs_73]], v[22:23], [%[o_regs_72], %[o_regs_73]]       \n"// 000000004574: D3B14070 1802E116
  "v_pk_mul_f32  [%[o_regs_74], %[o_regs_75]], v[22:23], [%[o_regs_74], %[o_regs_75]]       \n"// 00000000457C: D3B14072 1802E516
  "v_pk_mul_f32  [%[o_regs_76], %[o_regs_77]], v[22:23], [%[o_regs_76], %[o_regs_77]]       \n"// 000000004584: D3B14074 1802E916
  "v_pk_mul_f32  [%[o_regs_78], %[o_regs_79]], v[22:23], [%[o_regs_78], %[o_regs_79]]       \n"// 00000000458C: D3B14076 1802ED16
  "v_pk_mul_f32  [%[o_regs_80], %[o_regs_81]], v[22:23], [%[o_regs_80], %[o_regs_81]]       \n"// 000000004594: D3B14078 1802F116
  "v_pk_mul_f32  [%[o_regs_82], %[o_regs_83]], v[22:23], [%[o_regs_82], %[o_regs_83]]       \n"// 00000000459C: D3B1407A 1802F516
  "v_pk_mul_f32  [%[o_regs_84], %[o_regs_85]], v[22:23], [%[o_regs_84], %[o_regs_85]]       \n"// 0000000045A4: D3B1407C 1802F916
  "v_pk_mul_f32  [%[o_regs_86], %[o_regs_87]], v[22:23], [%[o_regs_86], %[o_regs_87]]       \n"// 0000000045AC: D3B1407E 1802FD16
  "v_pk_mul_f32  [%[o_regs_88], %[o_regs_89]], v[22:23], [%[o_regs_88], %[o_regs_89]]       \n"// 0000000045B4: D3B14080 18030116
  "v_pk_mul_f32  [%[o_regs_90], %[o_regs_91]], v[22:23], [%[o_regs_90], %[o_regs_91]]       \n"// 0000000045BC: D3B14082 18030516
  "v_pk_mul_f32  [%[o_regs_92], %[o_regs_93]], v[22:23], [%[o_regs_92], %[o_regs_93]]       \n"// 0000000045C4: D3B14084 18030916
  "v_pk_mul_f32  [%[o_regs_94], %[o_regs_95]], v[22:23], [%[o_regs_94], %[o_regs_95]]       \n"// 0000000045CC: D3B14086 18030D16
  "v_pk_mul_f32  [%[o_regs_96], %[o_regs_97]], v[22:23], [%[o_regs_96], %[o_regs_97]]       \n"// 0000000045D4: D3B14088 18031116
  "v_pk_mul_f32  [%[o_regs_98], %[o_regs_99]], v[22:23], [%[o_regs_98], %[o_regs_99]]       \n"// 0000000045DC: D3B1408A 18031516
  "v_pk_mul_f32  [%[o_regs_100], %[o_regs_101]], v[22:23], [%[o_regs_100], %[o_regs_101]]       \n"// 0000000045E4: D3B1408C 18031916
  "v_pk_mul_f32  [%[o_regs_102], %[o_regs_103]], v[22:23], [%[o_regs_102], %[o_regs_103]]       \n"// 0000000045EC: D3B1408E 18031D16
  "v_pk_mul_f32  [%[o_regs_104], %[o_regs_105]], v[22:23], [%[o_regs_104], %[o_regs_105]]       \n"// 0000000045F4: D3B14090 18032116
  "v_pk_mul_f32  [%[o_regs_106], %[o_regs_107]], v[22:23], [%[o_regs_106], %[o_regs_107]]       \n"// 0000000045FC: D3B14092 18032516
  "v_pk_mul_f32  [%[o_regs_108], %[o_regs_109]], v[22:23], [%[o_regs_108], %[o_regs_109]]       \n"// 000000004604: D3B14094 18032916
  "v_pk_mul_f32  [%[o_regs_110], %[o_regs_111]], v[22:23], [%[o_regs_110], %[o_regs_111]]       \n"// 00000000460C: D3B14096 18032D16
  "v_pk_mul_f32  [%[o_regs_112], %[o_regs_113]], v[22:23], [%[o_regs_112], %[o_regs_113]]       \n"// 000000004614: D3B14098 18033116
  "v_pk_mul_f32  [%[o_regs_114], %[o_regs_115]], v[22:23], [%[o_regs_114], %[o_regs_115]]       \n"// 00000000461C: D3B1409A 18033516
  "v_pk_mul_f32  [%[o_regs_116], %[o_regs_117]], v[22:23], [%[o_regs_116], %[o_regs_117]]       \n"// 000000004624: D3B1409C 18033916
  "v_pk_mul_f32  [%[o_regs_118], %[o_regs_119]], v[22:23], [%[o_regs_118], %[o_regs_119]]       \n"// 00000000462C: D3B1409E 18033D16
  "v_pk_mul_f32  [%[o_regs_120], %[o_regs_121]], v[22:23], [%[o_regs_120], %[o_regs_121]]       \n"// 000000004634: D3B140A0 18034116
  "v_pk_mul_f32  [%[o_regs_122], %[o_regs_123]], v[22:23], [%[o_regs_122], %[o_regs_123]]       \n"// 00000000463C: D3B140A2 18034516
  "v_pk_mul_f32  [%[o_regs_124], %[o_regs_125]], v[22:23], [%[o_regs_124], %[o_regs_125]]       \n"// 000000004644: D3B140A4 18034916
  "v_pk_mul_f32  [%[o_regs_126], %[o_regs_127]], v[22:23], [%[o_regs_126], %[o_regs_127]]       \n"// 00000000464C: D3B140A6 18034D16
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000004654: BF8CC07F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], acc[144:145], v[32:33], [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]]\n"// 000000004658: D3E10028 0CA24190
  "ds_read_b128  acc[176:179], v7 offset:45312          \n"// 000000004660: DBFEB100 B0000007
  "ds_read_b128  acc[180:183], v7 offset:46336          \n"// 000000004668: DBFEB500 B4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], acc[146:147], v[32:33], [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]]\n"// 000000004670: D3E1002C 0CB24192
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], acc[148:149], v[32:33], [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]]\n"// 000000004678: D3E10030 0CC24194
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], acc[150:151], v[32:33], [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]]\n"// 000000004680: D3E10034 0CD24196
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], acc[152:153], v[32:33], [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]]\n"// 000000004688: D3E10038 0CE24198
  "ds_read_b128  acc[184:187], v7 offset:47360          \n"// 000000004690: DBFEB900 B8000007
  "ds_read_b128  acc[188:191], v7 offset:48384          \n"// 000000004698: DBFEBD00 BC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], acc[154:155], v[32:33], [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]]\n"// 0000000046A0: D3E1003C 0CF2419A
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], acc[156:157], v[32:33], [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]]\n"// 0000000046A8: D3E10040 0D02419C
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], acc[158:159], v[32:33], [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]]\n"// 0000000046B0: D3E10044 0D12419E
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]], acc[160:161], v[32:33], [%[o_regs_32], %[o_regs_33], %[o_regs_34], %[o_regs_35]]\n"// 0000000046B8: D3E10048 0D2241A0
  "ds_read_b128  acc[192:195], v7 offset:49408          \n"// 0000000046C0: DBFEC100 C0000007
  "ds_read_b128  acc[196:199], v7 offset:50432          \n"// 0000000046C8: DBFEC500 C4000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]], acc[162:163], v[32:33], [%[o_regs_36], %[o_regs_37], %[o_regs_38], %[o_regs_39]]\n"// 0000000046D0: D3E1004C 0D3241A2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]], acc[164:165], v[32:33], [%[o_regs_40], %[o_regs_41], %[o_regs_42], %[o_regs_43]]\n"// 0000000046D8: D3E10050 0D4241A4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]], acc[166:167], v[32:33], [%[o_regs_44], %[o_regs_45], %[o_regs_46], %[o_regs_47]]\n"// 0000000046E0: D3E10054 0D5241A6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]], acc[168:169], v[32:33], [%[o_regs_48], %[o_regs_49], %[o_regs_50], %[o_regs_51]]\n"// 0000000046E8: D3E10058 0D6241A8
  "ds_read_b128  acc[200:203], v7 offset:51456          \n"// 0000000046F0: DBFEC900 C8000007
  "ds_read_b128  acc[204:207], v7 offset:52480          \n"// 0000000046F8: DBFECD00 CC000007
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]], acc[170:171], v[32:33], [%[o_regs_52], %[o_regs_53], %[o_regs_54], %[o_regs_55]]\n"// 000000004700: D3E1005C 0D7241AA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]], acc[172:173], v[32:33], [%[o_regs_56], %[o_regs_57], %[o_regs_58], %[o_regs_59]]\n"// 000000004708: D3E10060 0D8241AC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]], acc[174:175], v[32:33], [%[o_regs_60], %[o_regs_61], %[o_regs_62], %[o_regs_63]]\n"// 000000004710: D3E10064 0D9241AE
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000004718: BF8CC47F
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]], acc[176:177], v[32:33], [%[o_regs_64], %[o_regs_65], %[o_regs_66], %[o_regs_67]]\n"// 00000000471C: D3E10068 0DA241B0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]], acc[178:179], v[32:33], [%[o_regs_68], %[o_regs_69], %[o_regs_70], %[o_regs_71]]\n"// 000000004724: D3E1006C 0DB241B2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]], acc[180:181], v[32:33], [%[o_regs_72], %[o_regs_73], %[o_regs_74], %[o_regs_75]]\n"// 00000000472C: D3E10070 0DC241B4
  "s_waitcnt     vmcnt(18) & lgkmcnt(0)                 \n"// 000000004734: BF8C4072
  "s_barrier                                            \n"// 000000004738: BF8A0000
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]], acc[182:183], v[32:33], [%[o_regs_76], %[o_regs_77], %[o_regs_78], %[o_regs_79]]\n"// 00000000473C: D3E10074 0DD241B6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]], acc[184:185], v[32:33], [%[o_regs_80], %[o_regs_81], %[o_regs_82], %[o_regs_83]]\n"// 000000004744: D3E10078 0DE241B8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]], acc[186:187], v[32:33], [%[o_regs_84], %[o_regs_85], %[o_regs_86], %[o_regs_87]]\n"// 00000000474C: D3E1007C 0DF241BA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]], acc[188:189], v[32:33], [%[o_regs_88], %[o_regs_89], %[o_regs_90], %[o_regs_91]]\n"// 000000004754: D3E10080 0E0241BC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]], acc[190:191], v[32:33], [%[o_regs_92], %[o_regs_93], %[o_regs_94], %[o_regs_95]]\n"// 00000000475C: D3E10084 0E1241BE
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]], acc[192:193], v[32:33], [%[o_regs_96], %[o_regs_97], %[o_regs_98], %[o_regs_99]]\n"// 000000004764: D3E10088 0E2241C0
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]], acc[194:195], v[32:33], [%[o_regs_100], %[o_regs_101], %[o_regs_102], %[o_regs_103]]\n"// 00000000476C: D3E1008C 0E3241C2
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]], acc[196:197], v[32:33], [%[o_regs_104], %[o_regs_105], %[o_regs_106], %[o_regs_107]]\n"// 000000004774: D3E10090 0E4241C4
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]], acc[198:199], v[32:33], [%[o_regs_108], %[o_regs_109], %[o_regs_110], %[o_regs_111]]\n"// 00000000477C: D3E10094 0E5241C6
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]], acc[200:201], v[32:33], [%[o_regs_112], %[o_regs_113], %[o_regs_114], %[o_regs_115]]\n"// 000000004784: D3E10098 0E6241C8
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]], acc[202:203], v[32:33], [%[o_regs_116], %[o_regs_117], %[o_regs_118], %[o_regs_119]]\n"// 00000000478C: D3E1009C 0E7241CA
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]], acc[204:205], v[32:33], [%[o_regs_120], %[o_regs_121], %[o_regs_122], %[o_regs_123]]\n"// 000000004794: D3E100A0 0E8241CC
  "v_mfma_f32_16x16x16_bf16  [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]], acc[206:207], v[32:33], [%[o_regs_124], %[o_regs_125], %[o_regs_126], %[o_regs_127]]\n"// 00000000479C: D3E100A4 0E9241CE
  "s_nop         0x0008                                 \n"// 0000000047A4: BF800008
  "s_branch      label_11EB                             \n"// 0000000047A8: BF820000
"label_11EB: \n"
  "ds_write_b32  v3, v14 offset:55552                   \n"// 0000000047AC: D81AD900 00000E03
  "ds_write_b32  v3, v15 offset:56576                   \n"// 0000000047B4: D81ADD00 00000F03
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000047BC: BF8CC07F
  "ds_read_b32   v20, v2 offset:55552                   \n"// 0000000047C0: D86CD900 14000002
  "ds_read_b32   v21, v2 offset:55616                   \n"// 0000000047C8: D86CD940 15000002
  "ds_read_b32   v22, v2 offset:55680                   \n"// 0000000047D0: D86CD980 16000002
  "ds_read_b32   v23, v2 offset:55744                   \n"// 0000000047D8: D86CD9C0 17000002
  "ds_read_b32   v24, v2 offset:56576                   \n"// 0000000047E0: D86CDD00 18000002
  "ds_read_b32   v25, v2 offset:56640                   \n"// 0000000047E8: D86CDD40 19000002
  "ds_read_b32   v26, v2 offset:56704                   \n"// 0000000047F0: D86CDD80 1A000002
  "ds_read_b32   v27, v2 offset:56768                   \n"// 0000000047F8: D86CDDC0 1B000002
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000004800: BF8CC07F
  "v_mov_b32     v14, 0                                 \n"// 000000004804: 7E1C0280
  "v_mov_b32     v15, 0                                 \n"// 000000004808: 7E1E0280
  "v_add_f32     v14, v20, v14                          \n"// 00000000480C: 021C1D14
  "v_add_f32     v15, v24, v15                          \n"// 000000004810: 021E1F18
  "v_add_f32     v14, v21, v14                          \n"// 000000004814: 021C1D15
  "v_add_f32     v15, v25, v15                          \n"// 000000004818: 021E1F19
  "v_add_f32     v14, v22, v14                          \n"// 00000000481C: 021C1D16
  "v_add_f32     v15, v26, v15                          \n"// 000000004820: 021E1F1A
  "v_add_f32     v14, v23, v14                          \n"// 000000004824: 021C1D17
  "v_add_f32     v15, v27, v15                          \n"// 000000004828: 021E1F1B
  "v_mov_b32     v20, 0                                 \n"// 00000000482C: 7E280280
  "v_cmp_eq_u32  s[38:39], v20, v14                     \n"// 000000004830: D0CA0026 00021D14
  "v_cmp_eq_u32  s[40:41], v20, v15                     \n"// 000000004838: D0CA0028 00021F14
  "v_mul_f32     v20, v12, %[s_scalar]                          \n"// 000000004840: D1050014 0000810C
  "v_mul_f32     v22, v13, %[s_scalar]                          \n"// 000000004848: D1050016 0000810D
  "v_log_f32     v21, v14                               \n"// 000000004850: 7E2A430E
  "v_log_f32     v23, v15                               \n"// 000000004854: 7E2E430F
  "v_cndmask_b32  v14, v14, 1.0, s[38:39]               \n"// 000000004858: D100000E 0099E50E
  "v_cndmask_b32  v15, v15, 1.0, s[40:41]               \n"// 000000004860: D100000F 00A1E50F
  "s_nop         0x0001                                 \n"// 000000004868: BF800001
  "v_rcp_f32     v14, v14                               \n"// 00000000486C: 7E1C450E
  "v_rcp_f32     v15, v15                               \n"// 000000004870: 7E1E450F
  "s_nop         0x0001                                 \n"// 000000004874: BF800001
  ";v_fma_f32     v24, v21, s63, v20                     \n"// 000000004878: D1CB0018 04507F15
  "v_fma_f32     %[lse_result], v21, s63, v20                     \n"// 000000004878: D1CB0018 04507F15
  "v_fma_f32     v25, v23, s63, v22                     \n"// 000000004880: D1CB0019 04587F17
  "v_mul_f32     %[o_regs_0], v14, %[o_regs_0]                          \n"// 000000004888: 0A50510E
  "v_mul_f32     %[o_regs_1], v14, %[o_regs_1]                          \n"// 00000000488C: 0A52530E
  "v_mul_f32     %[o_regs_2], v14, %[o_regs_2]                          \n"// 000000004890: 0A54550E
  "v_mul_f32     %[o_regs_3], v14, %[o_regs_3]                          \n"// 000000004894: 0A56570E
  "v_mul_f32     %[o_regs_4], v14, %[o_regs_4]                          \n"// 000000004898: 0A58590E
  "v_mul_f32     %[o_regs_5], v14, %[o_regs_5]                          \n"// 00000000489C: 0A5A5B0E
  "v_mul_f32     %[o_regs_6], v14, %[o_regs_6]                          \n"// 0000000048A0: 0A5C5D0E
  "v_mul_f32     %[o_regs_7], v14, %[o_regs_7]                          \n"// 0000000048A4: 0A5E5F0E
  "v_mul_f32     %[o_regs_8], v14, %[o_regs_8]                          \n"// 0000000048A8: 0A60610E
  "v_mul_f32     %[o_regs_9], v14, %[o_regs_9]                          \n"// 0000000048AC: 0A62630E
  "v_mul_f32     %[o_regs_10], v14, %[o_regs_10]                          \n"// 0000000048B0: 0A64650E
  "v_mul_f32     %[o_regs_11], v14, %[o_regs_11]                          \n"// 0000000048B4: 0A66670E
  "v_mul_f32     %[o_regs_12], v14, %[o_regs_12]                          \n"// 0000000048B8: 0A68690E
  "v_mul_f32     %[o_regs_13], v14, %[o_regs_13]                          \n"// 0000000048BC: 0A6A6B0E
  "v_mul_f32     %[o_regs_14], v14, %[o_regs_14]                          \n"// 0000000048C0: 0A6C6D0E
  "v_mul_f32     %[o_regs_15], v14, %[o_regs_15]                          \n"// 0000000048C4: 0A6E6F0E
  "v_mul_f32     %[o_regs_16], v14, %[o_regs_16]                          \n"// 0000000048C8: 0A70710E
  "v_mul_f32     %[o_regs_17], v14, %[o_regs_17]                          \n"// 0000000048CC: 0A72730E
  "v_mul_f32     %[o_regs_18], v14, %[o_regs_18]                          \n"// 0000000048D0: 0A74750E
  "v_mul_f32     %[o_regs_19], v14, %[o_regs_19]                          \n"// 0000000048D4: 0A76770E
  "v_mul_f32     %[o_regs_20], v14, %[o_regs_20]                          \n"// 0000000048D8: 0A78790E
  "v_mul_f32     %[o_regs_21], v14, %[o_regs_21]                          \n"// 0000000048DC: 0A7A7B0E
  "v_mul_f32     %[o_regs_22], v14, %[o_regs_22]                          \n"// 0000000048E0: 0A7C7D0E
  "v_mul_f32     %[o_regs_23], v14, %[o_regs_23]                          \n"// 0000000048E4: 0A7E7F0E
  "v_mul_f32     %[o_regs_24], v14, %[o_regs_24]                          \n"// 0000000048E8: 0A80810E
  "v_mul_f32     %[o_regs_25], v14, %[o_regs_25]                          \n"// 0000000048EC: 0A82830E
  "v_mul_f32     %[o_regs_26], v14, %[o_regs_26]                          \n"// 0000000048F0: 0A84850E
  "v_mul_f32     %[o_regs_27], v14, %[o_regs_27]                          \n"// 0000000048F4: 0A86870E
  "v_mul_f32     %[o_regs_28], v14, %[o_regs_28]                          \n"// 0000000048F8: 0A88890E
  "v_mul_f32     %[o_regs_29], v14, %[o_regs_29]                          \n"// 0000000048FC: 0A8A8B0E
  "v_mul_f32     %[o_regs_30], v14, %[o_regs_30]                          \n"// 000000004900: 0A8C8D0E
  "v_mul_f32     %[o_regs_31], v14, %[o_regs_31]                          \n"// 000000004904: 0A8E8F0E
  "v_mul_f32     %[o_regs_32], v14, %[o_regs_32]                          \n"// 000000004908: 0A90910E
  "v_mul_f32     %[o_regs_33], v14, %[o_regs_33]                          \n"// 00000000490C: 0A92930E
  "v_mul_f32     %[o_regs_34], v14, %[o_regs_34]                          \n"// 000000004910: 0A94950E
  "v_mul_f32     %[o_regs_35], v14, %[o_regs_35]                          \n"// 000000004914: 0A96970E
  "v_mul_f32     %[o_regs_36], v14, %[o_regs_36]                          \n"// 000000004918: 0A98990E
  "v_mul_f32     %[o_regs_37], v14, %[o_regs_37]                          \n"// 00000000491C: 0A9A9B0E
  "v_mul_f32     %[o_regs_38], v14, %[o_regs_38]                          \n"// 000000004920: 0A9C9D0E
  "v_mul_f32     %[o_regs_39], v14, %[o_regs_39]                          \n"// 000000004924: 0A9E9F0E
  "v_mul_f32     %[o_regs_40], v14, %[o_regs_40]                          \n"// 000000004928: 0AA0A10E
  "v_mul_f32     %[o_regs_41], v14, %[o_regs_41]                          \n"// 00000000492C: 0AA2A30E
  "v_mul_f32     %[o_regs_42], v14, %[o_regs_42]                          \n"// 000000004930: 0AA4A50E
  "v_mul_f32     %[o_regs_43], v14, %[o_regs_43]                          \n"// 000000004934: 0AA6A70E
  "v_mul_f32     %[o_regs_44], v14, %[o_regs_44]                          \n"// 000000004938: 0AA8A90E
  "v_mul_f32     %[o_regs_45], v14, %[o_regs_45]                          \n"// 00000000493C: 0AAAAB0E
  "v_mul_f32     %[o_regs_46], v14, %[o_regs_46]                          \n"// 000000004940: 0AACAD0E
  "v_mul_f32     %[o_regs_47], v14, %[o_regs_47]                          \n"// 000000004944: 0AAEAF0E
  "v_mul_f32     %[o_regs_48], v14, %[o_regs_48]                          \n"// 000000004948: 0AB0B10E
  "v_mul_f32     %[o_regs_49], v14, %[o_regs_49]                          \n"// 00000000494C: 0AB2B30E
  "v_mul_f32     %[o_regs_50], v14, %[o_regs_50]                          \n"// 000000004950: 0AB4B50E
  "v_mul_f32     %[o_regs_51], v14, %[o_regs_51]                          \n"// 000000004954: 0AB6B70E
  "v_mul_f32     %[o_regs_52], v14, %[o_regs_52]                          \n"// 000000004958: 0AB8B90E
  "v_mul_f32     %[o_regs_53], v14, %[o_regs_53]                          \n"// 00000000495C: 0ABABB0E
  "v_mul_f32     %[o_regs_54], v14, %[o_regs_54]                          \n"// 000000004960: 0ABCBD0E
  "v_mul_f32     %[o_regs_55], v14, %[o_regs_55]                          \n"// 000000004964: 0ABEBF0E
  "v_mul_f32     %[o_regs_56], v14, %[o_regs_56]                          \n"// 000000004968: 0AC0C10E
  "v_mul_f32     %[o_regs_57], v14, %[o_regs_57]                          \n"// 00000000496C: 0AC2C30E
  "v_mul_f32     %[o_regs_58], v14, %[o_regs_58]                          \n"// 000000004970: 0AC4C50E
  "v_mul_f32     %[o_regs_59], v14, %[o_regs_59]                          \n"// 000000004974: 0AC6C70E
  "v_mul_f32     %[o_regs_60], v14, %[o_regs_60]                        \n"// 000000004978: 0AC8C90E
  "v_mul_f32     %[o_regs_61], v14, %[o_regs_61]                        \n"// 00000000497C: 0ACACB0E
  "v_mul_f32     %[o_regs_62], v14, %[o_regs_62]                        \n"// 000000004980: 0ACCCD0E
  "v_mul_f32     %[o_regs_63], v14, %[o_regs_63]                        \n"// 000000004984: 0ACECF0E
  "v_mul_f32     %[o_regs_64], v14, %[o_regs_64]                        \n"// 000000004988: 0AD0D10E
  "v_mul_f32     %[o_regs_65], v14, %[o_regs_65]                        \n"// 00000000498C: 0AD2D30E
  "v_mul_f32     %[o_regs_66], v14, %[o_regs_66]                        \n"// 000000004990: 0AD4D50E
  "v_mul_f32     %[o_regs_67], v14, %[o_regs_67]                        \n"// 000000004994: 0AD6D70E
  "v_mul_f32     %[o_regs_68], v14, %[o_regs_68]                        \n"// 000000004998: 0AD8D90E
  "v_mul_f32     %[o_regs_69], v14, %[o_regs_69]                        \n"// 00000000499C: 0ADADB0E
  "v_mul_f32     %[o_regs_70], v14, %[o_regs_70]                        \n"// 0000000049A0: 0ADCDD0E
  "v_mul_f32     %[o_regs_71], v14, %[o_regs_71]                        \n"// 0000000049A4: 0ADEDF0E
  "v_mul_f32     %[o_regs_72], v14, %[o_regs_72]                        \n"// 0000000049A8: 0AE0E10E
  "v_mul_f32     %[o_regs_73], v14, %[o_regs_73]                        \n"// 0000000049AC: 0AE2E30E
  "v_mul_f32     %[o_regs_74], v14, %[o_regs_74]                        \n"// 0000000049B0: 0AE4E50E
  "v_mul_f32     %[o_regs_75], v14, %[o_regs_75]                        \n"// 0000000049B4: 0AE6E70E
  "v_mul_f32     %[o_regs_76], v14, %[o_regs_76]                        \n"// 0000000049B8: 0AE8E90E
  "v_mul_f32     %[o_regs_77], v14, %[o_regs_77]                        \n"// 0000000049BC: 0AEAEB0E
  "v_mul_f32     %[o_regs_78], v14, %[o_regs_78]                        \n"// 0000000049C0: 0AECED0E
  "v_mul_f32     %[o_regs_79], v14, %[o_regs_79]                        \n"// 0000000049C4: 0AEEEF0E
  "v_mul_f32     %[o_regs_80], v14, %[o_regs_80]                        \n"// 0000000049C8: 0AF0F10E
  "v_mul_f32     %[o_regs_81], v14, %[o_regs_81]                        \n"// 0000000049CC: 0AF2F30E
  "v_mul_f32     %[o_regs_82], v14, %[o_regs_82]                        \n"// 0000000049D0: 0AF4F50E
  "v_mul_f32     %[o_regs_83], v14, %[o_regs_83]                        \n"// 0000000049D4: 0AF6F70E
  "v_mul_f32     %[o_regs_84], v14, %[o_regs_84]                        \n"// 0000000049D8: 0AF8F90E
  "v_mul_f32     %[o_regs_85], v14, %[o_regs_85]                        \n"// 0000000049DC: 0AFAFB0E
  "v_mul_f32     %[o_regs_86], v14, %[o_regs_86]                        \n"// 0000000049E0: 0AFCFD0E
  "v_mul_f32     %[o_regs_87], v14, %[o_regs_87]                        \n"// 0000000049E4: 0AFEFF0E
  "v_mul_f32     %[o_regs_88], v14, %[o_regs_88]                        \n"// 0000000049E8: 0B01010E
  "v_mul_f32     %[o_regs_89], v14, %[o_regs_89]                        \n"// 0000000049EC: 0B03030E
  "v_mul_f32     %[o_regs_90], v14, %[o_regs_90]                        \n"// 0000000049F0: 0B05050E
  "v_mul_f32     %[o_regs_91], v14, %[o_regs_91]                        \n"// 0000000049F4: 0B07070E
  "v_mul_f32     %[o_regs_92], v14, %[o_regs_92]                        \n"// 0000000049F8: 0B09090E
  "v_mul_f32     %[o_regs_93], v14, %[o_regs_93]                        \n"// 0000000049FC: 0B0B0B0E
  "v_mul_f32     %[o_regs_94], v14, %[o_regs_94]                        \n"// 000000004A00: 0B0D0D0E
  "v_mul_f32     %[o_regs_95], v14, %[o_regs_95]                        \n"// 000000004A04: 0B0F0F0E
  "v_mul_f32     %[o_regs_96], v14, %[o_regs_96]                        \n"// 000000004A08: 0B11110E
  "v_mul_f32     %[o_regs_97], v14, %[o_regs_97]                        \n"// 000000004A0C: 0B13130E
  "v_mul_f32     %[o_regs_98], v14, %[o_regs_98]                        \n"// 000000004A10: 0B15150E
  "v_mul_f32     %[o_regs_99], v14, %[o_regs_99]                        \n"// 000000004A14: 0B17170E
  "v_mul_f32     %[o_regs_100], v14, %[o_regs_100]                        \n"// 000000004A18: 0B19190E
  "v_mul_f32     %[o_regs_101], v14, %[o_regs_101]                        \n"// 000000004A1C: 0B1B1B0E
  "v_mul_f32     %[o_regs_102], v14, %[o_regs_102]                        \n"// 000000004A20: 0B1D1D0E
  "v_mul_f32     %[o_regs_103], v14, %[o_regs_103]                        \n"// 000000004A24: 0B1F1F0E
  "v_mul_f32     %[o_regs_104], v14, %[o_regs_104]                        \n"// 000000004A28: 0B21210E
  "v_mul_f32     %[o_regs_105], v14, %[o_regs_105]                        \n"// 000000004A2C: 0B23230E
  "v_mul_f32     %[o_regs_106], v14, %[o_regs_106]                        \n"// 000000004A30: 0B25250E
  "v_mul_f32     %[o_regs_107], v14, %[o_regs_107]                        \n"// 000000004A34: 0B27270E
  "v_mul_f32     %[o_regs_108], v14, %[o_regs_108]                        \n"// 000000004A38: 0B29290E
  "v_mul_f32     %[o_regs_109], v14, %[o_regs_109]                        \n"// 000000004A3C: 0B2B2B0E
  "v_mul_f32     %[o_regs_110], v14, %[o_regs_110]                        \n"// 000000004A40: 0B2D2D0E
  "v_mul_f32     %[o_regs_111], v14, %[o_regs_111]                        \n"// 000000004A44: 0B2F2F0E
  "v_mul_f32     %[o_regs_112], v14, %[o_regs_112]                        \n"// 000000004A48: 0B31310E
  "v_mul_f32     %[o_regs_113], v14, %[o_regs_113]                        \n"// 000000004A4C: 0B33330E
  "v_mul_f32     %[o_regs_114], v14, %[o_regs_114]                        \n"// 000000004A50: 0B35350E
  "v_mul_f32     %[o_regs_115], v14, %[o_regs_115]                        \n"// 000000004A54: 0B37370E
  "v_mul_f32     %[o_regs_116], v14, %[o_regs_116]                        \n"// 000000004A58: 0B39390E
  "v_mul_f32     %[o_regs_117], v14, %[o_regs_117]                        \n"// 000000004A5C: 0B3B3B0E
  "v_mul_f32     %[o_regs_118], v14, %[o_regs_118]                        \n"// 000000004A60: 0B3D3D0E
  "v_mul_f32     %[o_regs_119], v14, %[o_regs_119]                        \n"// 000000004A64: 0B3F3F0E
  "v_mul_f32     %[o_regs_120], v14, %[o_regs_120]                        \n"// 000000004A68: 0B41410E
  "v_mul_f32     %[o_regs_121], v14, %[o_regs_121]                        \n"// 000000004A6C: 0B43430E
  "v_mul_f32     %[o_regs_122], v14, %[o_regs_122]                        \n"// 000000004A70: 0B45450E
  "v_mul_f32     %[o_regs_123], v14, %[o_regs_123]                        \n"// 000000004A74: 0B47470E
  "v_mul_f32     %[o_regs_124], v14, %[o_regs_124]                        \n"// 000000004A78: 0B49490E
  "v_mul_f32     %[o_regs_125], v14, %[o_regs_125]                        \n"// 000000004A7C: 0B4B4B0E
  "v_mul_f32     %[o_regs_126], v14, %[o_regs_126]                        \n"// 000000004A80: 0B4D4D0E
  "v_mul_f32     %[o_regs_127], v14, %[o_regs_127]                        \n"// 000000004A84: 0B4F4F0E
  "s_cmp_le_u32  %[s_kv_splits], 1                                 \n"// 000000004A88: BF0B8143
  "s_branch      label_1960                             \n"// 000000005E90: BF8201BB



  "s_cbranch_scc0  label_17A5                           \n"// 000000004A8C: BF840501
  ";s_cbranch_scc0  label_1960 \n"// 000000004A8C: BF840501


  "s_mul_i32     s75, 0x00000400, %[s_head_num_q]                   \n"// 000000004A90: 924B41FF 00000400
  "s_mul_i32     s76, %[s_kv_splits], s75                          \n"// 000000004A98: 924C4B43
  "s_add_u32     s56, s80, s79                          \n"// 000000004A9C: 80384F50
  "v_mov_b32     v20, s56                               \n"// 000000004AA0: 7E280238
  "v_mul_lo_u32  v21, s76, v20                          \n"// 000000004AA4: D2850015 0002284C
  "v_mul_hi_u32  v22, s76, v20                          \n"// 000000004AAC: D2860016 0002284C
  "s_nop         0x0002                                 \n"// 000000004AB4: BF800002
  "v_readfirstlane_b32  s56, v21                        \n"// 000000004AB8: 7E700515
  "v_readfirstlane_b32  s57, v22                        \n"// 000000004ABC: 7E720516
  "s_nop         0x0004                                 \n"// 000000004AC0: BF800004
  "s_add_u32     %[o_res_0], s56, %[o_res_0]                           \n"// 000000004AC4: 80080838
  "s_addc_u32    %[o_res_1], s57, %[o_res_1]                           \n"// 000000004AC8: 82090939
  "s_sub_u32     s56, s81, s80                          \n"// 000000004ACC: 80B85051
  "s_mul_i32     s56, s56, s76                          \n"// 000000004AD0: 92384C38
  "s_mov_b32     %[o_res_2], s56                               \n"// 000000004AD4: BE8A0038
  "v_and_b32     v20, 7, %[threadIdxx]                             \n"// 000000004AD8: 26280087
  "v_lshlrev_b32  v18, 4, v20                           \n"// 000000004ADC: 24242884
  "v_lshrrev_b32  v20, 3, %[threadIdxx]                            \n"// 000000004AE0: 20280083
  "v_mul_i32_i24  v20, 0x00000400, v20                  \n"// 000000004AE4: 0C2828FF 00000400
  "v_add_u32     v18, v18, v20                          \n"// 000000004AEC: 68242912
  "s_mul_i32     s56, %[blockIdxz], s75                           \n"// 000000004AF0: 92384B04
  "v_add_u32     v18, v18, s56                          \n"// 000000004AF4: D1340012 00007112
  "s_mul_i32     s56, %[wave_id], s76                           \n"// 000000004AFC: 92384C07
  "v_add_u32     v18, v18, s56                          \n"// 000000004B00: D1340012 00007112
  "v_mov_b32     v19, v18                               \n"// 000000004B08: 7E260312
  "s_waitcnt     vmcnt(0) & lgkmcnt(0)                  \n"// 000000004B0C: BF8C0070
  "s_barrier                                            \n"// 000000004B10: BF8A0000
  "s_mul_i32     s75, 0x00000400, %[s_head_num_q]                   \n"// 000000004B14: 924B41FF 00000400
  "s_mul_i32     s76, %[s_kv_splits], s75                          \n"// 000000004B1C: 924C4B43
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000004B20: 20280084
  "v_mul_i32_i24  v5, 0x00000048, v20                   \n"// 000000004B24: 0C0A28FF 00000048
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000004B2C: 2628008F
  "v_mul_i32_i24  v20, 2, v20                           \n"// 000000004B30: 0C282882
  "v_add_u32     v5, v20, v5                            \n"// 000000004B34: 680A0B14
  "s_mul_i32     s56, %[wave_id], 0x00000480                    \n"// 000000004B38: 9238FF07 00000480
  "v_add_u32     v5, s56, v5                            \n"// 000000004B40: 680A0A38
  "v_lshlrev_b32  v5, 2, v5                             \n"// 000000004B44: 240A0A82
  "v_lshrrev_b32  v20, 3, %[threadIdxx]                            \n"// 000000004B48: 20280083
  "v_mul_i32_i24  v4, 2, v20                            \n"// 000000004B4C: 0C082882
  "v_and_b32     v20, 7, %[threadIdxx]                             \n"// 000000004B50: 26280087
  "v_mul_i32_i24  v20, 36, v20                          \n"// 000000004B54: 0C2828A4
  "v_add_u32     v4, v20, v4                            \n"// 000000004B58: 68080914
  "s_mul_i32     s56, %[wave_id], 0x00000480                    \n"// 000000004B5C: 9238FF07 00000480
  "v_add_u32     v4, s56, v4                            \n"// 000000004B64: 68080838
  "v_lshlrev_b32  v4, 2, v4                             \n"// 000000004B68: 24080882
  "v_mov_b32     v29, 0xffff0000                        \n"// 000000004B6C: 7E3A02FF FFFF0000
  "v_mov_b32     v30, 0x7fff0000                        \n"// 000000004B74: 7E3C02FF 7FFF0000
  "v_mov_b32     v31, 0x00007fff                        \n"// 000000004B7C: 7E3E02FF 00007FFF
  "s_mul_i32     s56, 0, s76                            \n"// 000000004B84: 92384C80
  "v_add_u32     v19, v19, s56                          \n"// 000000004B88: D1340013 00007113
  "v_mov_b32     v24, %[o_regs_0]                               \n"// 000000004B90: 7E300328
  "v_mov_b32     v25, %[o_regs_4]                               \n"// 000000004B94: 7E32032C
  "v_mov_b32     v26, %[o_regs_8]                               \n"// 000000004B98: 7E340330
  "v_mov_b32     v27, %[o_regs_12]                               \n"// 000000004B9C: 7E360334
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004BA0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004BA8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004BB0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004BB8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004BC0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004BC8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004BD0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004BD8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004BE0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004BE8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004BF0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004BF8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004C00: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004C08: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25]                           \n"// 000000004C10: D89A0000 00001805
  "v_mov_b32     v24, %[o_regs_1]                               \n"// 000000004C18: 7E300329
  "v_mov_b32     v25, %[o_regs_5]                               \n"// 000000004C1C: 7E32032D
  "v_mov_b32     v26, %[o_regs_9]                               \n"// 000000004C20: 7E340331
  "v_mov_b32     v27, %[o_regs_13]                               \n"// 000000004C24: 7E360335
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004C28: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004C30: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004C38: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004C40: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004C48: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004C50: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004C58: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004C60: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004C68: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004C70: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004C78: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004C80: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004C88: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004C90: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1152               \n"// 000000004C98: D89A0480 00001805
  "v_mov_b32     v24, %[o_regs_2]                               \n"// 000000004CA0: 7E30032A
  "v_mov_b32     v25, %[o_regs_6]                               \n"// 000000004CA4: 7E32032E
  "v_mov_b32     v26, %[o_regs_10]                               \n"// 000000004CA8: 7E340332
  "v_mov_b32     v27, %[o_regs_14]                               \n"// 000000004CAC: 7E360336
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004CB0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004CB8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004CC0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004CC8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004CD0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004CD8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004CE0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004CE8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004CF0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004CF8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004D00: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004D08: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004D10: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004D18: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:144                \n"// 000000004D20: D89A0090 00001805
  "v_mov_b32     v24, %[o_regs_3]                               \n"// 000000004D28: 7E30032B
  "v_mov_b32     v25, %[o_regs_7]                               \n"// 000000004D2C: 7E32032F
  "v_mov_b32     v26, %[o_regs_11]                               \n"// 000000004D30: 7E340333
  "v_mov_b32     v27, %[o_regs_15]                               \n"// 000000004D34: 7E360337
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004D38: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004D40: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004D48: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004D50: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004D58: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004D60: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004D68: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004D70: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004D78: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004D80: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004D88: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004D90: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004D98: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004DA0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1296               \n"// 000000004DA8: D89A0510 00001805
  "v_mov_b32     v24, %[o_regs_16]                               \n"// 000000004DB0: 7E300338
  "v_mov_b32     v25, %[o_regs_20]                               \n"// 000000004DB4: 7E32033C
  "v_mov_b32     v26, %[o_regs_24]                               \n"// 000000004DB8: 7E340340
  "v_mov_b32     v27, %[o_regs_28]                               \n"// 000000004DBC: 7E360344
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004DC0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004DC8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004DD0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004DD8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004DE0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004DE8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004DF0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004DF8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004E00: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004E08: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004E10: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004E18: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004E20: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004E28: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2304               \n"// 000000004E30: D89A0900 00001805
  "v_mov_b32     v24, %[o_regs_17]                               \n"// 000000004E38: 7E300339
  "v_mov_b32     v25, %[o_regs_21]                               \n"// 000000004E3C: 7E32033D
  "v_mov_b32     v26, %[o_regs_25]                               \n"// 000000004E40: 7E340341
  "v_mov_b32     v27, %[o_regs_29]                               \n"// 000000004E44: 7E360345
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004E48: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004E50: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004E58: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004E60: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004E68: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004E70: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004E78: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004E80: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004E88: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004E90: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004E98: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004EA0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004EA8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004EB0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3456               \n"// 000000004EB8: D89A0D80 00001805
  "v_mov_b32     v24, %[o_regs_18]                               \n"// 000000004EC0: 7E30033A
  "v_mov_b32     v25, %[o_regs_22]                               \n"// 000000004EC4: 7E32033E
  "v_mov_b32     v26, %[o_regs_26]                               \n"// 000000004EC8: 7E340342
  "v_mov_b32     v27, %[o_regs_30]                               \n"// 000000004ECC: 7E360346
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004ED0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004ED8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004EE0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004EE8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004EF0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004EF8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004F00: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004F08: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004F10: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004F18: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004F20: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004F28: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004F30: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004F38: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2448               \n"// 000000004F40: D89A0990 00001805
  "v_mov_b32     v24, %[o_regs_19]                               \n"// 000000004F48: 7E30033B
  "v_mov_b32     v25, %[o_regs_23]                               \n"// 000000004F4C: 7E32033F
  "v_mov_b32     v26, %[o_regs_27]                               \n"// 000000004F50: 7E340343
  "v_mov_b32     v27, %[o_regs_31]                               \n"// 000000004F54: 7E360347
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000004F58: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000004F60: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004F68: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000004F70: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000004F78: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004F80: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000004F88: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000004F90: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000004F98: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000004FA0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000004FA8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000004FB0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000004FB8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000004FC0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3600               \n"// 000000004FC8: D89A0E10 00001805
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000004FD0: BF8CC47F
  "ds_read_b64   [%[o_regs_0], %[o_regs_1]], v4                           \n"// 000000004FD4: D8EC0000 28000004
  "ds_read_b64   [%[o_regs_4], %[o_regs_5]], v4 offset:64                 \n"// 000000004FDC: D8EC0040 2C000004
  "ds_read_b64   [%[o_regs_2], %[o_regs_3]], v4 offset:1152               \n"// 000000004FE4: D8EC0480 2A000004
  "ds_read_b64   [%[o_regs_6], %[o_regs_7]], v4 offset:1216               \n"// 000000004FEC: D8EC04C0 2E000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000004FF4: BF8CC47F
  "ds_read_b64   [%[o_regs_8], %[o_regs_9]], v4 offset:2304               \n"// 000000004FF8: D8EC0900 30000004
  "ds_read_b64   [%[o_regs_12], %[o_regs_13]], v4 offset:2368               \n"// 000000005000: D8EC0940 34000004
  "ds_read_b64   [%[o_regs_10], %[o_regs_11]], v4 offset:3456               \n"// 000000005008: D8EC0D80 32000004
  "ds_read_b64   [%[o_regs_14], %[o_regs_15]], v4 offset:3520               \n"// 000000005010: D8EC0DC0 36000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000005018: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 00000000501C: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 000000005020: E07C1000 80022812
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:128\n"// 000000005028: E07C1080 80023012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000005030: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 000000005038: E07C1000 80022C12
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:128\n"// 000000005040: E07C1080 80023412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000005048: 682424FF 00002000
  "v_mov_b32     v24, %[o_regs_32]                               \n"// 000000005050: 7E300348
  "v_mov_b32     v25, %[o_regs_36]                               \n"// 000000005054: 7E32034C
  "v_mov_b32     v26, %[o_regs_40]                               \n"// 000000005058: 7E340350
  "v_mov_b32     v27, %[o_regs_44]                               \n"// 00000000505C: 7E360354
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005060: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005068: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005070: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005078: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005080: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005088: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005090: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005098: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000050A0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000050A8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000050B0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 0000000050B8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000050C0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000050C8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25]                           \n"// 0000000050D0: D89A0000 00001805
  "v_mov_b32     v24, %[o_regs_33]                               \n"// 0000000050D8: 7E300349
  "v_mov_b32     v25, %[o_regs_37]                               \n"// 0000000050DC: 7E32034D
  "v_mov_b32     v26, %[o_regs_41]                               \n"// 0000000050E0: 7E340351
  "v_mov_b32     v27, %[o_regs_45]                               \n"// 0000000050E4: 7E360355
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000050E8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000050F0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000050F8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005100: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005108: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005110: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005118: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005120: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005128: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005130: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005138: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005140: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005148: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005150: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1152               \n"// 000000005158: D89A0480 00001805
  "v_mov_b32     v24, %[o_regs_34]                               \n"// 000000005160: 7E30034A
  "v_mov_b32     v25, %[o_regs_38]                               \n"// 000000005164: 7E32034E
  "v_mov_b32     v26, %[o_regs_42]                               \n"// 000000005168: 7E340352
  "v_mov_b32     v27, %[o_regs_46]                               \n"// 00000000516C: 7E360356
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005170: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005178: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005180: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005188: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005190: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005198: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000051A0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 0000000051A8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000051B0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000051B8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000051C0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 0000000051C8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000051D0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000051D8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:144                \n"// 0000000051E0: D89A0090 00001805
  "v_mov_b32     v24, %[o_regs_35]                               \n"// 0000000051E8: 7E30034B
  "v_mov_b32     v25, %[o_regs_39]                               \n"// 0000000051EC: 7E32034F
  "v_mov_b32     v26, %[o_regs_43]                               \n"// 0000000051F0: 7E340353
  "v_mov_b32     v27, %[o_regs_47]                               \n"// 0000000051F4: 7E360357
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000051F8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005200: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005208: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005210: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005218: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005220: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005228: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005230: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005238: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005240: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005248: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005250: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005258: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005260: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1296               \n"// 000000005268: D89A0510 00001805
  "v_mov_b32     v24, %[o_regs_48]                               \n"// 000000005270: 7E300358
  "v_mov_b32     v25, %[o_regs_52]                               \n"// 000000005274: 7E32035C
  "v_mov_b32     v26, %[o_regs_56]                               \n"// 000000005278: 7E340360
  "v_mov_b32     v27, %[o_regs_60]                              \n"// 00000000527C: 7E360364
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005280: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005288: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005290: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005298: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000052A0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000052A8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000052B0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 0000000052B8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000052C0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000052C8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000052D0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 0000000052D8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000052E0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000052E8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2304               \n"// 0000000052F0: D89A0900 00001805
  "v_mov_b32     v24, %[o_regs_49]                               \n"// 0000000052F8: 7E300359
  "v_mov_b32     v25, %[o_regs_53]                               \n"// 0000000052FC: 7E32035D
  "v_mov_b32     v26, %[o_regs_57]                               \n"// 000000005300: 7E340361
  "v_mov_b32     v27, %[o_regs_61]                              \n"// 000000005304: 7E360365
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005308: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005310: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005318: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005320: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005328: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005330: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005338: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005340: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005348: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005350: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005358: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005360: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005368: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005370: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3456               \n"// 000000005378: D89A0D80 00001805
  "v_mov_b32     v24, %[o_regs_50]                               \n"// 000000005380: 7E30035A
  "v_mov_b32     v25, %[o_regs_54]                               \n"// 000000005384: 7E32035E
  "v_mov_b32     v26, %[o_regs_58]                               \n"// 000000005388: 7E340362
  "v_mov_b32     v27, %[o_regs_62]                              \n"// 00000000538C: 7E360366
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005390: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005398: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000053A0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000053A8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000053B0: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000053B8: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000053C0: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 0000000053C8: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000053D0: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000053D8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000053E0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 0000000053E8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000053F0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000053F8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2448               \n"// 000000005400: D89A0990 00001805
  "v_mov_b32     v24, %[o_regs_51]                               \n"// 000000005408: 7E30035B
  "v_mov_b32     v25, %[o_regs_55]                               \n"// 00000000540C: 7E32035F
  "v_mov_b32     v26, %[o_regs_59]                               \n"// 000000005410: 7E340363
  "v_mov_b32     v27, %[o_regs_63]                              \n"// 000000005414: 7E360367
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005418: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005420: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005428: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005430: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005438: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005440: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005448: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005450: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005458: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005460: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005468: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005470: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005478: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005480: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3600               \n"// 000000005488: D89A0E10 00001805
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000005490: BF8CC47F
  "ds_read_b64   [%[o_regs_0], %[o_regs_1]], v4                           \n"// 000000005494: D8EC0000 28000004
  "ds_read_b64   [%[o_regs_4], %[o_regs_5]], v4 offset:64                 \n"// 00000000549C: D8EC0040 2C000004
  "ds_read_b64   [%[o_regs_2], %[o_regs_3]], v4 offset:1152               \n"// 0000000054A4: D8EC0480 2A000004
  "ds_read_b64   [%[o_regs_6], %[o_regs_7]], v4 offset:1216               \n"// 0000000054AC: D8EC04C0 2E000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000054B4: BF8CC47F
  "ds_read_b64   [%[o_regs_8], %[o_regs_9]], v4 offset:2304               \n"// 0000000054B8: D8EC0900 30000004
  "ds_read_b64   [%[o_regs_12], %[o_regs_13]], v4 offset:2368               \n"// 0000000054C0: D8EC0940 34000004
  "ds_read_b64   [%[o_regs_10], %[o_regs_11]], v4 offset:3456               \n"// 0000000054C8: D8EC0D80 32000004
  "ds_read_b64   [%[o_regs_14], %[o_regs_15]], v4 offset:3520               \n"// 0000000054D0: D8EC0DC0 36000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000054D8: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 0000000054DC: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 0000000054E0: E07C1100 80022812
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:384\n"// 0000000054E8: E07C1180 80023012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000054F0: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 0000000054F8: E07C1100 80022C12
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:384\n"// 000000005500: E07C1180 80023412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000005508: 682424FF 00002000
  "v_mov_b32     v24, %[o_regs_64]                              \n"// 000000005510: 7E300368
  "v_mov_b32     v25, %[o_regs_68]                              \n"// 000000005514: 7E32036C
  "v_mov_b32     v26, %[o_regs_72]                              \n"// 000000005518: 7E340370
  "v_mov_b32     v27, %[o_regs_76]                              \n"// 00000000551C: 7E360374
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005520: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005528: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005530: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005538: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005540: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005548: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005550: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005558: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005560: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005568: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005570: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005578: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005580: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005588: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25]                           \n"// 000000005590: D89A0000 00001805
  "v_mov_b32     v24, %[o_regs_65]                              \n"// 000000005598: 7E300369
  "v_mov_b32     v25, %[o_regs_69]                              \n"// 00000000559C: 7E32036D
  "v_mov_b32     v26, %[o_regs_73]                              \n"// 0000000055A0: 7E340371
  "v_mov_b32     v27, %[o_regs_77]                              \n"// 0000000055A4: 7E360375
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000055A8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000055B0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000055B8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000055C0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000055C8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000055D0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000055D8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 0000000055E0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000055E8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000055F0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000055F8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005600: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005608: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005610: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1152               \n"// 000000005618: D89A0480 00001805
  "v_mov_b32     v24, %[o_regs_66]                              \n"// 000000005620: 7E30036A
  "v_mov_b32     v25, %[o_regs_70]                              \n"// 000000005624: 7E32036E
  "v_mov_b32     v26, %[o_regs_74]                              \n"// 000000005628: 7E340372
  "v_mov_b32     v27, %[o_regs_78]                              \n"// 00000000562C: 7E360376
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005630: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005638: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005640: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005648: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005650: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005658: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005660: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005668: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005670: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005678: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005680: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005688: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005690: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005698: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:144                \n"// 0000000056A0: D89A0090 00001805
  "v_mov_b32     v24, %[o_regs_67]                              \n"// 0000000056A8: 7E30036B
  "v_mov_b32     v25, %[o_regs_71]                              \n"// 0000000056AC: 7E32036F
  "v_mov_b32     v26, %[o_regs_75]                              \n"// 0000000056B0: 7E340373
  "v_mov_b32     v27, %[o_regs_79]                              \n"// 0000000056B4: 7E360377
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000056B8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000056C0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000056C8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000056D0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000056D8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000056E0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000056E8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 0000000056F0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 0000000056F8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005700: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005708: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005710: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005718: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005720: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1296               \n"// 000000005728: D89A0510 00001805
  "v_mov_b32     v24, %[o_regs_80]                              \n"// 000000005730: 7E300378
  "v_mov_b32     v25, %[o_regs_84]                              \n"// 000000005734: 7E32037C
  "v_mov_b32     v26, %[o_regs_88]                              \n"// 000000005738: 7E340380
  "v_mov_b32     v27, %[o_regs_92]                              \n"// 00000000573C: 7E360384
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005740: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005748: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005750: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005758: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005760: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005768: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005770: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005778: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005780: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005788: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005790: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005798: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000057A0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000057A8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2304               \n"// 0000000057B0: D89A0900 00001805
  "v_mov_b32     v24, %[o_regs_81]                              \n"// 0000000057B8: 7E300379
  "v_mov_b32     v25, %[o_regs_85]                              \n"// 0000000057BC: 7E32037D
  "v_mov_b32     v26, %[o_regs_89]                              \n"// 0000000057C0: 7E340381
  "v_mov_b32     v27, %[o_regs_93]                              \n"// 0000000057C4: 7E360385
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000057C8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000057D0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000057D8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000057E0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000057E8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000057F0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 0000000057F8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005800: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005808: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005810: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005818: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005820: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005828: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005830: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3456               \n"// 000000005838: D89A0D80 00001805
  "v_mov_b32     v24, %[o_regs_82]                              \n"// 000000005840: 7E30037A
  "v_mov_b32     v25, %[o_regs_86]                              \n"// 000000005844: 7E32037E
  "v_mov_b32     v26, %[o_regs_90]                              \n"// 000000005848: 7E340382
  "v_mov_b32     v27, %[o_regs_94]                              \n"// 00000000584C: 7E360386
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005850: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005858: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005860: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005868: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005870: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005878: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005880: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005888: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005890: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005898: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 0000000058A0: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 0000000058A8: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 0000000058B0: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 0000000058B8: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2448               \n"// 0000000058C0: D89A0990 00001805
  "v_mov_b32     v24, %[o_regs_83]                              \n"// 0000000058C8: 7E30037B
  "v_mov_b32     v25, %[o_regs_87]                              \n"// 0000000058CC: 7E32037F
  "v_mov_b32     v26, %[o_regs_91]                              \n"// 0000000058D0: 7E340383
  "v_mov_b32     v27, %[o_regs_95]                              \n"// 0000000058D4: 7E360387
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000058D8: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000058E0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000058E8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000058F0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 0000000058F8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005900: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005908: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005910: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005918: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005920: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005928: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005930: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005938: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005940: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3600               \n"// 000000005948: D89A0E10 00001805
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000005950: BF8CC47F
  "ds_read_b64   [%[o_regs_0], %[o_regs_1]], v4                           \n"// 000000005954: D8EC0000 28000004
  "ds_read_b64   [%[o_regs_4], %[o_regs_5]], v4 offset:64                 \n"// 00000000595C: D8EC0040 2C000004
  "ds_read_b64   [%[o_regs_2], %[o_regs_3]], v4 offset:1152               \n"// 000000005964: D8EC0480 2A000004
  "ds_read_b64   [%[o_regs_6], %[o_regs_7]], v4 offset:1216               \n"// 00000000596C: D8EC04C0 2E000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000005974: BF8CC47F
  "ds_read_b64   [%[o_regs_8], %[o_regs_9]], v4 offset:2304               \n"// 000000005978: D8EC0900 30000004
  "ds_read_b64   [%[o_regs_12], %[o_regs_13]], v4 offset:2368               \n"// 000000005980: D8EC0940 34000004
  "ds_read_b64   [%[o_regs_10], %[o_regs_11]], v4 offset:3456               \n"// 000000005988: D8EC0D80 32000004
  "ds_read_b64   [%[o_regs_14], %[o_regs_15]], v4 offset:3520               \n"// 000000005990: D8EC0DC0 36000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000005998: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 00000000599C: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 0000000059A0: E07C1200 80022812
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:640\n"// 0000000059A8: E07C1280 80023012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000059B0: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 0000000059B8: E07C1200 80022C12
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:640\n"// 0000000059C0: E07C1280 80023412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000059C8: 682424FF 00002000
  "v_mov_b32     v24, %[o_regs_96]                              \n"// 0000000059D0: 7E300388
  "v_mov_b32     v25, %[o_regs_100]                              \n"// 0000000059D4: 7E32038C
  "v_mov_b32     v26, %[o_regs_104]                              \n"// 0000000059D8: 7E340390
  "v_mov_b32     v27, %[o_regs_108]                              \n"// 0000000059DC: 7E360394
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 0000000059E0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 0000000059E8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 0000000059F0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 0000000059F8: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005A00: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005A08: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005A10: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005A18: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005A20: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005A28: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005A30: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005A38: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005A40: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005A48: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25]                           \n"// 000000005A50: D89A0000 00001805
  "v_mov_b32     v24, %[o_regs_97]                              \n"// 000000005A58: 7E300389
  "v_mov_b32     v25, %[o_regs_101]                              \n"// 000000005A5C: 7E32038D
  "v_mov_b32     v26, %[o_regs_105]                              \n"// 000000005A60: 7E340391
  "v_mov_b32     v27, %[o_regs_109]                              \n"// 000000005A64: 7E360395
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005A68: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005A70: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005A78: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005A80: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005A88: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005A90: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005A98: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005AA0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005AA8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005AB0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005AB8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005AC0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005AC8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005AD0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1152               \n"// 000000005AD8: D89A0480 00001805
  "v_mov_b32     v24, %[o_regs_98]                              \n"// 000000005AE0: 7E30038A
  "v_mov_b32     v25, %[o_regs_102]                              \n"// 000000005AE4: 7E32038E
  "v_mov_b32     v26, %[o_regs_106]                              \n"// 000000005AE8: 7E340392
  "v_mov_b32     v27, %[o_regs_110]                              \n"// 000000005AEC: 7E360396
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005AF0: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005AF8: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005B00: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005B08: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005B10: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005B18: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005B20: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005B28: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005B30: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005B38: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005B40: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005B48: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005B50: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005B58: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:144                \n"// 000000005B60: D89A0090 00001805
  "v_mov_b32     v24, %[o_regs_99]                              \n"// 000000005B68: 7E30038B
  "v_mov_b32     v25, %[o_regs_103]                              \n"// 000000005B6C: 7E32038F
  "v_mov_b32     v26, %[o_regs_107]                              \n"// 000000005B70: 7E340393
  "v_mov_b32     v27, %[o_regs_111]                              \n"// 000000005B74: 7E360397
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005B78: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005B80: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005B88: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005B90: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005B98: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005BA0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005BA8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005BB0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005BB8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005BC0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005BC8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005BD0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005BD8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005BE0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:1296               \n"// 000000005BE8: D89A0510 00001805
  "v_mov_b32     v24, %[o_regs_112]                              \n"// 000000005BF0: 7E300398
  "v_mov_b32     v25, %[o_regs_116]                              \n"// 000000005BF4: 7E32039C
  "v_mov_b32     v26, %[o_regs_120]                              \n"// 000000005BF8: 7E3403A0
  "v_mov_b32     v27, %[o_regs_124]                              \n"// 000000005BFC: 7E3603A4
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005C00: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005C08: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005C10: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005C18: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005C20: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005C28: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005C30: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005C38: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005C40: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005C48: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005C50: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005C58: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005C60: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005C68: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2304               \n"// 000000005C70: D89A0900 00001805
  "v_mov_b32     v24, %[o_regs_113]                              \n"// 000000005C78: 7E300399
  "v_mov_b32     v25, %[o_regs_117]                              \n"// 000000005C7C: 7E32039D
  "v_mov_b32     v26, %[o_regs_121]                              \n"// 000000005C80: 7E3403A1
  "v_mov_b32     v27, %[o_regs_125]                              \n"// 000000005C84: 7E3603A5
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005C88: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005C90: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005C98: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005CA0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005CA8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005CB0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005CB8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005CC0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005CC8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005CD0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005CD8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005CE0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005CE8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005CF0: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3456               \n"// 000000005CF8: D89A0D80 00001805
  "v_mov_b32     v24, %[o_regs_114]                              \n"// 000000005D00: 7E30039A
  "v_mov_b32     v25, %[o_regs_118]                              \n"// 000000005D04: 7E32039E
  "v_mov_b32     v26, %[o_regs_122]                              \n"// 000000005D08: 7E3403A2
  "v_mov_b32     v27, %[o_regs_126]                              \n"// 000000005D0C: 7E3603A6
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005D10: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005D18: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005D20: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005D28: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005D30: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005D38: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005D40: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005D48: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005D50: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005D58: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005D60: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005D68: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005D70: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005D78: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:2448               \n"// 000000005D80: D89A0990 00001805
  "v_mov_b32     v24, %[o_regs_115]                              \n"// 000000005D88: 7E30039B
  "v_mov_b32     v25, %[o_regs_119]                              \n"// 000000005D8C: 7E32039F
  "v_mov_b32     v26, %[o_regs_123]                              \n"// 000000005D90: 7E3403A3
  "v_mov_b32     v27, %[o_regs_127]                              \n"// 000000005D94: 7E3603A7
  "v_cmp_u_f32   s[38:39], v24, v24                     \n"// 000000005D98: D0480026 00023118
  "v_add3_u32    v28, v24, v31, 1                       \n"// 000000005DA0: D1FF001C 02063F18
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005DA8: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v25, v25                     \n"// 000000005DB0: D0480026 00023319
  "v_add3_u32    v28, v25, v31, 1                       \n"// 000000005DB8: D1FF001C 02063F19
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005DC0: D1000015 009A3D1C
  "v_perm_b32    v24, v21, v20, s52                     \n"// 000000005DC8: D1ED0018 00D22915
  "v_cmp_u_f32   s[38:39], v26, v26                     \n"// 000000005DD0: D0480026 0002351A
  "v_add3_u32    v28, v26, v31, 1                       \n"// 000000005DD8: D1FF001C 02063F1A
  "v_cndmask_b32  v20, v28, v30, s[38:39]               \n"// 000000005DE0: D1000014 009A3D1C
  "v_cmp_u_f32   s[38:39], v27, v27                     \n"// 000000005DE8: D0480026 0002371B
  "v_add3_u32    v28, v27, v31, 1                       \n"// 000000005DF0: D1FF001C 02063F1B
  "v_cndmask_b32  v21, v28, v30, s[38:39]               \n"// 000000005DF8: D1000015 009A3D1C
  "v_perm_b32    v25, v21, v20, s52                     \n"// 000000005E00: D1ED0019 00D22915
  "ds_write_b64  v5, v[24:25] offset:3600               \n"// 000000005E08: D89A0E10 00001805
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000005E10: BF8CC47F
  "ds_read_b64   [%[o_regs_0], %[o_regs_1]], v4                           \n"// 000000005E14: D8EC0000 28000004
  "ds_read_b64   [%[o_regs_4], %[o_regs_5]], v4 offset:64                 \n"// 000000005E1C: D8EC0040 2C000004
  "ds_read_b64   [%[o_regs_2], %[o_regs_3]], v4 offset:1152               \n"// 000000005E24: D8EC0480 2A000004
  "ds_read_b64   [%[o_regs_6], %[o_regs_7]], v4 offset:1216               \n"// 000000005E2C: D8EC04C0 2E000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000005E34: BF8CC47F
  "ds_read_b64   [%[o_regs_8], %[o_regs_9]], v4 offset:2304               \n"// 000000005E38: D8EC0900 30000004
  "ds_read_b64   [%[o_regs_12], %[o_regs_13]], v4 offset:2368               \n"// 000000005E40: D8EC0940 34000004
  "ds_read_b64   [%[o_regs_10], %[o_regs_11]], v4 offset:3456               \n"// 000000005E48: D8EC0D80 32000004
  "ds_read_b64   [%[o_regs_14], %[o_regs_15]], v4 offset:3520               \n"// 000000005E50: D8EC0DC0 36000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000005E58: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 000000005E5C: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 000000005E60: E07C1300 80022812
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:896\n"// 000000005E68: E07C1380 80023012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000005E70: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 000000005E78: E07C1300 80022C12
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:896\n"// 000000005E80: E07C1380 80023412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000005E88: 682424FF 00002000
  "s_branch      label_1960                             \n"// 000000005E90: BF8201BB
"label_17A5: \n"
  "s_mul_i32     s76, %[s_kv_splits], s75                          \n"// 000000005E94: 924C4B43
  "s_add_u32     s56, s80, s79                          \n"// 000000005E98: 80384F50
  "v_mov_b32     v20, s56                               \n"// 000000005E9C: 7E280238
  "v_mul_lo_u32  v21, s76, v20                          \n"// 000000005EA0: D2850015 0002284C
  "v_mul_hi_u32  v22, s76, v20                          \n"// 000000005EA8: D2860016 0002284C
  "s_nop         0x0002                                 \n"// 000000005EB0: BF800002
  "v_readfirstlane_b32  s56, v21                        \n"// 000000005EB4: 7E700515
  "v_readfirstlane_b32  s57, v22                        \n"// 000000005EB8: 7E720516
  "s_nop         0x0004                                 \n"// 000000005EBC: BF800004
  "s_add_u32     %[o_res_0], s56, %[o_res_0]                           \n"// 000000005EC0: 80080838
  "s_addc_u32    %[o_res_1], s57, %[o_res_1]                           \n"// 000000005EC4: 82090939
  "s_sub_u32     s56, s81, s80                          \n"// 000000005EC8: 80B85051
  "s_mul_i32     s56, s56, s76                          \n"// 000000005ECC: 92384C38
  "s_mov_b32     %[o_res_2], s56                               \n"// 000000005ED0: BE8A0038
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000005ED4: 2628008F
  "v_lshlrev_b32  v18, 4, v20                           \n"// 000000005ED8: 24242884
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000005EDC: 20280084
  "v_mul_i32_i24  v20, 0x00000800, v20                  \n"// 000000005EE0: 0C2828FF 00000800
  "v_add_u32     v18, v18, v20                          \n"// 000000005EE8: 68242912
  "s_mul_i32     s56, %[blockIdxz], s75                           \n"// 000000005EEC: 92384B04
  "v_add_u32     v18, v18, s56                          \n"// 000000005EF0: D1340012 00007112
  "s_mul_i32     s56, %[wave_id], s76                           \n"// 000000005EF8: 92384C07
  "v_add_u32     v18, v18, s56                          \n"// 000000005EFC: D1340012 00007112
  "v_mov_b32     v19, v18                               \n"// 000000005F04: 7E260312
  "s_mul_i32     s58, 4, %[s_head_num_q]                            \n"// 000000005F08: 923A4184
  "s_mul_i32     s77, %[s_kv_splits], s58                          \n"// 000000005F0C: 924D3A43
  "s_add_u32     s56, s80, s79                          \n"// 000000005F10: 80384F50
  "s_mul_i32     s56, s56, s77                          \n"// 000000005F14: 92384D38
  "s_add_u32     %[lse_res_0], s56, %[lse_res_0]                         \n"// 000000005F18: 800C0C38
  "s_addc_u32    %[lse_res_1], 0, %[lse_res_1]                           \n"// 000000005F1C: 820D0D80
  "s_sub_u32     s56, s81, s80                          \n"// 000000005F20: 80B85051
  "s_mul_i32     s56, s56, s77                          \n"// 000000005F24: 92384D38
  "s_mov_b32     %[lse_res_2], s56                               \n"// 000000005F28: BE8E0038
  "v_and_b32     v26, 15, %[threadIdxx]                            \n"// 000000005F2C: 2634008F
  "v_lshlrev_b32  v26, 2, v26                           \n"// 000000005F30: 24343482
  "s_mul_i32     s56, %[blockIdxz], s58                           \n"// 000000005F34: 92383A04
  "v_add_u32     v26, v26, s56                          \n"// 000000005F38: D134001A 0000711A
  "s_mul_i32     s56, %[wave_id], s77                           \n"// 000000005F40: 92384D07
  "v_add_u32     v26, v26, s56                          \n"// 000000005F44: D134001A 0000711A

  "s_waitcnt     vmcnt(0) & lgkmcnt(0)                  \n"// 000000005F4C: BF8C0070
  "s_barrier                                            \n"// 000000005F50: BF8A0000
  "v_lshlrev_b32  v5, 2, %[threadIdxx]                             \n"// 000000005F54: 240A0082
  "s_mul_i32     s56, %[wave_id], 0x00000840                    \n"// 000000005F58: 9238FF07 00000840
  "v_add_u32     v5, s56, v5                            \n"// 000000005F60: 680A0A38
  "v_lshlrev_b32  v5, 2, v5                             \n"// 000000005F64: 240A0A82
  "v_lshrrev_b32  v20, 4, %[threadIdxx]                            \n"// 000000005F68: 20280084
  "v_mul_i32_i24  v4, 4, v20                            \n"// 000000005F6C: 0C082884
  "v_and_b32     v20, 3, %[threadIdxx]                             \n"// 000000005F70: 26280083
  "v_mul_i32_i24  v20, 0x00000108, v20                  \n"// 000000005F74: 0C2828FF 00000108
  "v_add_u32     v4, v20, v4                            \n"// 000000005F7C: 68080914
  "v_and_b32     v20, 15, %[threadIdxx]                            \n"// 000000005F80: 2628008F
  "v_lshrrev_b32  v20, 2, v20                           \n"// 000000005F84: 20282882
  "v_mul_i32_i24  v20, 64, v20                          \n"// 000000005F88: 0C2828C0
  "v_add_u32     v4, v20, v4                            \n"// 000000005F8C: 68080914
  "s_mul_i32     s56, %[wave_id], 0x00000840                    \n"// 000000005F90: 9238FF07 00000840
  "v_add_u32     v4, s56, v4                            \n"// 000000005F98: 68080838
  "v_lshlrev_b32  v4, 2, v4                             \n"// 000000005F9C: 24080882
  "s_mul_i32     s56, 0, s76                            \n"// 000000005FA0: 92384C80
  "v_add_u32     v19, v19, s56                          \n"// 000000005FA4: D1340013 00007113
  "v_mov_b32     v20, %[o_regs_0]                               \n"// 000000005FAC: 7E280328
  "v_mov_b32     v21, %[o_regs_4]                               \n"// 000000005FB0: 7E2A032C
  "v_mov_b32     v22, %[o_regs_8]                               \n"// 000000005FB4: 7E2C0330
  "v_mov_b32     v23, %[o_regs_12]                               \n"// 000000005FB8: 7E2E0334
  "ds_write_b128  v5, v[20:23]                          \n"// 000000005FBC: D9BE0000 00001405
  "v_mov_b32     v20, %[o_regs_1]                               \n"// 000000005FC4: 7E280329
  "v_mov_b32     v21, %[o_regs_5]                               \n"// 000000005FC8: 7E2A032D
  "v_mov_b32     v22, %[o_regs_9]                               \n"// 000000005FCC: 7E2C0331
  "v_mov_b32     v23, %[o_regs_13]                               \n"// 000000005FD0: 7E2E0335
  "ds_write_b128  v5, v[20:23] offset:1056              \n"// 000000005FD4: D9BE0420 00001405
  "v_mov_b32     v20, %[o_regs_2]                               \n"// 000000005FDC: 7E28032A
  "v_mov_b32     v21, %[o_regs_6]                               \n"// 000000005FE0: 7E2A032E
  "v_mov_b32     v22, %[o_regs_10]                               \n"// 000000005FE4: 7E2C0332
  "v_mov_b32     v23, %[o_regs_14]                               \n"// 000000005FE8: 7E2E0336
  "ds_write_b128  v5, v[20:23] offset:2112              \n"// 000000005FEC: D9BE0840 00001405
  "v_mov_b32     v20, %[o_regs_3]                               \n"// 000000005FF4: 7E28032B
  "v_mov_b32     v21, %[o_regs_7]                               \n"// 000000005FF8: 7E2A032F
  "v_mov_b32     v22, %[o_regs_11]                               \n"// 000000005FFC: 7E2C0333
  "v_mov_b32     v23, %[o_regs_15]                               \n"// 000000006000: 7E2E0337
  "ds_write_b128  v5, v[20:23] offset:3168              \n"// 000000006004: D9BE0C60 00001405
  "v_mov_b32     v20, %[o_regs_16]                               \n"// 00000000600C: 7E280338
  "v_mov_b32     v21, %[o_regs_20]                               \n"// 000000006010: 7E2A033C
  "v_mov_b32     v22, %[o_regs_24]                               \n"// 000000006014: 7E2C0340
  "v_mov_b32     v23, %[o_regs_28]                               \n"// 000000006018: 7E2E0344
  "ds_write_b128  v5, v[20:23] offset:4224              \n"// 00000000601C: D9BE1080 00001405
  "v_mov_b32     v20, %[o_regs_17]                               \n"// 000000006024: 7E280339
  "v_mov_b32     v21, %[o_regs_21]                               \n"// 000000006028: 7E2A033D
  "v_mov_b32     v22, %[o_regs_25]                               \n"// 00000000602C: 7E2C0341
  "v_mov_b32     v23, %[o_regs_29]                               \n"// 000000006030: 7E2E0345
  "ds_write_b128  v5, v[20:23] offset:5280              \n"// 000000006034: D9BE14A0 00001405
  "v_mov_b32     v20, %[o_regs_18]                               \n"// 00000000603C: 7E28033A
  "v_mov_b32     v21, %[o_regs_22]                               \n"// 000000006040: 7E2A033E
  "v_mov_b32     v22, %[o_regs_26]                               \n"// 000000006044: 7E2C0342
  "v_mov_b32     v23, %[o_regs_30]                               \n"// 000000006048: 7E2E0346
  "ds_write_b128  v5, v[20:23] offset:6336              \n"// 00000000604C: D9BE18C0 00001405
  "v_mov_b32     v20, %[o_regs_19]                               \n"// 000000006054: 7E28033B
  "v_mov_b32     v21, %[o_regs_23]                               \n"// 000000006058: 7E2A033F
  "v_mov_b32     v22, %[o_regs_27]                               \n"// 00000000605C: 7E2C0343
  "v_mov_b32     v23, %[o_regs_31]                               \n"// 000000006060: 7E2E0347
  "ds_write_b128  v5, v[20:23] offset:7392              \n"// 000000006064: D9BE1CE0 00001405
  "s_waitcnt     lgkmcnt(4)                             \n"// 00000000606C: BF8CC47F
  "ds_read_b128  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v4                           \n"// 000000006070: D9FE0000 28000004
  "ds_read_b128  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v4 offset:64                 \n"// 000000006078: D9FE0040 2C000004
  "ds_read_b128  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v4 offset:128                \n"// 000000006080: D9FE0080 30000004
  "ds_read_b128  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v4 offset:192                \n"// 000000006088: D9FE00C0 34000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000006090: BF8CC47F
  "ds_read_b128  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v4 offset:4224               \n"// 000000006094: D9FE1080 38000004
  "ds_read_b128  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v4 offset:4288               \n"// 00000000609C: D9FE10C0 3C000004
  "ds_read_b128  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v4 offset:4352               \n"// 0000000060A4: D9FE1100 40000004
  "ds_read_b128  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v4 offset:4416               \n"// 0000000060AC: D9FE1140 44000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 0000000060B4: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 0000000060B8: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 0000000060BC: E07C1000 80022812
  "buffer_store_dwordx4  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 0000000060C4: E07C1100 80023812
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000060CC: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 0000000060D4: E07C1000 80022C12
  "buffer_store_dwordx4  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 0000000060DC: E07C1100 80023C12
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000060E4: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 0000000060EC: E07C1000 80023012
  "buffer_store_dwordx4  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 0000000060F4: E07C1100 80024012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000060FC: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen\n"// 000000006104: E07C1000 80023412
  "buffer_store_dwordx4  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:256\n"// 00000000610C: E07C1100 80024412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000006114: 682424FF 00002000
  "v_mov_b32     v20, %[o_regs_32]                               \n"// 00000000611C: 7E280348
  "v_mov_b32     v21, %[o_regs_36]                               \n"// 000000006120: 7E2A034C
  "v_mov_b32     v22, %[o_regs_40]                               \n"// 000000006124: 7E2C0350
  "v_mov_b32     v23, %[o_regs_44]                               \n"// 000000006128: 7E2E0354
  "ds_write_b128  v5, v[20:23]                          \n"// 00000000612C: D9BE0000 00001405
  "v_mov_b32     v20, %[o_regs_33]                               \n"// 000000006134: 7E280349
  "v_mov_b32     v21, %[o_regs_37]                               \n"// 000000006138: 7E2A034D
  "v_mov_b32     v22, %[o_regs_41]                               \n"// 00000000613C: 7E2C0351
  "v_mov_b32     v23, %[o_regs_45]                               \n"// 000000006140: 7E2E0355
  "ds_write_b128  v5, v[20:23] offset:1056              \n"// 000000006144: D9BE0420 00001405
  "v_mov_b32     v20, %[o_regs_34]                               \n"// 00000000614C: 7E28034A
  "v_mov_b32     v21, %[o_regs_38]                               \n"// 000000006150: 7E2A034E
  "v_mov_b32     v22, %[o_regs_42]                               \n"// 000000006154: 7E2C0352
  "v_mov_b32     v23, %[o_regs_46]                               \n"// 000000006158: 7E2E0356
  "ds_write_b128  v5, v[20:23] offset:2112              \n"// 00000000615C: D9BE0840 00001405
  "v_mov_b32     v20, %[o_regs_35]                               \n"// 000000006164: 7E28034B
  "v_mov_b32     v21, %[o_regs_39]                               \n"// 000000006168: 7E2A034F
  "v_mov_b32     v22, %[o_regs_43]                               \n"// 00000000616C: 7E2C0353
  "v_mov_b32     v23, %[o_regs_47]                               \n"// 000000006170: 7E2E0357
  "ds_write_b128  v5, v[20:23] offset:3168              \n"// 000000006174: D9BE0C60 00001405
  "v_mov_b32     v20, %[o_regs_48]                               \n"// 00000000617C: 7E280358
  "v_mov_b32     v21, %[o_regs_52]                               \n"// 000000006180: 7E2A035C
  "v_mov_b32     v22, %[o_regs_56]                               \n"// 000000006184: 7E2C0360
  "v_mov_b32     v23, %[o_regs_60]                              \n"// 000000006188: 7E2E0364
  "ds_write_b128  v5, v[20:23] offset:4224              \n"// 00000000618C: D9BE1080 00001405
  "v_mov_b32     v20, %[o_regs_49]                               \n"// 000000006194: 7E280359
  "v_mov_b32     v21, %[o_regs_53]                               \n"// 000000006198: 7E2A035D
  "v_mov_b32     v22, %[o_regs_57]                               \n"// 00000000619C: 7E2C0361
  "v_mov_b32     v23, %[o_regs_61]                              \n"// 0000000061A0: 7E2E0365
  "ds_write_b128  v5, v[20:23] offset:5280              \n"// 0000000061A4: D9BE14A0 00001405
  "v_mov_b32     v20, %[o_regs_50]                               \n"// 0000000061AC: 7E28035A
  "v_mov_b32     v21, %[o_regs_54]                               \n"// 0000000061B0: 7E2A035E
  "v_mov_b32     v22, %[o_regs_58]                               \n"// 0000000061B4: 7E2C0362
  "v_mov_b32     v23, %[o_regs_62]                              \n"// 0000000061B8: 7E2E0366
  "ds_write_b128  v5, v[20:23] offset:6336              \n"// 0000000061BC: D9BE18C0 00001405
  "v_mov_b32     v20, %[o_regs_51]                               \n"// 0000000061C4: 7E28035B
  "v_mov_b32     v21, %[o_regs_55]                               \n"// 0000000061C8: 7E2A035F
  "v_mov_b32     v22, %[o_regs_59]                               \n"// 0000000061CC: 7E2C0363
  "v_mov_b32     v23, %[o_regs_63]                              \n"// 0000000061D0: 7E2E0367
  "ds_write_b128  v5, v[20:23] offset:7392              \n"// 0000000061D4: D9BE1CE0 00001405
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000061DC: BF8CC47F
  "ds_read_b128  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v4                           \n"// 0000000061E0: D9FE0000 28000004
  "ds_read_b128  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v4 offset:64                 \n"// 0000000061E8: D9FE0040 2C000004
  "ds_read_b128  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v4 offset:128                \n"// 0000000061F0: D9FE0080 30000004
  "ds_read_b128  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v4 offset:192                \n"// 0000000061F8: D9FE00C0 34000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000006200: BF8CC47F
  "ds_read_b128  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v4 offset:4224               \n"// 000000006204: D9FE1080 38000004
  "ds_read_b128  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v4 offset:4288               \n"// 00000000620C: D9FE10C0 3C000004
  "ds_read_b128  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v4 offset:4352               \n"// 000000006214: D9FE1100 40000004
  "ds_read_b128  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v4 offset:4416               \n"// 00000000621C: D9FE1140 44000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000006224: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 000000006228: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 00000000622C: E07C1200 80022812
  "buffer_store_dwordx4  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 000000006234: E07C1300 80023812
  "v_add_u32     v18, 0x00002000, v18                   \n"// 00000000623C: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 000000006244: E07C1200 80022C12
  "buffer_store_dwordx4  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 00000000624C: E07C1300 80023C12
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000006254: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 00000000625C: E07C1200 80023012
  "buffer_store_dwordx4  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 000000006264: E07C1300 80024012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 00000000626C: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:512\n"// 000000006274: E07C1200 80023412
  "buffer_store_dwordx4  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:768\n"// 00000000627C: E07C1300 80024412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000006284: 682424FF 00002000
  "v_mov_b32     v20, %[o_regs_64]                              \n"// 00000000628C: 7E280368
  "v_mov_b32     v21, %[o_regs_68]                              \n"// 000000006290: 7E2A036C
  "v_mov_b32     v22, %[o_regs_72]                              \n"// 000000006294: 7E2C0370
  "v_mov_b32     v23, %[o_regs_76]                              \n"// 000000006298: 7E2E0374
  "ds_write_b128  v5, v[20:23]                          \n"// 00000000629C: D9BE0000 00001405
  "v_mov_b32     v20, %[o_regs_65]                              \n"// 0000000062A4: 7E280369
  "v_mov_b32     v21, %[o_regs_69]                              \n"// 0000000062A8: 7E2A036D
  "v_mov_b32     v22, %[o_regs_73]                              \n"// 0000000062AC: 7E2C0371
  "v_mov_b32     v23, %[o_regs_77]                              \n"// 0000000062B0: 7E2E0375
  "ds_write_b128  v5, v[20:23] offset:1056              \n"// 0000000062B4: D9BE0420 00001405
  "v_mov_b32     v20, %[o_regs_66]                              \n"// 0000000062BC: 7E28036A
  "v_mov_b32     v21, %[o_regs_70]                              \n"// 0000000062C0: 7E2A036E
  "v_mov_b32     v22, %[o_regs_74]                              \n"// 0000000062C4: 7E2C0372
  "v_mov_b32     v23, %[o_regs_78]                              \n"// 0000000062C8: 7E2E0376
  "ds_write_b128  v5, v[20:23] offset:2112              \n"// 0000000062CC: D9BE0840 00001405
  "v_mov_b32     v20, %[o_regs_67]                              \n"// 0000000062D4: 7E28036B
  "v_mov_b32     v21, %[o_regs_71]                              \n"// 0000000062D8: 7E2A036F
  "v_mov_b32     v22, %[o_regs_75]                              \n"// 0000000062DC: 7E2C0373
  "v_mov_b32     v23, %[o_regs_79]                              \n"// 0000000062E0: 7E2E0377
  "ds_write_b128  v5, v[20:23] offset:3168              \n"// 0000000062E4: D9BE0C60 00001405
  "v_mov_b32     v20, %[o_regs_80]                              \n"// 0000000062EC: 7E280378
  "v_mov_b32     v21, %[o_regs_84]                              \n"// 0000000062F0: 7E2A037C
  "v_mov_b32     v22, %[o_regs_88]                              \n"// 0000000062F4: 7E2C0380
  "v_mov_b32     v23, %[o_regs_92]                              \n"// 0000000062F8: 7E2E0384
  "ds_write_b128  v5, v[20:23] offset:4224              \n"// 0000000062FC: D9BE1080 00001405
  "v_mov_b32     v20, %[o_regs_81]                              \n"// 000000006304: 7E280379
  "v_mov_b32     v21, %[o_regs_85]                              \n"// 000000006308: 7E2A037D
  "v_mov_b32     v22, %[o_regs_89]                              \n"// 00000000630C: 7E2C0381
  "v_mov_b32     v23, %[o_regs_93]                              \n"// 000000006310: 7E2E0385
  "ds_write_b128  v5, v[20:23] offset:5280              \n"// 000000006314: D9BE14A0 00001405
  "v_mov_b32     v20, %[o_regs_82]                              \n"// 00000000631C: 7E28037A
  "v_mov_b32     v21, %[o_regs_86]                              \n"// 000000006320: 7E2A037E
  "v_mov_b32     v22, %[o_regs_90]                              \n"// 000000006324: 7E2C0382
  "v_mov_b32     v23, %[o_regs_94]                              \n"// 000000006328: 7E2E0386
  "ds_write_b128  v5, v[20:23] offset:6336              \n"// 00000000632C: D9BE18C0 00001405
  "v_mov_b32     v20, %[o_regs_83]                              \n"// 000000006334: 7E28037B
  "v_mov_b32     v21, %[o_regs_87]                              \n"// 000000006338: 7E2A037F
  "v_mov_b32     v22, %[o_regs_91]                              \n"// 00000000633C: 7E2C0383
  "v_mov_b32     v23, %[o_regs_95]                              \n"// 000000006340: 7E2E0387
  "ds_write_b128  v5, v[20:23] offset:7392              \n"// 000000006344: D9BE1CE0 00001405
  "s_waitcnt     lgkmcnt(4)                             \n"// 00000000634C: BF8CC47F
  "ds_read_b128  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v4                           \n"// 000000006350: D9FE0000 28000004
  "ds_read_b128  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v4 offset:64                 \n"// 000000006358: D9FE0040 2C000004
  "ds_read_b128  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v4 offset:128                \n"// 000000006360: D9FE0080 30000004
  "ds_read_b128  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v4 offset:192                \n"// 000000006368: D9FE00C0 34000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 000000006370: BF8CC47F
  "ds_read_b128  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v4 offset:4224               \n"// 000000006374: D9FE1080 38000004
  "ds_read_b128  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v4 offset:4288               \n"// 00000000637C: D9FE10C0 3C000004
  "ds_read_b128  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v4 offset:4352               \n"// 000000006384: D9FE1100 40000004
  "ds_read_b128  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v4 offset:4416               \n"// 00000000638C: D9FE1140 44000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000006394: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 000000006398: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1024\n"// 00000000639C: E07C1400 80022812
  "buffer_store_dwordx4  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1280\n"// 0000000063A4: E07C1500 80023812
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000063AC: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1024\n"// 0000000063B4: E07C1400 80022C12
  "buffer_store_dwordx4  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1280\n"// 0000000063BC: E07C1500 80023C12
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000063C4: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1024\n"// 0000000063CC: E07C1400 80023012
  "buffer_store_dwordx4  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1280\n"// 0000000063D4: E07C1500 80024012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000063DC: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1024\n"// 0000000063E4: E07C1400 80023412
  "buffer_store_dwordx4  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1280\n"// 0000000063EC: E07C1500 80024412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 0000000063F4: 682424FF 00002000
  "v_mov_b32     v20, %[o_regs_96]                              \n"// 0000000063FC: 7E280388
  "v_mov_b32     v21, %[o_regs_100]                              \n"// 000000006400: 7E2A038C
  "v_mov_b32     v22, %[o_regs_104]                              \n"// 000000006404: 7E2C0390
  "v_mov_b32     v23, %[o_regs_108]                              \n"// 000000006408: 7E2E0394
  "ds_write_b128  v5, v[20:23]                          \n"// 00000000640C: D9BE0000 00001405
  "v_mov_b32     v20, %[o_regs_97]                              \n"// 000000006414: 7E280389
  "v_mov_b32     v21, %[o_regs_101]                              \n"// 000000006418: 7E2A038D
  "v_mov_b32     v22, %[o_regs_105]                              \n"// 00000000641C: 7E2C0391
  "v_mov_b32     v23, %[o_regs_109]                              \n"// 000000006420: 7E2E0395
  "ds_write_b128  v5, v[20:23] offset:1056              \n"// 000000006424: D9BE0420 00001405
  "v_mov_b32     v20, %[o_regs_98]                              \n"// 00000000642C: 7E28038A
  "v_mov_b32     v21, %[o_regs_102]                              \n"// 000000006430: 7E2A038E
  "v_mov_b32     v22, %[o_regs_106]                              \n"// 000000006434: 7E2C0392
  "v_mov_b32     v23, %[o_regs_110]                              \n"// 000000006438: 7E2E0396
  "ds_write_b128  v5, v[20:23] offset:2112              \n"// 00000000643C: D9BE0840 00001405
  "v_mov_b32     v20, %[o_regs_99]                              \n"// 000000006444: 7E28038B
  "v_mov_b32     v21, %[o_regs_103]                              \n"// 000000006448: 7E2A038F
  "v_mov_b32     v22, %[o_regs_107]                              \n"// 00000000644C: 7E2C0393
  "v_mov_b32     v23, %[o_regs_111]                              \n"// 000000006450: 7E2E0397
  "ds_write_b128  v5, v[20:23] offset:3168              \n"// 000000006454: D9BE0C60 00001405
  "v_mov_b32     v20, %[o_regs_112]                              \n"// 00000000645C: 7E280398
  "v_mov_b32     v21, %[o_regs_116]                              \n"// 000000006460: 7E2A039C
  "v_mov_b32     v22, %[o_regs_120]                              \n"// 000000006464: 7E2C03A0
  "v_mov_b32     v23, %[o_regs_124]                              \n"// 000000006468: 7E2E03A4
  "ds_write_b128  v5, v[20:23] offset:4224              \n"// 00000000646C: D9BE1080 00001405
  "v_mov_b32     v20, %[o_regs_113]                              \n"// 000000006474: 7E280399
  "v_mov_b32     v21, %[o_regs_117]                              \n"// 000000006478: 7E2A039D
  "v_mov_b32     v22, %[o_regs_121]                              \n"// 00000000647C: 7E2C03A1
  "v_mov_b32     v23, %[o_regs_125]                              \n"// 000000006480: 7E2E03A5
  "ds_write_b128  v5, v[20:23] offset:5280              \n"// 000000006484: D9BE14A0 00001405
  "v_mov_b32     v20, %[o_regs_114]                              \n"// 00000000648C: 7E28039A
  "v_mov_b32     v21, %[o_regs_118]                              \n"// 000000006490: 7E2A039E
  "v_mov_b32     v22, %[o_regs_122]                              \n"// 000000006494: 7E2C03A2
  "v_mov_b32     v23, %[o_regs_126]                              \n"// 000000006498: 7E2E03A6
  "ds_write_b128  v5, v[20:23] offset:6336              \n"// 00000000649C: D9BE18C0 00001405
  "v_mov_b32     v20, %[o_regs_115]                              \n"// 0000000064A4: 7E28039B
  "v_mov_b32     v21, %[o_regs_119]                              \n"// 0000000064A8: 7E2A039F
  "v_mov_b32     v22, %[o_regs_123]                              \n"// 0000000064AC: 7E2C03A3
  "v_mov_b32     v23, %[o_regs_127]                              \n"// 0000000064B0: 7E2E03A7
  "ds_write_b128  v5, v[20:23] offset:7392              \n"// 0000000064B4: D9BE1CE0 00001405
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000064BC: BF8CC47F
  "ds_read_b128  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v4                           \n"// 0000000064C0: D9FE0000 28000004
  "ds_read_b128  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v4 offset:64                 \n"// 0000000064C8: D9FE0040 2C000004
  "ds_read_b128  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v4 offset:128                \n"// 0000000064D0: D9FE0080 30000004
  "ds_read_b128  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v4 offset:192                \n"// 0000000064D8: D9FE00C0 34000004
  "s_waitcnt     lgkmcnt(4)                             \n"// 0000000064E0: BF8CC47F
  "ds_read_b128  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v4 offset:4224               \n"// 0000000064E4: D9FE1080 38000004
  "ds_read_b128  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v4 offset:4288               \n"// 0000000064EC: D9FE10C0 3C000004
  "ds_read_b128  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v4 offset:4352               \n"// 0000000064F4: D9FE1100 40000004
  "ds_read_b128  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v4 offset:4416               \n"// 0000000064FC: D9FE1140 44000004
  "s_waitcnt     lgkmcnt(0)                             \n"// 000000006504: BF8CC07F
  "v_mov_b32     v18, v19                               \n"// 000000006508: 7E240313
  "buffer_store_dwordx4  [%[o_regs_0], %[o_regs_1], %[o_regs_2], %[o_regs_3]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1536\n"// 00000000650C: E07C1600 80022812
  "buffer_store_dwordx4  [%[o_regs_16], %[o_regs_17], %[o_regs_18], %[o_regs_19]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1792\n"// 000000006514: E07C1700 80023812
  "v_add_u32     v18, 0x00002000, v18                   \n"// 00000000651C: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_4], %[o_regs_5], %[o_regs_6], %[o_regs_7]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1536\n"// 000000006524: E07C1600 80022C12
  "buffer_store_dwordx4  [%[o_regs_20], %[o_regs_21], %[o_regs_22], %[o_regs_23]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1792\n"// 00000000652C: E07C1700 80023C12
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000006534: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_8], %[o_regs_9], %[o_regs_10], %[o_regs_11]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1536\n"// 00000000653C: E07C1600 80023012
  "buffer_store_dwordx4  [%[o_regs_24], %[o_regs_25], %[o_regs_26], %[o_regs_27]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1792\n"// 000000006544: E07C1700 80024012
  "v_add_u32     v18, 0x00002000, v18                   \n"// 00000000654C: 682424FF 00002000
  "buffer_store_dwordx4  [%[o_regs_12], %[o_regs_13], %[o_regs_14], %[o_regs_15]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1536\n"// 000000006554: E07C1600 80023412
  "buffer_store_dwordx4  [%[o_regs_28], %[o_regs_29], %[o_regs_30], %[o_regs_31]], v18, [%[o_res_0], %[o_res_1], %[o_res_2], %[o_res_3]], 0 offen offset:1792\n"// 00000000655C: E07C1700 80024412
  "v_add_u32     v18, 0x00002000, v18                   \n"// 000000006564: 682424FF 00002000
  "buffer_store_dword  %[lse_result], v26, [%[lse_res_0], %[lse_res_1], %[lse_res_2], %[lse_res_3]], 0 offen      \n"// 00000000656C: E0701000 8003181A
  "s_mul_i32     s56, 4, s77                            \n"// 000000006574: 92384D84
  "v_add_u32     v26, v26, s56                          \n"// 000000006578: D134001A 0000711A
"label_1960: \n"
  "s_waitcnt     0x0000                                 \n"// 000000006580: BF8C0000
