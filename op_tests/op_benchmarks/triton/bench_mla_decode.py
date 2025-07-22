import triton

from op_tests.op_benchmarks.triton.utils.benchmark_utils import (
    get_model_configs,
    get_available_models,
    print_vgpr,
)
from op_tests.triton_tests.utils.rotary_embedding import DeepseekScalingRotaryEmbedding
from aiter.ops.triton.mla_decode_rope import decode_attention_fwd_grouped_rope
import torch
import argparse


def is_hip():
    return triton.runtime.driver.active.get_current_target().backend == "hip"


is_hip_ = is_hip()


def input_helper(
    B,
    H,
    S,
    kv_lora_rank,
    rotary_dim,
    qk_rope_head_dim,
    num_kv_splits,
    dtype,
    device,
    rope_base=10,
    rope_max_seq_len=16324,
    rope_scaling=1.0,
    equal_seqlens=False,
    is_neox_style=True,
):
    if not equal_seqlens:
        seqlens = torch.randint(1, S + 1, (B,), dtype=torch.int32, device=device)
    else:
        seqlens = torch.full((B,), S, dtype=torch.int32, device=device)

    cu_seqlens = torch.cat(
        [
            torch.tensor([0], dtype=torch.int32),
            seqlens.cumsum(dim=0, dtype=torch.int32),
        ]
    )

    total_seqlen = cu_seqlens[-1]

    q = torch.randn(B, H, kv_lora_rank + qk_rope_head_dim, dtype=dtype, device=device)
    kv_cache = torch.randn(
        total_seqlen, kv_lora_rank + qk_rope_head_dim, dtype=dtype, device=device
    )

    # interlancing [batch_start_off, batch_seq_len, batch_start_off, batch_seq_len, ...,]
    kv_indptr = cu_seqlens
    kv_indices = torch.arange(total_seqlen, device=device)

    attn_logits = torch.empty(
        B, H, num_kv_splits, kv_lora_rank + 1, dtype=dtype, device=device
    )

    rotary_emb = DeepseekScalingRotaryEmbedding(
        qk_rope_head_dim,
        rotary_dim,
        rope_max_seq_len,
        rope_base,
        is_neox_style,
        rope_scaling,
        q.dtype,
        device=device,
    )

    positions = (
        torch.tensor([S], device=device).unsqueeze(0).repeat(B, 1)
    )  # k positions and q position as last

    o = torch.empty(B, H, kv_lora_rank, dtype=dtype, device=device)

    return kv_indptr, kv_indices, q, kv_cache, attn_logits, rotary_emb, positions, o


def ref_preprocess(kv_cache, kv_lora_rank):
    latent_cache = kv_cache
    v_input = latent_cache[..., :kv_lora_rank]
    v_input = v_input.contiguous().unsqueeze(1)
    k_input = latent_cache.unsqueeze(1)
    k_input[..., :kv_lora_rank] = v_input
    return k_input, v_input


def model_benchmark_configs(args):
    config_file = args.model_configs
    # Only deepseek models are supported for this benchmark.
    if args.model == "all":
        configs = get_model_configs(config_path=config_file, models="deepseek")
    else:
        assert (
            "deepseek" in args.model
        ), "Only deepseek models are supported for this benchmark."
        configs = get_model_configs(config_path=config_file, models=args.model)

    batch_size = args.b if args.b else 1

    x_names = [
        "model",
        "B",
        "H",
        "S",
        "kv_lora_rank",
        "qk_rope_head_dim",
        "rotary_dim",
        "num_kv_splits",
    ]

    x_vals_list = []

    for model_name, config in configs.items():
        H = config["num_attention_heads"] // 8  # tp8
        S = args.seqlen
        # attn_impl = args.attn_impl if args.attn_impl else "non-absorb"
        x_vals_list.append((model_name, batch_size, H, S, 512, 64, 64, 32))

    return x_names, x_vals_list


