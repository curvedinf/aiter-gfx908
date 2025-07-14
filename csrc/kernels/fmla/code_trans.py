


file_w = open("./macro_utils.hpp", mode="w")

lines = []

for loop in range(8):
    for i in range(4):
        for j in range(4):
            if j != 3:
                line = f"#define LOOP_STRIDE4_{16 * loop + i + 4 * j}(func)  func({i//2==0 ? 0:1}, {j * 4})  LOOP_STRIDE4_{16 * loop + i + 4 * j + 4}(func)"
            else:
                line = f"#define LOOP_STRIDE4_{16 * loop + i + 4 * j}(func)  func(1, {j * 4})  LOOP_STRIDE4_END(func)"

        file_w.write(line)

    file_w.write("\n")


