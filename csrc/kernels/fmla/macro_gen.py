
file_w = open("./macro_utils.hpp", mode="w")

file_w.write("#define LOOPEND()\n")

for loop in range(8):
    for i in range(4):
        for j in range(4):
            if j != 3:
                func = "func1" if j % 2 == 0 else "func2"
                line = f"#define LOOP_STRIDE4_{16 * loop + i + 4 * j}(func1, func2)  {func}({j//2}, {j * 4})  LOOP_STRIDE4_{16 * loop + i + 4 * j + 4}(func1, func2) \n"
            else:
                line = f"#define LOOP_STRIDE4_{16 * loop + i + 4 * j}(func1, func2)  func2(1, {j * 4})  LOOPEND() \n"

            file_w.write(line)
        file_w.write("\n")


for r in range(2):
    for i in range(2):
        for j in range(4):
            if j != 3:
                line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + j // 2 * 4}, lds_ld_base + {r * 576 + i * 288 + j + (j // 2) * 16})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j + 1}(func, lds_ld_base) \n"
            elif i == 0:
                line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + j // 2 * 4}, lds_ld_base + {r * 576 + i * 288 + j + (j // 2) * 16})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i + 1}_{0}(func, lds_ld_base) \n"
            elif r == 0:
                line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + j // 2 * 4}, lds_ld_base + {r * 576 + i * 288 + j + (j // 2) * 16})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r + 1}_{0}_{0}(func, lds_ld_base) \n"
            else:
                line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + j // 2 * 4}, lds_ld_base + {r * 576 + i * 288 + j + (j // 2) * 16})  LOOPEND() \n"
            file_w.write(line)
        file_w.write("\n")
        #
        # for j in range(2):
        #     if j == 0:
        #         line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + 4}, lds_ld_base + {r * 576 + i * 16 + j + 288})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j + 1}(func, lds_ld_base) \n"
        #     elif i == 0:
        #         line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + 4}, lds_ld_base + {r * 576 + i * 16 + j + 288})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i + 1}_{0}(func, lds_ld_base) \n"
        #     elif r == 0:
        #         line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + 4}, lds_ld_base + {r * 576 + i * 16 + j + 288})  B16_LDS_2_VGPR_LOOP_STRIDE1_{r + 1}_{0}_{0}(func, lds_ld_base) \n"
        #     else:
        #         line = f"#define B16_LDS_2_VGPR_LOOP_STRIDE1_{r}_{i}_{j}(func, lds_ld_base)  func({r * 8 + i * 2 + j + 4}, lds_ld_base + {r * 576 + i * 16 + j + 288})  B16_LDS_2_VGPR_LOOP_STRIDE1_END() \n"
        #     file_w.write(line)
        # file_w.write("\n")


for r in range(2):
    for i in range(2):
        for j in range(4):
            if j != 3:
                line = f"#define B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i}_{j}(func, dram_st_base)  func({r * 4 + i * 8 + j}, dram_st_base + {r * 2048 + i * 32 + j})  B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i}_{j + 1}(func, dram_st_base) \n"
            elif i == 0:
                line = f"#define B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i}_{j}(func, dram_st_base)  func({r * 4 + i * 8 + j}, dram_st_base + {r * 2048 + i * 32 + j})  B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i + 1}_{0}(func, dram_st_base) \n"
            elif r == 0:
                line = f"#define B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i}_{j}(func, dram_st_base)  func({r * 4 + i * 8 + j}, dram_st_base + {r * 2048 + i * 32 + j})  B16_VGPR_2_DRAM_LOOP_STRIDE1_{r + 1}_{0}_{0}(func, dram_st_base) \n"
            else:
                line = f"#define B16_VGPR_2_DRAM_LOOP_STRIDE1_{r}_{i}_{j}(func, dram_st_base)  func({r * 4 + i * 8 + j}, dram_st_base + {r * 2048 + i * 32 + j})  LOOPEND() \n"
            file_w.write(line)
        file_w.write("\n")



# for r in range(2):
#     for i in range(2):
#         for j in range(4):
#             if j != 3:
#                 line = f"#define B16_LOOP_STRIDE1_{r}_{i}_{j}(func, off1, off2, ptr_base)  func(off1({r}, {i}, {j}), ptr_base + off2({r}, {i}, {j}))  B16_LOOP_STRIDE1_{r}_{i}_{j + 1}(func, off1, off2, ptr_base) \n"
#             elif i == 0:
#                 line = f"#define B16_LOOP_STRIDE1_{r}_{i}_{j}(func, off1, off2, ptr_base)  func(off1({r}, {i}, {j}), ptr_base + off2({r}, {i}, {j}))  B16_LOOP_STRIDE1_{r}_{i + 1}_{0}(func, off1, off2, ptr_base) \n"
#             elif r == 0:
#                 line = f"#define B16_LOOP_STRIDE1_{r}_{i}_{j}(func, off1, off2, ptr_base)  func(off1({r}, {i}, {j}), ptr_base + off2({r}, {i}, {j}))  B16_LOOP_STRIDE1_{r + 1}_{0}_{0}(func, off1, off2, ptr_base) \n"
#             else:
#                 line = f"#define B16_LOOP_STRIDE1_{r}_{i}_{j}(func, off1, off2, ptr_base)  func(off1({r}, {i}, {j}), ptr_base + off2({r}, {i}, {j}))  B16_LOOP_STRIDE1_END() \n"
#             file_w.write(line)
#         file_w.write("\n")