def benchmark(args):
    dtype = arg_to_torch_dtype[args.dtype]
    torch.set_default_dtype(dtype)

    configs = []

    if args.model:
        x_names, x_vals_list = model_benchmark_configs(args)

    line_vals = ["mla_decode_fwd"]

    plot_name = args.plot_name + "mla_decode"

    configs.append(
        triton.testing.Benchmark(
            x_names=x_names,
            x_vals=x_vals_list,
            line_arg="provider",
            line_vals=line_vals,
            line_names=line_vals,
            styles=[("red", "-"), ("green", "-")],
            ylabel="ms",
            plot_name=plot_name,
            args={"sm_scale": 1.0, "logit_cap": 0.0, "device": args.device},
        )
    )

    @triton.testing.perf_report(configs)
    def bench_MLA(
        B,
        H,
        S,
        kv_lora_rank,
        qk_rope_head_dim,
        rotary_dim,
        num_kv_splits,
        sm_scale,
        logit_cap,
        device,
        provider=None,
        model=None,
    ):
        warmup = 25
        rep = 100
        is_neox_style = True

        k_pe_tokens = torch.empty(B, qk_rope_head_dim, dtype=dtype, device=device)

        kv_indptr, kv_indices, q, kv_cache, attn_logits, rotary_emb, positions, o = (
            input_helper(
                B,
                H,
                S,
                kv_lora_rank,
                rotary_dim,
                qk_rope_head_dim,
                num_kv_splits,
                dtype,
                device,
                is_neox_style=is_neox_style,
                equal_seqlens=args.equal_seqlens,
            )
        )
        k_input, v_input = ref_preprocess(kv_cache, kv_lora_rank)

        def fn():
            return decode_attention_fwd_grouped_rope(
                q,
                k_input,
                v_input,
                o,
                kv_indptr,
                kv_indices,
                k_pe_tokens,
                kv_lora_rank,
                rotary_dim,
                rotary_emb.cos_sin_cache,
                positions,
                attn_logits,
                num_kv_splits,
                sm_scale,
                logit_cap,
                args.use_rope,
                is_neox_style,
            )

        ms = triton.testing.do_bench(fn, warmup=warmup, rep=rep)

        return ms

    bench_MLA.run(save_path="." if args.o else None, print_data=True, show_plots=False)
    return x_vals_list, x_names, line_vals


arg_to_torch_dtype = {
    "fp16": torch.float16,
    "bf16": torch.bfloat16,
    "fp32": torch.float32,
}


def parse_args():
    parser = argparse.ArgumentParser(
        prog="Benchmark MLA Prefill",
        allow_abbrev=False,
    )
    parser.add_argument(
        "--model_configs",
        type=str,
        default="utils/model_configs.json",
        help="Model config json file.",
    )
    available_models = get_available_models(
        filter="deepseek"
    )  # Dynamically load model names
    model_help = (
        "Model name to benchmark. Select from: ["
        + ", ".join(available_models)
        + "]. Use 'all' to benchmark all models. Provide model family (the part before -) to benchmark all models in that family. One can provide multiple as --model \"llama3,mistral_7B\""
    )
    parser.add_argument(
        "--plot_name",
        type=str,
        default="MLA-prefill",
        help="Name for the results plot|table",
    )
    parser.add_argument("--model", type=str, default="", help=model_help)
    parser.add_argument("-b", type=int, default=0, help="Batch size")
    parser.add_argument("--seqlen", type=int, default=0, help="Sequence length")
    parser.add_argument(
        "-equal_seqlens",
        action="store_true",
        default=False,
        help="Equal sequence lengths, i.e. total (prefix|extend) tokens = B * (prefix|extend). Otherwise we have randint(1, (prefix|extend), (B,)) as sequence lengths.",
    )
    parser.add_argument("--dtype", default="bf16")
    parser.add_argument("--device", default="cuda")
    parser.add_argument(
        "-print_vgpr",
        action="store_true",
        default=False,
        help="Prints the VGPR usage of the compiled triton kernel.",
    )
    parser.add_argument("-causal", action="store_true", default=False)
    parser.add_argument("-use_rope", action="store_true", default=False)
    parser.add_argument(
        "-o",
        action="store_true",
        default=False,
        help="Write performance results to CSV file",
    )
    return parser.parse_args()


arg_to_torch_dtype = {
    "fp16": torch.float16,
    "bf16": torch.bfloat16,
    "fp32": torch.float32,
}


def run_bench(args):
    torch.manual_seed(0)
    torch.set_default_device(args.device)
    benchmark(args)


def main():
    args = parse_args()
    if args.print_vgpr:  # print the vgpr usage of the kernel
        print_vgpr(lambda: run_bench(args), table_start=args.plot_name)
        return 0
    run_bench(args)


if __name__ == "__main__":
    main()
