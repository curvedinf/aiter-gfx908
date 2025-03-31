
import triton
import triton.language as tl
from utils.benchmark_utils import get_model_configs, get_available_models
import torch
from aiter.ops.triton.mha import flash_attn_varlen_func
import sys


def mha_input_helper(Z, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, is_varlen=False, layout="thd"):
    torch.manual_seed(20)
    assert layout in ["thd"], f"mha only supports thd layout. Invalid layout: {layout}"

    # Random sequence lengths. Using N_CTX * Z as kind of maximum possible sum of individual seqs
    if is_varlen:
        max_seqlens_q = N_CTX_Q
        max_seqlens_k = N_CTX_K
        if N_CTX_Q == N_CTX_K:
            seqlens_q = torch.randint(1, max_seqlens_q + 1, (Z, ), dtype=torch.int32)
            seqlens_k = seqlens_q
        else:
            seqlens_q = torch.randint(1, max_seqlens_q + 1, (Z, ), dtype=torch.int32)
            seqlens_k = torch.randint(1, max_seqlens_k + 1, (Z, ), dtype=torch.int32)
    else:
        seqlens_q = torch.full((Z, ), N_CTX_Q)
        seqlens_k = torch.full((Z, ), N_CTX_K)

    # Calculate cumulative sequence lengths
    cu_seqlens_q = torch.cat([torch.tensor([0], dtype=torch.int32), seqlens_q.cumsum(dim=0, dtype=torch.int32)])
    cu_seqlens_k = torch.cat([torch.tensor([0], dtype=torch.int32), seqlens_k.cumsum(dim=0, dtype=torch.int32)])

    cu_seqlens_q = cu_seqlens_q.to(device="cuda")
    cu_seqlens_k = cu_seqlens_k.to(device="cuda")
    # Initialize q, k, v with variable lengths
    total_q = cu_seqlens_q[-1].item()
    total_k = cu_seqlens_k[-1].item()

    q = torch.randn((total_q, HQ, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    k = torch.randn((total_k, HK, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    v = torch.randn((total_k, HK, D_HEAD), dtype=dtype, device="cuda").normal_(mean=0., std=0.5).requires_grad_()
    sm_scale = D_HEAD**-0.5
    return q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale


def model_benchmark_configs(args):
    config_file = args.model_configs
    configs = get_model_configs(config_path=config_file, models=args.model)
    fa_configs = []
    batch_size = args.b if args.b else 1

    for model_name, config in configs.items():
        HQ = config["num_attention_heads"]
        HK = HQ if config["num_key_value_heads"] is None else config["num_key_value_heads"]
        N_CTX_Q = args.sq if args.sq else 8192
        N_CTX_K = args.sk if args.sk else N_CTX_Q
        HEAD_DIM = config["hidden_size"] // HQ
        fa_configs.append((model_name, batch_size, HQ, HK, N_CTX_Q, N_CTX_K, HEAD_DIM))

    return fa_configs

def test_correctness(custom, args):
    dtype = arg_to_torch_dtype[args.dtype]
    hk = args.hq if not args.hk else args.hk
    sk = args.sq if not args.sk else args.sk
    head_size = 128 if not args.d else args.d
    mode = 'fwd'
    x_names = ['BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K']
    causal = args.causal if not args.model else True
    int8 = args.int8
    quantize_p = args.quantize_p and int8
    int8_kv = args.int8_kv and int8

    assert not (args.bench_torch and args.varlen), "Torch sdpa does not support variable sequence lengths."

    if custom:
        x_vals_list = [(args.b, args.hq, hk, args.sq, sk)]
    else:
        x_vals_list = model_benchmark_configs(args)
        x_names = ['model', 'BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K', 'D_HEAD']


    def bench_flash_attention(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, causal, mode, provider, device="cuda",
                              model=None):
        assert mode in ["fwd", "bwd"]
        assert not (int8_kv and quantize_p)

        # Bwd pass only supports causal=True right now
        if mode == 'bwd':
            causal = True

        assert args.layout in supported_layouts(), f"Layout {args.layout} not supported. Supported layouts: {supported_layouts()}"
        q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale = mha_input_helper(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype,
                                                        is_varlen=args.varlen, layout=args.layout)

        if "Torch" in provider:
            assert not args.varlen, "Torch sdpa does not support variable sequence lengths"
            q = q.view(BATCH, N_CTX_Q, HQ, D_HEAD).transpose(1, 2)
            k = k.view(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            v = v.view(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            if HQ != HK:  # TODO: sdpa(..., enable_gqa=True) works but gives very bad perf
                k = k.repeat_interleave(q.size(-3) // k.size(-3), -3)
                v = v.repeat_interleave(q.size(-3) // v.size(-3), -3)
            fn = lambda: torch.nn.functional.scaled_dot_product_attention(
                q, k, v, attn_mask=None, dropout_p=0.0, is_causal=causal, scale=sm_scale)
        else:
            o = torch.empty_like(q)
            fn = lambda: flash_attn_varlen_func(q, k, v, cu_seqlens_q, cu_seqlens_k,
                                                N_CTX_Q, N_CTX_K, dropout_p=0.0, softmax_scale=sm_scale,
                                                causal=causal, window_size=(-1, -1), alibi_slopes=None, deterministic=False,
                                                return_lse=False, return_attn_probs=False)
            if mode == 'bwd':
                o, _ = fn()
                do = torch.randn_like(o)
                fn = lambda: o.backward(do, retain_graph=True)

        return fn()

    # Test correctness of the triton kernel by comparing the output to the torch sdpa output
    for config in x_vals_list:
        # Build a dictionary from x_names and config values, and add D_HEAD
        cfg = {name: value for name, value in zip(x_names, config)}
        cfg["D_HEAD"] = head_size  # head size computed above

        # Run benchmark with Triton provider
        triton_result = bench_flash_attention(
            **cfg,
            dtype=dtype,
            causal=causal,
            mode=mode,
            provider="Triton"
        )
        triton_result = triton_result[0]
        print("triton_result.shape", triton_result.shape)

        # Run benchmark with Torch provider
        torch_result = bench_flash_attention(
            **cfg,
            dtype=dtype,
            causal=causal,
            mode=mode,
            provider="Torch"
        )

        torch_result = torch_result.transpose(1,2).flatten(0,1) # Triton kernel flattens batch and sequence length dims

        # Check that the results are close
        torch.testing.assert_close(triton_result, torch_result, rtol=2e-2, atol=2e-2)
        print(f"Results are close for config: {cfg} for triton kernel and torch.sdpa!")



def run_benchmark(custom, args):

    dtype = arg_to_torch_dtype[args.dtype]
    hk = args.hq if not args.hk else args.hk
    sk = args.sq if not args.sk else args.sk
    head_size = 128 if not args.d else args.d
    mode = 'fwd'
    x_names = ['BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K']
    causal = args.causal if not args.model else True
    int8 = args.int8
    quantize_p = args.quantize_p and int8
    int8_kv = args.int8_kv and int8

    assert not (args.bench_torch and args.varlen), "Torch sdpa does not support variable sequence lengths"

    configs = []
    plot_name = f'fused-attention-{mode}-d{head_size}-layout{args.layout}'
    extra_args = {'D_HEAD': head_size, 'dtype': dtype, 'causal': causal, 'mode': mode}
    if custom:
        x_vals_list = [(args.b, args.hq, hk, args.sq, sk)]
    else:
        x_vals_list = model_benchmark_configs(args)
        x_names = ['model', 'BATCH', 'HQ', 'HK', 'N_CTX_Q', 'N_CTX_K', 'D_HEAD']
        plot_name = f'fused-attention-{mode}-layout{args.layout}'
        extra_args = {'dtype': dtype, 'causal': causal, 'mode': mode}

    print_time = args.return_time

    if args.bench_torch:
        unit = 'ms' if print_time else 'TFLOPS'
        line_vals = [f'Triton ({unit})', f'Torch ({unit})']
    else:
        line_vals = ['Time (ms)' if print_time else 'TFLOPS']

    configs.append(
        triton.testing.Benchmark(x_names=x_names, x_vals=x_vals_list, line_arg='provider', line_vals=line_vals,
                                 line_names=line_vals, styles=[('green', '-'), ('red', '-')],
                                 ylabel='Time (ms)' if print_time else 'TFLOPS', plot_name=plot_name, args=extra_args))

    @triton.testing.perf_report(configs)
    def bench_flash_attention(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype, causal, mode, provider, device="cuda",
                              model=None):
        assert mode in ["fwd", "bwd"]
        assert not (int8_kv and quantize_p)
        warmup = 25
        rep = 100

        # Bwd pass only supports causal=True right now
        if mode == 'bwd':
            causal = True

        flops_per_matmul = 0

        assert args.layout=="thd" or not args.varlen, "Only thd layout supported for variable sequence lengths"
        assert args.layout in supported_layouts(), f"Layout {args.layout} not supported. Supported layouts: {supported_layouts()}"
        q, k, v, cu_seqlens_q, cu_seqlens_k, sm_scale = mha_input_helper(BATCH, HQ, HK, N_CTX_Q, N_CTX_K, D_HEAD, dtype,
                                                        is_varlen=args.varlen, layout=args.layout)

        if args.varlen:
            num_contexts = len(cu_seqlens_q) - 1
            for i in range(0, num_contexts):
                seqlen_q = (cu_seqlens_q[i + 1] - cu_seqlens_q[i]).item()
                seqlen_k = (cu_seqlens_k[i + 1] - cu_seqlens_k[i]).item()
                # x2 in both cases for 2 GEMMs
                if causal:
                    valid_out_elements = ((seqlen_k**2 + seqlen_k) / 2) if seqlen_q > seqlen_k else \
                            (seqlen_q * seqlen_k - ((seqlen_q**2 - seqlen_q) / 2))
                    flops_per_matmul += valid_out_elements * HQ * D_HEAD * 2
                else:
                    flops_per_matmul += seqlen_q * seqlen_k * HQ * D_HEAD * 2
        else: # Fixed sequence length
            if causal:
                valid_out_elements = ((N_CTX_K**2 + N_CTX_K) / 2) if N_CTX_Q > N_CTX_K else \
                        (N_CTX_Q * N_CTX_K - ((N_CTX_Q**2 - N_CTX_Q) / 2))
                flops_per_matmul = valid_out_elements * HQ * D_HEAD * 2
            else:
                flops_per_matmul = N_CTX_Q * N_CTX_K * HQ * D_HEAD * 2


        if "Torch" in provider:
            assert not args.varlen, "Torch sdpa does not support variable sequence lengths"
            q = q.reshape(BATCH, N_CTX_Q, HQ, D_HEAD).transpose(1, 2)
            k = k.reshape(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            v = v.reshape(BATCH, N_CTX_K, HK, D_HEAD).transpose(1, 2)
            if HQ != HK:  # TODO: sdpa(..., enable_gqa=True) works but gives very bad perf
                k = k.repeat_interleave(q.size(-3) // k.size(-3), -3)
                v = v.repeat_interleave(q.size(-3) // v.size(-3), -3)
            fn = lambda: torch.nn.functional.scaled_dot_product_attention(
                q, k, v, attn_mask=None, dropout_p=0.0, is_causal=causal, scale=sm_scale)
        else:
            o = torch.empty_like(q)
            # _flash_attn_forward uses is_varlen = cu_seqlens_q is not None
            fn = lambda: flash_attn_varlen_func(q, k, v, cu_seqlens_q, cu_seqlens_k,
                                                N_CTX_Q, N_CTX_K, dropout_p=0.0, softmax_scale=sm_scale,
                                                causal=causal, window_size=(-1, -1), alibi_slopes=None, deterministic=False,
                                                return_lse=False, return_attn_probs=False)
            if mode == 'bwd':
                o, _ = fn()
                do = torch.randn_like(o)
                fn = lambda: o.backward(do, retain_graph=True)

        ms = triton.testing.do_bench(fn, warmup=warmup, rep=rep)
        total_flops = 2 * flops_per_matmul
        if mode == "bwd":
            total_flops *= 2.5  # 2.0(bwd) + 0.5(recompute)
        if print_time:
            return ms
        else:
            return total_flops / ms * 1e-9

    bench_flash_attention.run(save_path=".", print_data=True, show_plots=True)


def supported_layouts():
    layouts = \
        'thd: Q, K, V are individual tensors of [total_q/k, num_heads, head_size]'
    return layouts


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        prog="Benchmark FlashAttention",
        allow_abbrev=False,
    )
    parser.add_argument('-model_configs', type=str, default="utils/model_configs.json", help="Model config json file.")
    available_models = get_available_models()  # Dynamically load model names
    model_help = (
        "Model name to benchmark. Select from: [" + ", ".join(available_models) +
        "]. Use 'all' to benchmark all models. Provide model family (the part before -) to benchmark all models in that family. One can provide multiple as -model \"llama3,mistral_7B\""
    )
    parser.add_argument('-model', type=str, default="all", help=model_help)
    parser.add_argument("-b", type=int, default=0)
    parser.add_argument("-hq", type=int, default=0)
    parser.add_argument("-hk", type=int, default=0)
    parser.add_argument("-sq", type=int, default=0)
    parser.add_argument("-sk", type=int, default=0)
    parser.add_argument("-varlen", action='store_true', default=False,
                        help='If specified, uses variable sequence lengths. The t in the layout thd for q has maximum possible value of b*sq')
    parser.add_argument("-d", type=int, default=0)
    parser.add_argument("-causal", action='store_true', default=False)
    parser.add_argument("-int8", action='store_true', default=False)
    parser.add_argument("-quantize_p", action='store_true', default=False)
    parser.add_argument("-int8_kv", action='store_true', default=False)
    parser.add_argument("-dtype", default='fp16')
    parser.add_argument("-bench_torch", action='store_true', default=False)
    parser.add_argument("-return_time", action='store_true', default=False)
    parser.add_argument("-layout", type=str, default='thd', help=supported_layouts())
    parser.add_argument(
        "-persistent", nargs='?', const='fixed', choices=['fixed', 'dynamic'], default=None,
        help="Enable persistent kernels. Use '-persistent dynamic' for dynamic scheduling of the tiles.")
    return parser.parse_args()


arg_to_torch_dtype = {'fp16': torch.float16, 'bf16': torch.bfloat16, 'fp32': torch.float32}


def main():
    args = parse_args()
    custom_config = False
    # assert args.layout == 'thd' or not args.equal_seqlens or args.model, \
    #        "Equal sequence lengths arg must be used with the thd layout or a model config."
    if args.hq or args.hk or args.d:
        custom_config = True
        assert args.b and args.hq and args.sq and args.d, \
               "If custom config is specified, please provide \
                all of batch, number of Q heads, Q sequence length \
                and head size."

    if args.model:
        assert not (args.hq or args.hk or args.d), \
                "Specifying model fixes hq, hk and d already. Do not provide them!"

    assert args.dtype in arg_to_torch_dtype, \
           "Only fp16, bf16 and f32 types currently supported."

    if args.model:
        print("Note: Model config sets causal masking and THD layout (varlen) by default.")

    # test_correctness(custom_config, args)

    run_benchmark(custom_config, args)


if __name__ == '__main__':
    import sys
    sys.exit(main())
