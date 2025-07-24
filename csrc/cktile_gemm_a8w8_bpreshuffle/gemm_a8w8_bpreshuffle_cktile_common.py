# SPDX-License-Identifier: MIT
# Copyright (C) 2024-2025, Advanced Micro Devices, Inc. All rights reserved.
from dataclasses import dataclass

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
        #     ("x").join(map(lambda x: str(x), [
        #         self.sTransposeC, self.sUseStructuredSparsity, self.sTileParitionerGroupNum, self.sTileParitionerM01])),
        #     ("x").join(map(lambda x: str(x), [
        #         self.sNumWaveGroups, self.sDoubleSmemBuffer])),
        #     ("x").join(map(lambda x: str(x), [
        #         self.PadM, self.PadN, self.PadK, self.BlockPerCu])),
        #     ("x").join(map(lambda x: str(x), [
        #         self.MTile, self.NTile, self.KTile])),
        #     ("x").join(map(lambda x: str(x), [
        #         self.MWarp, self.NWarp, self.KWarp])),
        #     ("x").join(map(lambda x: str(x), [
        #         self.MWTile, self.NWTile, self.KWTile])),
        #     self.sScheduler.lower(),
        # ])
# fmt: off
# kernels_list_str = '''
kernels_list = {

    0: kernelInstance( 0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   128,  1,  4,  1,   16,    16,    64, "Default")
    # 1: kernelInstance( 256,    128,   128,   256,  16,  16,  16,   16,    4,    4,    [16, 16, 1],      ),
    # 2: kernelInstance( 256,    256,   256,   128,  16,  16,  16,   16,    8,    8,    [8, 32, 1],       ),
    # 3: kernelInstance( 256,    256,   128,   128,  16,  16,  16,   16,    8,    4,    [8, 32, 1],       ),
    # 4: kernelInstance( 256,    192,   128,   128,  16,  16,  16,   16,    6,    4,    [8, 32, 1],       ),
}
# '''



default_kernels_dict = {
    (-1): kernelInstance(0, 0, 8, 4, 1, 0, 0, 0, 0, 2, 128,   128,   128,  1,  4,  1,   16,    16,    64, "Default")
}
# fmt: on