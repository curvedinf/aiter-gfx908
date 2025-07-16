# SPDX-License-Identifier: MIT
# Copyright (C) 2025, Advanced Micro Devices, Inc. All rights reserved.
from dataclasses import dataclass


@dataclass
class kernelInstance:
    BLOCK_SIZE: int
    # GroupCount: int
    MPerBLOCK: int
    NPerBLOCK: int
    KPerBLOCK: int
    WAVE_TILE_M: int
    WAVE_TILE_N: int
    WAVE_TILE_K: int
    WAVE_MAP_M: int
    WAVE_MAP_N: int
    # ABLOCK_TRANSFER: list[int]
    # BBLOCK_TRANSFER: list[int]
    # CBLOCK_TRANSFER: list[int]
    # CBLOCK_SPV: list[int]
    # CSHUFFLE_MX_PER_WAVE_PERSHUFFLE: int
    # CSHUFFLE_NX_PER_WAVE_PERSHUFFLE: int
    LOOP_SCHED: str
    PIPELINE_VERSION: int

    @property
    def name(self) -> str:
        return ("_").join(
            [
                "m_grouped_gemm",
                ("x").join(
                    map(
                        lambda x: str(x),
                        [
                            self.BLOCK_SIZE,
                            self.MPerBLOCK,
                            self.NPerBLOCK,
                            self.KPerBLOCK,
                        ],
                    )
                ),
                ("x").join(map(lambda x: str(x), [self.WAVE_TILE_M, self.WAVE_TILE_N, self.WAVE_TILE_K])),
                ("x").join(map(lambda x: str(x), [self.WAVE_MAP_M, self.WAVE_MAP_N])),
                # ("x").join(map(lambda x: str(x), self.ABLOCK_TRANSFER)),
                # ("x").join(map(lambda x: str(x), self.BBLOCK_TRANSFER)),
                # ("x").join(map(lambda x: str(x), self.CBLOCK_TRANSFER)),
                # ("x").join(map(lambda x: str(x), self.CBLOCK_SPV)),
                # ("x").join(
                #     map(
                #         lambda x: str(x),
                #         [
                #             self.CSHUFFLE_MX_PER_WAVE_PERSHUFFLE,
                #             self.CSHUFFLE_NX_PER_WAVE_PERSHUFFLE,
                #         ],
                #     )
                # ),
                self.LOOP_SCHED.lower(),
                f"v{self.PIPELINE_VERSION}",
            ]
        )


# fmt: off
kernels_list = {
#   (    M,     N,     K): kernel:        BLOCK_SIZE| MPerBLOCK| NPerBLOCK| KPerBLOCK| WAVE_TILE_M| WAVE_TILE_N| WAVE_TILE_K| WAVE_MAP_M| WAVE_MAP_N|  LOOP_SCHED|PIPELINE_VERSION
    1:                     kernelInstance(       256,       128,       128,       128,           16,         16,          32,         1,           4, "Intrawave",  3),
}


default_kernels_dict = {
#   (    M,     N,     K): kernel:        BLOCK_SIZE| MPerBLOCK| NPerBLOCK| KPerBLOCK| WAVE_TILE_M| WAVE_TILE_N| WAVE_MAP_M| WAVE_MAP_N| ABLOCK_TRANSFER| BBLOCK_TRANSFER| CBLOCK_TRANSFER| CBLOCK_SPV| CSHUFFLE_MX| CSHUFFLE_NX|  LOOP_SCHED|PIPELINE_VERSION
    (-1):                  kernelInstance(        64,        16,        16,       128,           16,         16,          1,          1,      [8, 8,  1],      [8, 8,  1],   [1, 16, 1, 4],  [4, 4, 1],           1,           1, "Interwave",  2),
    (-3):                  kernelInstance(       128,        32,        16,       128,           16,         16,          1,          1,      [8, 16, 1],      [8, 16, 1],   [1, 16, 1, 8],  [2, 2, 1],           1,           1, "Interwave",  2),
    (-4):                  kernelInstance(        64,        16,        16,       256,           16,         16,          1,          1,      [16, 4, 1],      [16, 4, 1],   [1, 16, 1, 4],  [4, 4, 1],           1,           1, "Intrawave",  1),
    (-5):                  kernelInstance(       128,        16,        32,       128,           16,         16,          1,          1,      [8, 16, 1],      [8, 16, 1],   [1, 16, 1, 8],  [2, 2, 1],           1,           1, "Intrawave",  2),
    (-6):                  kernelInstance(       256,       128,       128,       128,           32,         32,          2,          2,      [8, 32, 1],      [8, 32, 1],   [1, 32, 1, 8],  [8, 8, 1],           1,           1, "Interwave",  1),
    (-7):                  kernelInstance(       256,       128,       128,       128,           32,         32,          2,          2,      [8, 32, 1],      [8, 32, 1],   [1, 32, 1, 8],  [8, 8, 1],           1,           1, "Intrawave",  3),
    (-8):                  kernelInstance(       256,       256,       128,        64,           32,         32,          4,          2,      [4, 64, 1],      [4, 64, 1],   [1, 32, 1, 8],  [8, 8, 1],           1,           1, "Interwave",  1),
    (-9):                  kernelInstance(       256,       224,       256,       128,           16,         16,          7,          8,      [8, 32, 1],      [8, 32, 1],   [1, 32, 1, 8],  [8, 8, 1],           1,           2, "Intrawave",  3),
    (-10):                 kernelInstance(       128,        16,        32,       128,           16,         16,          1,          1,      [8, 16, 1],      [8, 16, 1],   [1, 16, 1, 8],  [4, 4, 1],           1,           1, "Intrawave",  2),

}
# fmt: on
