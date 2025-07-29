# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
from dataclasses import dataclass
from aiter.jit.utils.chip_info import get_gfx

@dataclass
class kernelInstance:
    sTransposeC: bool
    sUseStructuredSparsity: bool
    sTileParitionerGroupNum: int
    sTileParitionerM01: int
    sNumWaveGroups : int
    sDoubleSmemBuffer: bool
    PadM: bool
    PadN: bool
    PadK: bool
    BlockPerCu: int
    MTile:int
    NTile: int
    KTile: int
    MWarp: int
    NWarp: int
    KWarp: int
    MWTile: int
    NWTile: int
    KWTile: int
    sScheduler: str

    @property
    def name(self) -> str:
        return ("_").join([
            "a8w8_bpreshuffle_cktile",

            ("x").join(map(lambda x: str(x),
                        [
                            self.sTransposeC, 
                            self.sUseStructuredSparsity, 
                            self.sTileParitionerGroupNum, 
                            self.sTileParitionerM01,
                            self.sNumWaveGroups,
                            self.sDoubleSmemBuffer,
                            self.PadM, 
                            self.PadN, 
                            self.PadK, 
                            self.BlockPerCu
                        ])),
            ("x").join(map(lambda x: str(x), [
                self.MTile, self.NTile, self.KTile])),
            ("x").join(map(lambda x: str(x), [
                self.MWarp, self.NWarp, self.KWarp])),
            ("x").join(map(lambda x: str(x), [
                self.MWTile, self.NWTile, self.KWTile])),
            self.sScheduler.lower(),
        ])


# fmt: off
# kernels_list_str = '''
kernels_list_942 = {
    0: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   128,  1,  4,  1,   16,    16,    64, "Default"),
    1: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   256,  1,  4,  1,   16,    16,    64, "Default"),
    2: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    64,    512,  1,  4,  1,   16,    16,    64, "Default"),
    3: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    128,   512,  1,  4,  1,   16,    16,    64, "Default"),
    4: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    256,   512,  1,  4,  1,   16,    16,    64, "Default"),
    5: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    64,    256,  1,  4,  1,   16,    16,    64, "Default"),
    6: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    128,   256,  1,  4,  1,   16,    16,    64, "Default"),
    7: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    256,   256,  1,  4,  1,   16,    16,    64, "Default"),
    8: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    512,   256,  1,  4,  1,   16,    16,    64, "Default"),
    9: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 32,    64,    512,  1,  4,  1,   16,    16,    64, "Default"),
    10: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 64,   256,   64,   1,  4,  1,   16,    16,    64, "Default"),
    11: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,  64,   128,   1,  4,  1,   16,    16,    64, "Default"),
    12: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,  64,   256,   1,  4,  1,   16,    16,    64, "Default"),
    13: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,  128,   64,   1,  4,  1,   16,    16,    64, "Default"),
    14: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,  256,   128,  1,  4,  1,   16,    16,    64, "Default"),
}
# '''

default_kernels_dict_942 = {
    (-1): kernelInstance(0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   128,  1,  4,  1,   16,    16,    64, "Default"),
    (-2):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 16,    64,    512,  1,  4,  1,   16,    16,    64, "Default"),
    (-3):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 32,    64,    512,  1,  4,  1,   16,    16,    64, "Default"),
    (-4):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 64,    256,   64,   1,  4,  1,   16,    16,    64, "Default"),
    (-5):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   64,   1,  4,  1,   16,    16,    64, "Default"),
    (-6):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   64,   128,   1,  4,  1,   16,    16,    64, "Default"),
}

kernels_list_950 = {
    0: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 256,   256,   128,  1,  4,  1,   16,    16,    128, "Default"),
    # 1: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 128,   128,   256,  1,  4,  1,   16,    16,    128, "Default"),
    # 2: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    64,    512,  1,  4,  1,   16,    16,    128, "Default"),
    # 3: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    128,   512,  1,  4,  1,   16,    16,    128, "Default"),
    # 4: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    256,   512,  1,  4,  1,   16,    16,    128, "Default"),
    # 5: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    64,    256,  1,  4,  1,   16,    16,    128, "Default"),
    # 6: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    128,   256,  1,  4,  1,   16,    16,    128, "Default"),
    # 7: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    256,   256,  1,  4,  1,   16,    16,    128, "Default"),
    # 8: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 16,    512,   256,  1,  4,  1,   16,    16,    128, "Default"),
    # 9: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 1, 32,    64,    512,  1,  4,  1,   16,    16,    128, "Default"),
    # 10: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 64,    256,   64,   1,  4,  1,   16,    16,    128, "Default"),
    # 11: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 128,   64,   128,   1,  4,  1,   16,    16,    128, "Default"),
    # 12: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 128,   64,   256,   1,  4,  1,   16,    16,    128, "Default"),
    # 13: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 128,   128,   64,   1,  4,  1,   16,    16,    128, "Default"),
    # 14: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 128,   256,   128,  1,  4,  1,   16,    16,    128, "Default"),
}

default_kernels_dict_950 = {
    (-1): kernelInstance(0, 0, 8, 4, 1, 0, 0, 0, 0,1, 256,   256,   128,  1,  4,  1,   16,    16,    128, "Default"),
    # (-2):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 16,    64,    512,  1,  4,  1,   16,    16,    128, "Default"),
    # (-3):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 32,    64,    512,  1,  4,  1,   16,    16,    128, "Default"),
    # (-4):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 64,    256,   64,   1,  4,  1,   16,    16,    128, "Default"),
    # (-5):kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0,1, 128,   128,   64,   1,  4,  1,   16,    16,    128, "Default"),
}

# fmt: on

arch = get_gfx()
if arch == "gfx942":
    kernels_list = kernels_list_942
    default_kernels_dict = default_kernels_dict_942
else:
    kernels_list = kernels_list_950
    default_kernels_dict = default_kernels_dict_950