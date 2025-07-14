#define LOOPEND()
#define LOOP_STRIDE4_0(func1, func2)  func1(0, 0)  LOOP_STRIDE4_4(func1, func2) 
#define LOOP_STRIDE4_4(func1, func2)  func2(0, 4)  LOOP_STRIDE4_8(func1, func2) 
#define LOOP_STRIDE4_8(func1, func2)  func1(1, 8)  LOOP_STRIDE4_12(func1, func2) 
#define LOOP_STRIDE4_12(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_1(func1, func2)  func1(0, 0)  LOOP_STRIDE4_5(func1, func2) 
#define LOOP_STRIDE4_5(func1, func2)  func2(0, 4)  LOOP_STRIDE4_9(func1, func2) 
#define LOOP_STRIDE4_9(func1, func2)  func1(1, 8)  LOOP_STRIDE4_13(func1, func2) 
#define LOOP_STRIDE4_13(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_2(func1, func2)  func1(0, 0)  LOOP_STRIDE4_6(func1, func2) 
#define LOOP_STRIDE4_6(func1, func2)  func2(0, 4)  LOOP_STRIDE4_10(func1, func2) 
#define LOOP_STRIDE4_10(func1, func2)  func1(1, 8)  LOOP_STRIDE4_14(func1, func2) 
#define LOOP_STRIDE4_14(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_3(func1, func2)  func1(0, 0)  LOOP_STRIDE4_7(func1, func2) 
#define LOOP_STRIDE4_7(func1, func2)  func2(0, 4)  LOOP_STRIDE4_11(func1, func2) 
#define LOOP_STRIDE4_11(func1, func2)  func1(1, 8)  LOOP_STRIDE4_15(func1, func2) 
#define LOOP_STRIDE4_15(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_16(func1, func2)  func1(0, 0)  LOOP_STRIDE4_20(func1, func2) 
#define LOOP_STRIDE4_20(func1, func2)  func2(0, 4)  LOOP_STRIDE4_24(func1, func2) 
#define LOOP_STRIDE4_24(func1, func2)  func1(1, 8)  LOOP_STRIDE4_28(func1, func2) 
#define LOOP_STRIDE4_28(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_17(func1, func2)  func1(0, 0)  LOOP_STRIDE4_21(func1, func2) 
#define LOOP_STRIDE4_21(func1, func2)  func2(0, 4)  LOOP_STRIDE4_25(func1, func2) 
#define LOOP_STRIDE4_25(func1, func2)  func1(1, 8)  LOOP_STRIDE4_29(func1, func2) 
#define LOOP_STRIDE4_29(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_18(func1, func2)  func1(0, 0)  LOOP_STRIDE4_22(func1, func2) 
#define LOOP_STRIDE4_22(func1, func2)  func2(0, 4)  LOOP_STRIDE4_26(func1, func2) 
#define LOOP_STRIDE4_26(func1, func2)  func1(1, 8)  LOOP_STRIDE4_30(func1, func2) 
#define LOOP_STRIDE4_30(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_19(func1, func2)  func1(0, 0)  LOOP_STRIDE4_23(func1, func2) 
#define LOOP_STRIDE4_23(func1, func2)  func2(0, 4)  LOOP_STRIDE4_27(func1, func2) 
#define LOOP_STRIDE4_27(func1, func2)  func1(1, 8)  LOOP_STRIDE4_31(func1, func2) 
#define LOOP_STRIDE4_31(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_32(func1, func2)  func1(0, 0)  LOOP_STRIDE4_36(func1, func2) 
#define LOOP_STRIDE4_36(func1, func2)  func2(0, 4)  LOOP_STRIDE4_40(func1, func2) 
#define LOOP_STRIDE4_40(func1, func2)  func1(1, 8)  LOOP_STRIDE4_44(func1, func2) 
#define LOOP_STRIDE4_44(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_33(func1, func2)  func1(0, 0)  LOOP_STRIDE4_37(func1, func2) 
#define LOOP_STRIDE4_37(func1, func2)  func2(0, 4)  LOOP_STRIDE4_41(func1, func2) 
#define LOOP_STRIDE4_41(func1, func2)  func1(1, 8)  LOOP_STRIDE4_45(func1, func2) 
#define LOOP_STRIDE4_45(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_34(func1, func2)  func1(0, 0)  LOOP_STRIDE4_38(func1, func2) 
#define LOOP_STRIDE4_38(func1, func2)  func2(0, 4)  LOOP_STRIDE4_42(func1, func2) 
#define LOOP_STRIDE4_42(func1, func2)  func1(1, 8)  LOOP_STRIDE4_46(func1, func2) 
#define LOOP_STRIDE4_46(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_35(func1, func2)  func1(0, 0)  LOOP_STRIDE4_39(func1, func2) 
#define LOOP_STRIDE4_39(func1, func2)  func2(0, 4)  LOOP_STRIDE4_43(func1, func2) 
#define LOOP_STRIDE4_43(func1, func2)  func1(1, 8)  LOOP_STRIDE4_47(func1, func2) 
#define LOOP_STRIDE4_47(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_48(func1, func2)  func1(0, 0)  LOOP_STRIDE4_52(func1, func2) 
#define LOOP_STRIDE4_52(func1, func2)  func2(0, 4)  LOOP_STRIDE4_56(func1, func2) 
#define LOOP_STRIDE4_56(func1, func2)  func1(1, 8)  LOOP_STRIDE4_60(func1, func2) 
#define LOOP_STRIDE4_60(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_49(func1, func2)  func1(0, 0)  LOOP_STRIDE4_53(func1, func2) 
#define LOOP_STRIDE4_53(func1, func2)  func2(0, 4)  LOOP_STRIDE4_57(func1, func2) 
#define LOOP_STRIDE4_57(func1, func2)  func1(1, 8)  LOOP_STRIDE4_61(func1, func2) 
#define LOOP_STRIDE4_61(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_50(func1, func2)  func1(0, 0)  LOOP_STRIDE4_54(func1, func2) 
#define LOOP_STRIDE4_54(func1, func2)  func2(0, 4)  LOOP_STRIDE4_58(func1, func2) 
#define LOOP_STRIDE4_58(func1, func2)  func1(1, 8)  LOOP_STRIDE4_62(func1, func2) 
#define LOOP_STRIDE4_62(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_51(func1, func2)  func1(0, 0)  LOOP_STRIDE4_55(func1, func2) 
#define LOOP_STRIDE4_55(func1, func2)  func2(0, 4)  LOOP_STRIDE4_59(func1, func2) 
#define LOOP_STRIDE4_59(func1, func2)  func1(1, 8)  LOOP_STRIDE4_63(func1, func2) 
#define LOOP_STRIDE4_63(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_64(func1, func2)  func1(0, 0)  LOOP_STRIDE4_68(func1, func2) 
#define LOOP_STRIDE4_68(func1, func2)  func2(0, 4)  LOOP_STRIDE4_72(func1, func2) 
#define LOOP_STRIDE4_72(func1, func2)  func1(1, 8)  LOOP_STRIDE4_76(func1, func2) 
#define LOOP_STRIDE4_76(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_65(func1, func2)  func1(0, 0)  LOOP_STRIDE4_69(func1, func2) 
#define LOOP_STRIDE4_69(func1, func2)  func2(0, 4)  LOOP_STRIDE4_73(func1, func2) 
#define LOOP_STRIDE4_73(func1, func2)  func1(1, 8)  LOOP_STRIDE4_77(func1, func2) 
#define LOOP_STRIDE4_77(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_66(func1, func2)  func1(0, 0)  LOOP_STRIDE4_70(func1, func2) 
#define LOOP_STRIDE4_70(func1, func2)  func2(0, 4)  LOOP_STRIDE4_74(func1, func2) 
#define LOOP_STRIDE4_74(func1, func2)  func1(1, 8)  LOOP_STRIDE4_78(func1, func2) 
#define LOOP_STRIDE4_78(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_67(func1, func2)  func1(0, 0)  LOOP_STRIDE4_71(func1, func2) 
#define LOOP_STRIDE4_71(func1, func2)  func2(0, 4)  LOOP_STRIDE4_75(func1, func2) 
#define LOOP_STRIDE4_75(func1, func2)  func1(1, 8)  LOOP_STRIDE4_79(func1, func2) 
#define LOOP_STRIDE4_79(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_80(func1, func2)  func1(0, 0)  LOOP_STRIDE4_84(func1, func2) 
#define LOOP_STRIDE4_84(func1, func2)  func2(0, 4)  LOOP_STRIDE4_88(func1, func2) 
#define LOOP_STRIDE4_88(func1, func2)  func1(1, 8)  LOOP_STRIDE4_92(func1, func2) 
#define LOOP_STRIDE4_92(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_81(func1, func2)  func1(0, 0)  LOOP_STRIDE4_85(func1, func2) 
#define LOOP_STRIDE4_85(func1, func2)  func2(0, 4)  LOOP_STRIDE4_89(func1, func2) 
#define LOOP_STRIDE4_89(func1, func2)  func1(1, 8)  LOOP_STRIDE4_93(func1, func2) 
#define LOOP_STRIDE4_93(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_82(func1, func2)  func1(0, 0)  LOOP_STRIDE4_86(func1, func2) 
#define LOOP_STRIDE4_86(func1, func2)  func2(0, 4)  LOOP_STRIDE4_90(func1, func2) 
#define LOOP_STRIDE4_90(func1, func2)  func1(1, 8)  LOOP_STRIDE4_94(func1, func2) 
#define LOOP_STRIDE4_94(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_83(func1, func2)  func1(0, 0)  LOOP_STRIDE4_87(func1, func2) 
#define LOOP_STRIDE4_87(func1, func2)  func2(0, 4)  LOOP_STRIDE4_91(func1, func2) 
#define LOOP_STRIDE4_91(func1, func2)  func1(1, 8)  LOOP_STRIDE4_95(func1, func2) 
#define LOOP_STRIDE4_95(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_96(func1, func2)  func1(0, 0)  LOOP_STRIDE4_100(func1, func2) 
#define LOOP_STRIDE4_100(func1, func2)  func2(0, 4)  LOOP_STRIDE4_104(func1, func2) 
#define LOOP_STRIDE4_104(func1, func2)  func1(1, 8)  LOOP_STRIDE4_108(func1, func2) 
#define LOOP_STRIDE4_108(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_97(func1, func2)  func1(0, 0)  LOOP_STRIDE4_101(func1, func2) 
#define LOOP_STRIDE4_101(func1, func2)  func2(0, 4)  LOOP_STRIDE4_105(func1, func2) 
#define LOOP_STRIDE4_105(func1, func2)  func1(1, 8)  LOOP_STRIDE4_109(func1, func2) 
#define LOOP_STRIDE4_109(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_98(func1, func2)  func1(0, 0)  LOOP_STRIDE4_102(func1, func2) 
#define LOOP_STRIDE4_102(func1, func2)  func2(0, 4)  LOOP_STRIDE4_106(func1, func2) 
#define LOOP_STRIDE4_106(func1, func2)  func1(1, 8)  LOOP_STRIDE4_110(func1, func2) 
#define LOOP_STRIDE4_110(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_99(func1, func2)  func1(0, 0)  LOOP_STRIDE4_103(func1, func2) 
#define LOOP_STRIDE4_103(func1, func2)  func2(0, 4)  LOOP_STRIDE4_107(func1, func2) 
#define LOOP_STRIDE4_107(func1, func2)  func1(1, 8)  LOOP_STRIDE4_111(func1, func2) 
#define LOOP_STRIDE4_111(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_112(func1, func2)  func1(0, 0)  LOOP_STRIDE4_116(func1, func2) 
#define LOOP_STRIDE4_116(func1, func2)  func2(0, 4)  LOOP_STRIDE4_120(func1, func2) 
#define LOOP_STRIDE4_120(func1, func2)  func1(1, 8)  LOOP_STRIDE4_124(func1, func2) 
#define LOOP_STRIDE4_124(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_113(func1, func2)  func1(0, 0)  LOOP_STRIDE4_117(func1, func2) 
#define LOOP_STRIDE4_117(func1, func2)  func2(0, 4)  LOOP_STRIDE4_121(func1, func2) 
#define LOOP_STRIDE4_121(func1, func2)  func1(1, 8)  LOOP_STRIDE4_125(func1, func2) 
#define LOOP_STRIDE4_125(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_114(func1, func2)  func1(0, 0)  LOOP_STRIDE4_118(func1, func2) 
#define LOOP_STRIDE4_118(func1, func2)  func2(0, 4)  LOOP_STRIDE4_122(func1, func2) 
#define LOOP_STRIDE4_122(func1, func2)  func1(1, 8)  LOOP_STRIDE4_126(func1, func2) 
#define LOOP_STRIDE4_126(func1, func2)  func2(1, 12)  LOOPEND() 

