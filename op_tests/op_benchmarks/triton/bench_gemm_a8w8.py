import sys
import triton
import math
from aiter.ops.triton.gemm_a8w8 import gemm_a8w8
from aiter.ops.triton.utils.types import str_to_torch_dtype
from op_tests.triton_tests.test_gemm_a8w8 import (
    generate_gemm_a8w8_inputs,
)
from op_tests.op_benchmarks.triton.utils.argparse import get_parser, add_argparse_ff
from op_tests.op_benchmarks.triton.utils.benchmark_utils import (
    get_model_configs,
)
import warnings
import matplotlib.pyplot as plt


def model_benchmark_shapes(args):
    config_file = args.model_configs
    configs = get_model_configs(config_path=config_file, models=args.model)
    M_list = [args.M] if args.model == "all" else [2**i for i in range(0, 15)]
    shapes = []
    for M in M_list:
        for _, config in configs.items():
            shapes.append((M, config["hidden_size"], config["intermediate_size"]))

    return shapes


def get_x_vals():
    """
    Get a default set of benchmarking values (M, N, K).
    """
    x_vals = [
        (1, 1280, 8192),
        (32, 1280, 8192),
        (64, 1280, 8192),
        (128, 1280, 8192),
        (192, 1280, 8192),
        (256, 1280, 8192),
        (320, 1280, 8192),
        (512, 1280, 8192),
        (1024, 1280, 8192),
        (2048, 1280, 8192),
        (4096, 1280, 8192),
        (8192, 1280, 8192),
        (16384, 1280, 8192),
    ]
    return x_vals


def run_model_benchmark(args):
    """
    Runs benchmark given a --model argument.
    """
    x_names = ["M", "hidden_dim", "intermediate_dim"]
    if not args.fc1 and not args.fc2:
        # by default, benchmark both
        warnings.warn(
            "No specific layer selected for benchmarking, defaulting to both. To specify a layer, use -fc1 or -fc2."
        )
        args.fc1 = True
        args.fc2 = True
    x_vals_list = model_benchmark_shapes(args)

    if args.metric == "time":
        ylabel = "Time (ms)"
    elif args.metric == "throughput":
        ylabel = "Throughput (TFLOPS)"
    elif args.metric == "bandwidth":
        ylabel = "Bandwidth (GB/s)"
    else:
        raise NotImplementedError(f"{args.metric} is not supported")

    line_names = []
    if args.fc1:
        line_names.append("fc1")
    if args.fc2:
        line_names.append("fc2")
    line_vals = line_names

    mpl_colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    benchmark = triton.testing.Benchmark(
        x_names=x_names,
        x_vals=x_vals_list,
        line_arg="layer",
        line_vals=line_vals,
        line_names=line_names,
        styles=[
            (mpl_colors[i], "-") for i in range(len(line_names))
        ],  # match line names to colors
        ylabel=ylabel,
        plot_name="GEMM A8W8 Benchmark",
        args={"metric": args.metric},
    )

    @triton.testing.perf_report([benchmark])
    def bench_gemm_a8w8(M, hidden_dim, intermediate_dim, metric, layer, **kwargs):
        # NOTE: Assume bias and output has the same dtype
        c_dtype = str_to_torch_dtype["bf16"]

        """
        Fc1:
             M      K                  K           N          M       N
        A = (B, hidden_dim) @ W = (hidden_dim, 2*int_dim) -> (B, 2*int_dim) -> gating -> (B, int_dim)

        Fc2:
             M     K               K          N          M       N
        A = (B, int_dim) @ W = (int_dim, hidden_dim) -> (B, hidden_dim)

        Tensor parallel splits across int_dim (N for fc1, K for fc2)
        """
        if layer == "fc1":
            if args.no_glu:
                N, K = intermediate_dim, hidden_dim
            else:
                N, K = intermediate_dim * 2, hidden_dim
            # Divide N by tensor parallel
            N = math.ceil(N / args.tp)
        elif layer == "fc2":
            N, K = hidden_dim, intermediate_dim
            # Divide K by tensor parallel
            K = math.ceil(K / args.tp)
        # print(f"Layer: {layer}, M: {M}, N: {N}, K: {K}, hidden_dim: {hidden_dim}, intermediate_dim: {intermediate_dim}")

        x, weight, x_scale, w_scale, bias, y = generate_gemm_a8w8_inputs(
            M, N, K, str_to_torch_dtype["fp8e4m3"], c_dtype, output=True
        )
        # flops
        flops = 2.0 * M * N * K
        # memory transfer
        mem_read = (M * K) * x.element_size() + (N * K) * weight.element_size()
        mem_write = (M * N) * bias.element_size()
        mem = mem_read + mem_write

        ms = triton.testing.do_bench(
            lambda: gemm_a8w8(
                x, weight, x_scale, w_scale, bias, c_dtype, y
            ),  # noqa: E731
            warmup=25,
            rep=100,
        )

        # Return exactly one scalar depending on which metric is active
        if metric == "time":
            return ms
        elif metric == "throughput":
            tflops = flops / ms * 1e-9
            return tflops
        elif metric == "bandwidth":
            bandwidth = mem / (ms * 1e-3) * 1e-9  # GB/s
            return bandwidth
        else:
            raise ValueError("Unknown metric: " + metric)

    bench_gemm_a8w8.run(save_path=".", print_data=True)


