import sys
import os
from pathlib import Path
import logging
import argparse
import itertools
import subprocess
import torch
import triton
import time
import csv
import json
import pandas as pd
from rpdTracerControl import rpdTracerControl
from aiter.ops.triton.gemm_a16w16 import gemm_a16w16
from op_tests.triton_tests.test_gemm_a16w16 import generate_gemm_a16w16_inputs


class gemm_op:
    module_base_path = "aiter.ops.triton"
    test_base_path = "op_tests.triton_tests"
    output_base_path = "output"

    def __init__(self, name, op_module_file, op_func, input_module_file, input_func):
        self.name = name
        self.module_import_path = self.module_base_path + "." + op_module_file
        self.func = op_func
        self.input_import_path = self.test_base_path + "." + input_module_file
        self.input_func = input_func
        self.elemBytes_a = 2
        self.elemBytes_b = 2
        self.best_configs = {}
        self.device = ""

        parent_path = Path("__file__").parent
        driver_file_dir = os.path.join(parent_path, f"{self.output_base_path}/{self.name}/")
        os.makedirs(driver_file_dir, exist_ok=True) 
        self.driver_file_path = os.path.join(driver_file_dir, "driver.py")

        profile_file_dir = os.path.join(parent_path, f"{self.output_base_path}/{self.name}/")
        os.makedirs(profile_file_dir, exist_ok=True) 
        self.profile_file_path = os.path.join(profile_file_dir, "profile")

        self.output_json_config_path = os.path.join(parent_path, f"{self.output_base_path}/{self.name}/{self.device}-{self.name}.json")

        self._determine_full_tuning_space()

    def __str__(self):
        return f"{self.name} {self.module_import_path} {self.input_import_path}"

    def set_device(self, device):
        self.device = device
        parent_path = Path("__file__").parent
        self.output_json_config_path = os.path.join(parent_path, f"{self.output_base_path}/{self.name}/{self.device}-{self.name}.json")
    
    #configs
    def _determine_full_tuning_space(self):
        configs = []

        block_mn_range = [16, 32, 64, 128, 256]
        block_k_range = [16, 32, 64, 128, 256]
        #split_k_range = [1, 2, 4, 5, 6, 8, 10, 12, 16, 18, 24]
        num_warps_range = [1, 2, 4, 8]
        group_m_range = [1, 2, 4, 8, 16, 32]
        # For now we see better perf with num_stages=2 for all gemm configs we care
        # But keep this explicit so that we do not forget we may need to set it to
        # other values in the future
        num_stage_range = [2]
        waves_per_eu_range = [0]
        matrix_instr_nonkdim_range = [16, 32]
        cache_modifier = [""]

        space = itertools.product(block_mn_range, block_mn_range, block_k_range, num_warps_range, group_m_range,
                                num_stage_range, waves_per_eu_range, matrix_instr_nonkdim_range, cache_modifier)

        for instance in space:
            block_m, block_n, block_k, num_warps, group_m, num_stages, waves_per_eu, matrix_instr_nonkdim, cache_modifier = instance
            configs.append({
                'BLOCK_SIZE_M': block_m, 'BLOCK_SIZE_N': block_n, 'BLOCK_SIZE_K': block_k, 'GROUP_SIZE_M': group_m,
                'num_warps': num_warps, 'num_stages': num_stages, 'waves_per_eu': waves_per_eu,
                'matrix_instr_nonkdim': matrix_instr_nonkdim, 'cache_modifier': cache_modifier})

        self.configs = configs

    def _prune_configs(self, M, N, K):
        pruned_configs = []

        if M < 32 or N < 32:
            mfma = 16
        else:
            mfma = 32

        large_gemm = False
        if M >= 2048 and N >= 2048:
            large_gemm = True

        for config in self.configs:
            BLOCK_SIZE_M = config.get("BLOCK_SIZE_M")
            BLOCK_SIZE_N = config.get("BLOCK_SIZE_N")
            BLOCK_SIZE_K = config.get("BLOCK_SIZE_K")
            num_warps = config.get("num_warps")
            num_stages = config.get("num_stages")
            matrix_instr_nonkdim = config.get("matrix_instr_nonkdim")
            
            if matrix_instr_nonkdim > mfma:
                continue
            
            if mfma == 4 and BLOCK_SIZE_K < 64:
                continue
            
            # some layouts could not work properly in case
            # number elemens per thread is less 1
            if BLOCK_SIZE_M * BLOCK_SIZE_N < 64:
                continue
            
            #SPLIT_K = config.get("SPLIT_K")
            GROUP_M = config.get("GROUP_SIZE_M")
            if BLOCK_SIZE_M < matrix_instr_nonkdim or BLOCK_SIZE_N < matrix_instr_nonkdim:
                continue
            if M <= matrix_instr_nonkdim and BLOCK_SIZE_M != matrix_instr_nonkdim:
                continue
            if N <= matrix_instr_nonkdim and BLOCK_SIZE_N != matrix_instr_nonkdim:
                continue
            
            # Skip BLOCK_SIZE that is too large compare to M/N
            # unless BLOCK_SIZE is already small enough
            if BLOCK_SIZE_M > M * 2 and BLOCK_SIZE_M != 16:
                continue
            if BLOCK_SIZE_N > N * 2 and BLOCK_SIZE_N != 16:
                continue
            
            # skip large GROUP_M
            if GROUP_M * BLOCK_SIZE_M > M and GROUP_M != 1:
                continue
            
            # out of shared memory resource
            LDSA = BLOCK_SIZE_K * BLOCK_SIZE_M * self.elemBytes_a
            LDSB = BLOCK_SIZE_K * BLOCK_SIZE_N * self.elemBytes_b
            if num_stages <= 1:
                # No pipeline, buffer A and buffer B can re-use each other
                LDS = max(LDSA, LDSB)
            else:
                # Pipeline, we need (num_stages - 1) buffers for both A and B at the same time
                LDS = (LDSA + LDSB) * (num_stages - 1)
            driver = triton.runtime.driver.active
            max_shared = driver.utils.get_device_properties(driver.get_current_device())["max_shared_mem"]
            if LDS > max_shared:
                continue
            
            # Skip small block sizes and num_warps for large gemm
            # For fp16 and f8, we want to only use BLOCK_SIZE >= 64
            if large_gemm:
                if BLOCK_SIZE_M < 64 or BLOCK_SIZE_N < 64:
                    continue
                if BLOCK_SIZE_K < 64:
                    continue
                if num_warps < 4:
                    continue
                # check if tiling is integer multiple of GEMM size because we have no boundary check
                if M % BLOCK_SIZE_M != 0 or N % BLOCK_SIZE_N != 0:
                    continue

            pruned_configs.append(config)

        return pruned_configs

    def _generate_driver_file(self,shape, cfg, num_runs=10):
        self.num_runs = num_runs
        M, N, K, layout = shape
        driver_file_str = f"""
import torch
import triton

from {self.module_import_path} import {self.func} 
from {self.input_import_path} import {self.input_func}

x, w, out_dtype, y = {self.input_func}({M}, {N}, {K}, torch.bfloat16, layout="{layout}", output=True)
for i in range({num_runs}):
    {self.func}(x, w, out_dtype, y, {cfg})
"""
        #print(f"driver_file_str={driver_file_str}")
        with open(self.driver_file_path, "w") as file:
            file.write(driver_file_str)
            file.close()

    def profile_op(self, shapes):
        best_configs = {}
        for shape in shapes:
            (M, N, K, layout) = shape
            shape_str = [str(e) for e in shape]
            shape_str = "-".join(shape_str)
            configs = self._prune_configs(M, N, K)
            print(f"SHAPE={shape} configs_full={len(self.configs)} pruned_configs={len(configs)}")

            best_cfg = ""
            best_avg_time = 10e7
            for cfg in configs:
                self._generate_driver_file(shape, cfg)
                run_bash_command(
                    f"PYTHONPATH=. rocprofv3 --kernel-trace -o {self.profile_file_path} --log-level fatal -- python {self.driver_file_path}") 
        
                #Read kernel stats
                df = pd.read_csv(f"{self.profile_file_path}_kernel_trace.csv")
                df.loc[:, 'Execution_Time'] = df['End_Timestamp'] - df['Start_Timestamp']
                avg_time = (df['Execution_Time'].sum()) / self.num_runs

                print(f"{cfg} avg_time={avg_time}")
                if avg_time < best_avg_time:
                    best_cfg, best_avg_time = cfg, avg_time
                
            print(f"SHAPE={shape_str} BEST_CFG={best_cfg} best_avg_time={best_avg_time}")
            best_configs[shape_str] = best_cfg

        print(f"best_config={best_configs}")
        with open(self.output_json_config_path, "w") as file:
            config_str = json.dumps(best_configs, indent=4)
            file.write(config_str)
            file.close()


