# SPDX-License-Identifier: MIT
# Copyright (c) 2025, Advanced Micro Devices, Inc. All rights reserved.

import torch
import aiter
from aiter.test_common import checkAllclose, perftest
import itertools
import argparse
import random
import math

import triton

Block_M = 64
Block_N = 64

def setup_seed(seed):
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    random.seed(seed)
    torch.backends.cudnn.deterministic = True

setup_seed(0)

def get_mla_metadata(cache_seqlens, num_heads_per_head_k, num_heads_k):
    batch_size = cache_seqlens.size(0)
    cu_count = torch.cuda.get_device_properties(
        device='cuda').multi_processor_count
    cu_parts = int(cu_count / num_heads_k / ((num_heads_per_head_k + Block_M - 1) // Block_M))

    tile_scheduler_metadata = torch.zeros([cu_parts, 5]).to(torch.int)
    num_splits = torch.zeros([batch_size + 1]).to(torch.int)

    fixed_overhead_num_blocks = 5;

    num_blocks = cache_seqlens // Block_N
   
    sum_blocks = num_blocks.sum() + fixed_overhead_num_blocks * batch_size
    payload = (sum_blocks + cu_parts - 1) // cu_parts + fixed_overhead_num_blocks

    now_idx = 0
    now_block = 0
    now_n_split_idx = 0
    cum_num_splits = 0

    num_splits[0] = 0
    for i in range(cu_parts):
        tile_scheduler_metadata[i, 0] = now_idx
        tile_scheduler_metadata[i, 1] = now_block * Block_N 
        tile_scheduler_metadata[i, 4] = now_n_split_idx
        remain_payload = payload
        while now_idx < batch_size:
            num_block = num_blocks[now_idx]
            now_remain_blocks = num_block - now_block

            if remain_payload >= now_remain_blocks + fixed_overhead_num_blocks:
                cum_num_splits = cum_num_splits + now_n_split_idx + 1
                num_splits[now_idx + 1] = cum_num_splits
                remain_payload = remain_payload - (now_remain_blocks + fixed_overhead_num_blocks)
                now_idx = now_idx + 1
                now_block = 0
                now_n_split_idx = 0
            else:
                if remain_payload - fixed_overhead_num_blocks > 0:
                    now_block += remain_payload - fixed_overhead_num_blocks
                    now_n_split_idx = now_n_split_idx + 1
                    remain_payload = 0
                break
        if now_block > 0:
            tile_scheduler_metadata[i, 2] = now_idx
            tile_scheduler_metadata[i, 3] = now_block * Block_N 
        else:
            tile_scheduler_metadata[i, 2] = now_idx - 1
            tile_scheduler_metadata[i, 3] = cache_seqlens[now_idx - 1]

    return tile_scheduler_metadata, num_splits


def scaled_dot_product_attention(query, key, value, h_q, h_kv, batch_id=0, partition_begin=0, partition_end=0, is_causal=False, out_flash=None, lse_flash=None):
    query = query.float()
    key = key.float()
    value = value.float()
    key = key.repeat_interleave(h_q // h_kv, dim=0)
    value = value.repeat_interleave(h_q // h_kv, dim=0)
    attn_weight = query @ key.transpose(-2, -1) / math.sqrt(query.size(-1))

    scale = 1 / math.sqrt(query.size(-1))
    scale_log2 = scale * math.log2(math.e)
    if is_causal:
        s_q = query.shape[-2]
        s_k = key.shape[-2]
        attn_bias = torch.zeros(s_q, s_k, dtype=query.dtype).cuda()
        temp_mask = torch.ones(s_q, s_k, dtype=torch.bool).tril(diagonal=s_k - s_q).cuda()
        attn_bias.masked_fill_(temp_mask.logical_not(), float("-inf"))
        attn_bias.to(query.dtype)
        attn_weight += attn_bias

        if partition_end == 0:
            partition_end = s_k
        def flash_attention():
            bq = query[:, 0]
            out_flash
            lse_flash
            n_block_num = (partition_end - partition_begin + Block_N - 1) // Block_N 
            # print("bq", bq)

            m = torch.zeros([Block_M]).cuda()
            l = torch.zeros([Block_M]).cuda()
            oacc = torch.zeros([Block_M, key.shape[-1] - 64]).cuda()

            m_log2 = torch.zeros([Block_M]).cuda()
            l_log2 = torch.zeros([Block_M]).cuda()
            oacc_log2 = torch.zeros([Block_M, key.shape[-1] - 64]).cuda()

            i_block_n = n_block_num
            for i in range(n_block_num):
                if i == 0:
                    bk = key[0][i_block_n * Block_N - Block_N + partition_begin:]
                else:
                    bk = key[0][i_block_n * Block_N - Block_N + partition_begin: i_block_n * Block_N + partition_begin]

                block_tmp = bq @ bk.transpose(0, 1) * scale
                block_tmp_log2 = bq @ bk.transpose(0, 1)

                block_tmp_masked = block_tmp
                block_tmp_masked_log2 = block_tmp_log2

                m_local = block_tmp_masked.max(-1).values
                m_local_log2 = block_tmp_masked_log2.max(-1).values

                m_old = m
                m_old_log2 = m_log2
                if i == 0:
                    m = m_local
                    m_log2 = m_local_log2
                else:
                    m = torch.max(m, m_local)
                    m_log2 = torch.max(m_log2, m_local_log2)

                
                p_compute = torch.exp(block_tmp_masked - m.unsqueeze(-1)) 
                p_compute_log2 = 2 ** (scale_log2 * block_tmp_masked_log2 - scale_log2 * m_log2.unsqueeze(-1)) 

                # print("p_compute", p_compute)
                row_sum = p_compute.sum(-1)
                row_sum_log2 = p_compute_log2.sum(-1)

                scale_o = torch.exp(m_old - m)
                scale_o_log2 = 2 ** (scale_log2 * m_old_log2 - scale_log2 * m_log2)

                l = l * scale_o + row_sum
                l_log2 = l_log2 * scale_o_log2 + row_sum_log2

                bv = value[0][i_block_n * Block_N - Block_N : i_block_n * Block_N]

                if batch_id == 0 and i <= 1:
                    import pdb; pdb.set_trace()
                oacc = p_compute @ bv + oacc * scale_o.unsqueeze(-1)
                oacc_log2 = p_compute_log2 @ bv + oacc_log2 * scale_o_log2.unsqueeze(-1)
                i_block_n -= 1

            return oacc / l.unsqueeze(-1)

        # out = flash_attention()
        # import pdb; pdb.set_trace()
    lse = attn_weight.logsumexp(dim=-1)
    attn_weight = torch.softmax(attn_weight, dim=-1, dtype=torch.float32)
    return attn_weight @ value, lse


def cal_diff(x: torch.Tensor, y: torch.Tensor, name: str) -> None:
    x, y = x.double(), y.double()
    RMSE = ((x - y) * (x - y)).mean().sqrt().item()
    cos_diff = 1 - 2 * (x * y).sum().item() / max((x * x + y * y).sum().item(), 1e-12)
    amax_diff = (x - y).abs().max().item()
    # print(f"{name}: {cos_diff=}, {RMSE=}, {amax_diff=}")
    assert cos_diff < 1e-5


@torch.inference_mode()
def test_flash_mla(dtype, b, s_q, mean_sk, h_q, h_kv, d, dv, causal, varlen):
    print(
        f"{b=}, {s_q=}, {mean_sk=}, {h_q=}, {h_kv=}, {d=}, {dv=}, {causal=}, {varlen=}"
    )

    cache_seqlens = torch.full((b,), mean_sk, dtype=torch.int32, device="cuda")
    if varlen:
        for i in range(b):
            cache_seqlens[i] = max(random.normalvariate(mean_sk, mean_sk / 2), s_q)
    total_seqlens = cache_seqlens.sum().item()
    mean_seqlens = cache_seqlens.float().mean().int().item()
    max_seqlen = cache_seqlens.max().item()
    # max_seqlen_pad = triton.cdiv(max_seqlen, 256) * 256

    max_seqlen_pad = int(math.ceil(max_seqlen / 256) * 256)
    print(f"{total_seqlens=}, {mean_seqlens=}, {max_seqlen=}")

    q = torch.randn(b, s_q, h_q, d, device="cuda", dtype=dtype)

    block_size = 64

    block_table = torch.arange(
        b * max_seqlen_pad // block_size, dtype=torch.int32, device="cuda"
    ).view(b, max_seqlen_pad // block_size)
    blocked_k = torch.randn(block_table.numel(), block_size, h_kv, d, device="cuda", dtype=dtype)
    for i in range(b):
        blocked_k.view(b, max_seqlen_pad, h_kv, d)[i, cache_seqlens[i].item():] = (
            float("nan")
            # float(0)
        )
    blocked_v = blocked_k[..., :dv]

    tile_scheduler_metadata, num_splits = aiter.get_mla_metadata(
        cache_seqlens, s_q * h_q // h_kv, h_kv
    )

    # tile_scheduler_metadata_torch, num_splits_torch = get_mla_metadata(
    #     cache_seqlens, s_q * h_q // h_kv, h_kv
    # )

    # @perftest(num_iters=3)
    def flash_mla():
        return aiter.flash_mla_fwd_with_kvcache(
            q,
            blocked_k,
            block_table,
            cache_seqlens,
            dv,
            tile_scheduler_metadata,
            num_splits,
            causal=causal,
        )

    def ref_mla_cu_partition(out_flash=None, lse_flash=None):
        out_acc = torch.empty(len(num_splits), s_q, h_q, dv, dtype=torch.float32)
        lse_acc = torch.empty(len(num_splits), h_q, s_q, dtype=torch.float32)
        for i in range(len(num_splits)):
            batch_begin = tile_scheduler_metadata[i][0]
            batch_end = tile_scheduler_metadata[i][2]

            for j in range(batch_begin, batch_end + 1):
                print("i, j", i, j)
                partition_begin = tile_scheduler_metadata[i][1]
                partition_end = tile_scheduler_metadata[i][3]
                if j != batch_begin:
                    partition_begin = 0 
                if j != batch_end:
                    partition_end = max_seqlen_pad

                begin = j * max_seqlen_pad
                end = begin + cache_seqlens[j]
                import pdb; pdb.set_trace()
                O, LSE = scaled_dot_product_attention(
                    q[j].transpose(0, 1),
                    blocked_k.view(-1, h_kv, d)[begin:end].transpose(0, 1),
                    blocked_v.view(-1, h_kv, dv)[begin:end].transpose(0, 1),
                    h_q=h_q,
                    h_kv=h_kv,
                    partition_begin=partition_begin,
                    partition_end=partition_end,
                    batch_id=i,
                    is_causal=causal,
                    out_flash=out_flash,
                    lse_flash=lse_flash
                )
                out_acc[i] = O.transpose(0, 1)
                lse_acc[i] = LSE
        return out_acc, lse_acc

    def ref_mla(out_flash=None, lse_flash=None):
        out = torch.empty(b, s_q, h_q, dv, dtype=torch.float32)
        lse = torch.empty(b, h_q, s_q, dtype=torch.float32)
        for i in range(b):
            begin = i * max_seqlen_pad
            end = begin + cache_seqlens[i]
            O, LSE = scaled_dot_product_attention(
                q[i].transpose(0, 1),
                blocked_k.view(-1, h_kv, d)[begin:end].transpose(0, 1),
                blocked_v.view(-1, h_kv, dv)[begin:end].transpose(0, 1),
                h_q=h_q,
                h_kv=h_kv,
                batch_id=i,
                is_causal=causal,
                out_flash=out_flash,
                lse_flash=lse_flash
            )
            out[i] = O.transpose(0, 1)
            lse[i] = LSE
        return out, lse

    # out, us = flash_mla()
    # # out_flash, lse_flash = out

    # out_torch, lse_torch = ref_mla_cu_partition(out_acc, lse_acc)
    out_flash, lse_flash, debug_m, debug_p, debug_v, debug_o = flash_mla()
    bk =  blocked_k[4096//64-1, :, 0]
    bv = bk[:, :512]
    bvt =bv.transpose(0,1)

    # import pdb; pdb.set_trace()
    out_torch, lse_torch = ref_mla(debug_p, debug_v)
    # import pdb; pdb.set_trace()

    # def ref_mla_combine():
    #     for i in range(b):
    #         split_offset = num_splits[i]
    #         actual_num_splits = num_splits[i + 1] - split_offset
    #         if actual_num_splits == 1:
    #             continue
    #         # import pdb; pdb.set_trace()
    #         lse_actual = lse_acc[split_offset : split_offset + actual_num_splits]
    #         lse_max = lse_actual.max(dim = 0).values
    #         lse_sum = torch.exp(lse_actual - lse_max).sum(dim = 0)
    #         global_lse = torch.log(lse_sum) + lse_max
    #
    #         lse_torch
    #
    #         # import pdb; pdb.set_trace()
    #         lse_flash_torch[i] = global_lse
    #
    #         # for j in range(actual_num_splits):
    #         #     out_flash_torch[i] += out_acc[split_offset + j][0] * (torch.exp(lse_actual[j] - global_lse)[0].unsqueeze(-1))

    # ref_mla_combine()

    # print(out_flash, lse_flash)
    # print(out_torch, lse_torch)

    # cal_diff(out_flash, out_torch.cuda(), "out")
    # cal_diff(lse_flash, lse_torch.cuda(), "lse")

    # t = us / 1000
    t = triton.testing.do_bench(flash_mla)

    FLOPS = s_q * total_seqlens * h_q * (d + dv) * 2
    bytes = (total_seqlens * h_kv * d + b * s_q * h_q * d + b * s_q * h_q * dv) * (
        torch.finfo(q.dtype).bits // 8
    )
    print(
        f"{t:.3f} ms, {FLOPS / 10 ** 9 / t:.2f} TFLOPS, {bytes / 10 ** 6 / t:.2f} GB/s"
    )


if __name__ == "__main__":
    h_kv = 1
    d, dv = 192, 128
    # d, dv = 576, 512 
    causal = True

    # for (dtype, b, s, h_q, s_q, causal, varlen) in itertools.product(
    #     (torch.float16, ),
    #     (128,),
    #     (4096, 8192),
    #     (16, 32, 64, 128),
    #     (1, 2),
    #     (True,),
    #     (True, False)
    # ):
    for (dtype, b, s, h_q, s_q, causal, varlen) in itertools.product(
        (torch.float16, ),
        (128,),
        (8192,),
        (64,),
        (1,),
        (True,),
        (True,)
    ):
        test_flash_mla(dtype, b, s_q, s, h_q, h_kv, d, dv, causal, varlen)
