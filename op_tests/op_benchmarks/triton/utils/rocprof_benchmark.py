import subprocess
import os
import pandas as pd
from prettytable import PrettyTable

def run_profiling(run_command, output_file):
    # Split the run_command string and expand ~ in the path
    command_parts = run_command.split()
    for i, part in enumerate(command_parts):
        if part.startswith('~/'):
            command_parts[i] = os.path.expanduser(part)
    # Use rocprofv2 instead of rocprof
    command = ["rocprof", "--stats", "-o", output_file] + command_parts
    print("Running command:", command)  # Debug output
    subprocess.run(command, check=True)

def parse_profiling_output(output_file, kernel_names):
    try:
        df = pd.read_csv(output_file)
    except (pd.errors.EmptyDataError, FileNotFoundError) as e:
        print(f"Error reading {output_file}: {e}")
        return {kernel: None for kernel in kernel_names + ['other_kernels_sum']}
    results = {}
    for kernel in kernel_names:
        kernel_data = df[df['Name'].str.strip('"') == kernel]
        if not kernel_data.empty:
            results[kernel] = kernel_data['AverageNs'].iloc[0] / 1000.0
        else:
            results[kernel] = None
    
    # Calculate sum of other kernels
    other_kernels = df[~df['Name'].str.strip('"').isin(kernel_names)]
    other_kernels_sum = other_kernels['AverageNs'].sum() / 1000.0
    results['other_kernels_sum'] = other_kernels_sum
    
    return results

def main():
    output_file = "profiling_output.csv"
    kernel_names = ["_gemm_afp4_wfp4_kernel.kd", "_gemm_afp4_wfp4_reduce_kernel.kd"]
    shapes = [(2**i, 53248, 16384) for i in range(11)]

    results = {}
    for shape in shapes:
        command = f"python ~/aiter/op_tests/op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape {shape[0]} {shape[1]} {shape[2]}"
        run_profiling(command, output_file)
        kernel_results = parse_profiling_output(output_file.replace(".csv", ".stats.csv"), kernel_names)
        results[f"{shape[0]} {shape[1]} {shape[2]}"] = kernel_results
    
    table = PrettyTable()
    table.field_names = ["M | N | K"] + kernel_names + ["Other Kernels Sum (µs)"]
    for shape in shapes:
        row = [f"{shape[0]} {shape[1]} {shape[2]}"] + [results[f"{shape[0]} {shape[1]} {shape[2]}"].get(kernel, "N/A") for kernel in kernel_names] + [results[f"{shape[0]} {shape[1]} {shape[2]}"].get('other_kernels_sum', "N/A")]
        table.add_row(row)
    
    print("\nProfiling Summary (in microseconds):")
    print(table)

if __name__ == "__main__":
    main()