class gemm_a8w8(gemm_op):
    #configs
    def _determine_full_tuning_space(self):
        configs = []

        block_mn_range = [16, 32, 64, 128, 256]
        block_k_range = [16, 32, 64, 128, 256]
        #split_k_range = [1, 2, 4, 5, 6, 8, 10, 12, 16, 18, 24]
        num_warps_range = [1, 2, 4, 8]
        group_m_range = [1, 2, 4, 8, 16, 32]
        # For now we see better perf with num_stages=2 for all gemm configs we care
        # But keep this explicit so that we do not forget we may need to set it to
        # other values in the future
        num_stage_range = [2]
        waves_per_eu_range = [0]
        matrix_instr_nonkdim_range = [16, 32]

        space = itertools.product(block_mn_range, block_mn_range, block_k_range, num_warps_range, group_m_range,
                                num_stage_range, waves_per_eu_range, matrix_instr_nonkdim_range)

        for instance in space:
            block_m, block_n, block_k, num_warps, group_m, num_stages, waves_per_eu, matrix_instr_nonkdim = instance
            configs.append({
                'BLOCK_SIZE_M': block_m, 'BLOCK_SIZE_N': block_n, 'BLOCK_SIZE_K': block_k, 'GROUP_SIZE_M': group_m,
                'num_warps': num_warps, 'num_stages': num_stages, 'waves_per_eu': waves_per_eu,
                'matrix_instr_nonkdim': matrix_instr_nonkdim})

        self.configs = configs

    def _generate_driver_file(self,shape, cfg, num_runs=10):
        self.num_runs = num_runs
        M, N, K, layout = shape
        driver_file_str = f"""
import torch
import triton

from {self.module_import_path} import {self.func} 
from {self.input_import_path} import {self.input_func}

x, weight, x_scale, w_scale, bias, y = {self.input_func}({M}, {N}, {K}, torch.float8_e4m3fnuz, torch.bfloat16, layout="{layout}", output=True)
for i in range({num_runs}):
    {self.func}(x, weight, x_scale, w_scale, bias, torch.bfloat16, y, {cfg}) 
"""
        #print(f"driver_file_str={driver_file_str}")
        with open(self.driver_file_path, "w") as file:
            file.write(driver_file_str)
            file.close()