def run_shape_benchmark(args):
    """
    Runs a benchmark with given tensor shapes.
    """
    x_names = ["M", "N", "K"]
    if args.shape:
        x_vals_list = [args.shape]
    else:
        x_vals_list = get_x_vals()

    if args.metric == "time":
        ylabel = "Time (ms)"
    elif args.metric == "throughput":
        ylabel = "Throughput (TFLOPS)"
    elif args.metric == "bandwidth":
        ylabel = "Bandwidth (GB/s)"
    else:
        raise NotImplementedError(f"{args.metric} is not supported")

    benchmark = triton.testing.Benchmark(
        x_names=x_names,
        x_vals=x_vals_list,
        line_arg="Provider",
        line_vals=["Triton"],
        line_names=["Triton"],
        styles=[("green", "-")],
        ylabel=ylabel,
        plot_name="GEMM A8W8 Benchmark",
        args={"metric": args.metric},
    )

    @triton.testing.perf_report([benchmark])
    def bench_gemm_a8w8(M, N, K, metric, **kwargs):
        # NOTE: Assume bias and output has the same dtype
        c_dtype = str_to_torch_dtype["bf16"]
        x, weight, x_scale, w_scale, bias, y = generate_gemm_a8w8_inputs(
            M, N, K, str_to_torch_dtype["fp8e4m3"], c_dtype, output=True
        )
        # Divide N by tensor parallel
        N = math.ceil(N / args.tp)

        # flops
        flops = 2.0 * M * N * K
        # memory transfer
        mem_read = (M * K) * x.element_size() + (N * K) * weight.element_size()
        mem_write = (M * N) * bias.element_size()
        mem = mem_read + mem_write

        ms = triton.testing.do_bench(
            lambda: gemm_a8w8(
                x, weight, x_scale, w_scale, bias, c_dtype, y
            ),  # noqa: E731
            warmup=25,
            rep=100,
        )

        # Return exactly one scalar depending on which metric is active
        if metric == "time":
            return ms
        elif metric == "throughput":
            tflops = flops / ms * 1e-9
            return tflops
        elif metric == "bandwidth":
            bandwidth = mem / (ms * 1e-3) * 1e-9  # GB/s
            return bandwidth
        else:
            raise ValueError("Unknown metric: " + metric)

    bench_gemm_a8w8.run(save_path=".", print_data=True)


def run_benchmark(args, defaults):
    assert not (args.shape and args.model) or not (
        args.shape and args.M
    ), "User can specify --shape or --model MODEL -M VAL exclusively"
    if args.model:
        unsupported_args = [
            "layout",
        ]
        for arg in unsupported_args:
            if getattr(args, arg, None) != getattr(defaults, arg, None):
                raise Exception(
                    f"Argument '{arg}' is not supported for benchmarking with the --model flag."
                )
        run_model_benchmark(args)
    else:
        unsupported_args = [
            "fc1",
            "fc2",
            "no_glu",
        ]
        for arg in unsupported_args:
            if getattr(args, arg, None) != getattr(defaults, arg, None):
                raise Exception(
                    f"Argument '{arg}' is not supported for benchmarking without the --model flag."
                )
        run_shape_benchmark(args)


def parse_args():
    parser = get_parser(kernel_name="A8W8 GEMM")
    parser = add_argparse_ff(parser)
    args = parser.parse_args()
    defaults = parser.parse_args([])  # get default arguments
    return args, defaults


def main():
    args, defaults = parse_args()
    run_benchmark(args, defaults)


if __name__ == "__main__":
    sys.exit(main())