#define LOOP_STRIDE4_115(func1, func2)  func1(0, 0)  LOOP_STRIDE4_119(func1, func2) 
#define LOOP_STRIDE4_119(func1, func2)  func2(0, 4)  LOOP_STRIDE4_123(func1, func2) 
#define LOOP_STRIDE4_123(func1, func2)  func1(1, 8)  LOOP_STRIDE4_127(func1, func2) 
#define LOOP_STRIDE4_127(func1, func2)  func2(1, 12)  LOOPEND() 

#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_0(func, lds_ld_base)  func(0, lds_ld_base + 0)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_1(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_1(func, lds_ld_base)  func(1, lds_ld_base + 1)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_2(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_2(func, lds_ld_base)  func(6, lds_ld_base + 18)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_3(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_0_3(func, lds_ld_base)  func(7, lds_ld_base + 19)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_0(func, lds_ld_base) 

#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_0(func, lds_ld_base)  func(2, lds_ld_base + 288)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_1(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_1(func, lds_ld_base)  func(3, lds_ld_base + 289)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_2(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_2(func, lds_ld_base)  func(8, lds_ld_base + 306)  B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_3(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_0_1_3(func, lds_ld_base)  func(9, lds_ld_base + 307)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_0(func, lds_ld_base) 

#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_0(func, lds_ld_base)  func(8, lds_ld_base + 576)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_1(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_1(func, lds_ld_base)  func(9, lds_ld_base + 577)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_2(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_2(func, lds_ld_base)  func(14, lds_ld_base + 594)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_3(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_0_3(func, lds_ld_base)  func(15, lds_ld_base + 595)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_0(func, lds_ld_base) 