OPS = {
    "gemm_a16w16": gemm_op("gemm_a16w16", "gemm_a16w16", "gemm_a16w16", "test_gemm_a16w16", "generate_gemm_a16w16_inputs"),
    "gemm_a8w8": gemm_a8w8("gemm_a8w8", "gemm_a8w8", "gemm_a8w8", "test_gemm_a8w8", "generate_gemm_a8w8_inputs"),
}

def run_bash_command(commandstring, capture=True):
    if capture:
        print(f"{commandstring}")
        proc = subprocess.run(commandstring, shell=True, check=True, executable='/bin/bash', stdout=subprocess.PIPE)
        return proc.stdout.splitlines()
    proc = subprocess.run(commandstring, shell=True, check=True, executable='/bin/bash')
    return None

def get_device():
    arch = run_bash_command("rocm_agent_enumerator")
    arch = [str(a) for a in arch]
    if "gfx950" in arch[0]:
        device = "MI35X"
    elif "gfx942" in arch[0]:
        device = "MI300"
    else:
        print(arch)
        raise "Unknown architecture"
    
    return device

def get_shapes(args):
    BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "."))
    if args.M != 0 and args.N !=0 and args.K !=0:
        return [(args.M, args.N, args.K, args.layout)]
    else:
        config_path = os.path.join(os.path.dirname(__file__), args.shapes_file)
        print(f"config_path={config_path}")
        shapes = []
        with open(config_path, "r") as f:
            configs = json.load(f)
            for model, variants in configs.items():
                for params, config in variants.items():
                    print(f"{model}_{params}: {config}")
                    shapes.append((args.M, config["intermediate_size"], config["hidden_size"], args.layout))
                    shapes.append((args.M, config["intermediate_size"] // 2, config["hidden_size"], args.layout))
                    shapes.append((args.M, config["hidden_size"], config["intermediate_size"], args.layout))
                    shapes.append((args.M, config["hidden_size"], config["intermediate_size"] // 2, args.layout))

        return shapes

def get_op(args):
    print(OPS.keys())
    if args.op not in OPS.keys():
        raise ValueError(f"{args.op} is not valid.")
    
    return OPS[args.op]

#arg parser
def parse_args():
    parser = argparse.ArgumentParser(description="Tune AITER Triton GEMM Kernels")

    parser.add_argument("-M", type=int, default=0)
    parser.add_argument("-N", type=int, default=0)
    parser.add_argument("-K", type=int, default=0)
    parser.add_argument("-layout", type=str,choices=["TT", "TN", "NT", "NN"], default='TN')
    parser.add_argument("-op", type=str, default='gemm_a16w16')
    parser.add_argument("-shapes_file", type=str, default="model_configs.json", help='JSON with GEMM shapes to tune')

    args = parser.parse_args()

    return args

def main():
    args = parse_args()
    op = get_op(args)
    print(f"{op}")

    device = get_device()
    print(f"{device}")
    
    shapes = get_shapes(args)
    print(f"{shapes}")

    run_bash_command("rm -rf ~/.triton/cache")

    op.set_device(device)
    op.profile_op(shapes)

#main
if __name__ == "__main__":
    sys.exit(main())