#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_0(func, lds_ld_base)  func(10, lds_ld_base + 864)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_1(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_1(func, lds_ld_base)  func(11, lds_ld_base + 865)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_2(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_2(func, lds_ld_base)  func(16, lds_ld_base + 882)  B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_3(func, lds_ld_base) 
#define B16_LDS_2_VGPR_LOOP_STRIDE1_1_1_3(func, lds_ld_base)  func(17, lds_ld_base + 883)  LOOPEND() 

#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_0(func, dram_st_base)  func(0, dram_st_base + 0)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_1(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_1(func, dram_st_base)  func(1, dram_st_base + 1)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_2(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_2(func, dram_st_base)  func(2, dram_st_base + 2)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_3(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_0_3(func, dram_st_base)  func(3, dram_st_base + 3)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_0(func, dram_st_base) 

#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_0(func, dram_st_base)  func(8, dram_st_base + 32)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_1(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_1(func, dram_st_base)  func(9, dram_st_base + 33)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_2(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_2(func, dram_st_base)  func(10, dram_st_base + 34)  B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_3(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_0_1_3(func, dram_st_base)  func(11, dram_st_base + 35)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_0(func, dram_st_base) 

#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_0(func, dram_st_base)  func(4, dram_st_base + 2048)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_1(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_1(func, dram_st_base)  func(5, dram_st_base + 2049)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_2(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_2(func, dram_st_base)  func(6, dram_st_base + 2050)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_3(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_0_3(func, dram_st_base)  func(7, dram_st_base + 2051)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_0(func, dram_st_base) 

#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_0(func, dram_st_base)  func(12, dram_st_base + 2080)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_1(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_1(func, dram_st_base)  func(13, dram_st_base + 2081)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_2(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_2(func, dram_st_base)  func(14, dram_st_base + 2082)  B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_3(func, dram_st_base) 
#define B16_VGPR_2_DRAM_LOOP_STRIDE1_1_1_3(func, dram_st_base)  func(15, dram_st_base + 2083)  LOOPEND() 

