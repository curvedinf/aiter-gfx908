rm group_gemm_qwen_*p_fp4*.log
./tp.sh 128 8 6144 4096 4 |& tee group_gemm_qwen_tp_fp4_6144_4096.log
./tp.sh 128 8 4096 3072 4 |& tee group_gemm_qwen_tp_fp4_4096_3072.log
./tp.sh 128 8 3072 4096 4 |& tee group_gemm_qwen_tp_fp4_3072_4096.log
./tp.sh 128 8 4096 1536 4 |& tee group_gemm_qwen_tp_fp4_4096_1536.log
./ep.sh 32 4096 12288 4   |& tee group_gemm_qwen_ep_fp4_4096_12288.log
./ep.sh 32 12288 4096 4   |& tee group_gemm_qwen_ep_fp4_12288_4096.log
./ep.sh 16 4096 12288 4   |& tee group_gemm_qwen_ep_fp4_4096_12288.log
./ep.sh 16 12288 4096 4   |& tee group_gemm_qwen_ep_fp4_12288_4096.log

rm group_gemm_qwen_*p_fp8*.log
./tp.sh 128 8 6144 4096 2 |& tee group_gemm_qwen_tp_fp8_6144_4096.log
./tp.sh 128 8 4096 3072 2 |& tee group_gemm_qwen_tp_fp8_4096_3072.log
./tp.sh 128 8 3072 4096 2 |& tee group_gemm_qwen_tp_fp8_3072_4096.log
./tp.sh 128 8 4096 1536 2 |& tee group_gemm_qwen_tp_fp8_4096_1536.log
./ep.sh 32 4096 12288 2   |& tee group_gemm_qwen_ep_fp8_4096_12288.log
./ep.sh 32 12288 4096 2   |& tee group_gemm_qwen_ep_fp8_12288_4096.log
./ep.sh 16 4096 12288 2   |& tee group_gemm_qwen_ep_fp8_4096_12288.log
./ep.sh 16 12288 4096 2   |& tee group_gemm_qwen_ep_fp8_12288_4096.log

rm group_gemm_qwen_*p_bf16*.log
./tp.sh 128 8 6144 4096 0 |& tee group_gemm_qwen_tp_bf16_6144_4096.log
./tp.sh 128 8 4096 3072 0 |& tee group_gemm_qwen_tp_bf16_4096_3072.log
./tp.sh 128 8 3072 4096 0 |& tee group_gemm_qwen_tp_bf16_3072_4096.log
./tp.sh 128 8 4096 1536 0 |& tee group_gemm_qwen_tp_bf16_4096_1536.log
./ep.sh 32 4096 12288 0   |& tee group_gemm_qwen_ep_bf16_4096_12288.log
./ep.sh 32 12288 4096 0   |& tee group_gemm_qwen_ep_bf16_12288_4096.log
./ep.sh 16 4096 12288 0   |& tee group_gemm_qwen_ep_bf16_4096_12288.log
./ep.sh 16 12288 4096 0   |& tee group_gemm_qwen_ep_bf16_12288_4096.log

rm group_gemm_deepseek_*p_fp4*.log
./tp.sh 256 8 1024 7168 4 |& tee group_gemm_deepseek_tp_fp4_6144_4096.log
./tp.sh 256 8 7168 512 4  |& tee group_gemm_deepseek_tp_fp4_4096_3072.log
./tp.sh 256 8 512 7168 4  |& tee group_gemm_deepseek_tp_fp4_3072_4096.log
./tp.sh 256 8 7168 256 4  |& tee group_gemm_deepseek_tp_fp4_4096_1536.log
./ep.sh 64 4096 7168 4    |& tee group_gemm_deepseek_ep_fp4_4096_12288.log
./ep.sh 64 7168 2048 4    |& tee group_gemm_deepseek_ep_fp4_12288_4096.log
./ep.sh 32 4096 7168 4    |& tee group_gemm_deepseek_ep_fp4_4096_12288.log
./ep.sh 32 7168 2048 4    |& tee group_gemm_deepseek_ep_fp4_12288_4096.log

rm group_gemm_deepseek_*p_fp8.log
./tp.sh 256 8 1024 7168 2 |& tee group_gemm_deepseek_tp_fp8_6144_4096.log
./tp.sh 256 8 7168 512 2  |& tee group_gemm_deepseek_tp_fp8_4096_3072.log
./tp.sh 256 8 512 7168 2  |& tee group_gemm_deepseek_tp_fp8_3072_4096.log
./tp.sh 256 8 7168 256 2  |& tee group_gemm_deepseek_tp_fp8_4096_1536.log
./ep.sh 64 4096 7168 2    |& tee group_gemm_deepseek_ep_fp8_4096_12288.log
./ep.sh 64 7168 2048 2    |& tee group_gemm_deepseek_ep_fp8_12288_4096.log
./ep.sh 32 4096 7168 2    |& tee group_gemm_deepseek_ep_fp8_4096_12288.log
./ep.sh 32 7168 2048 2    |& tee group_gemm_deepseek_ep_fp8_12288_4096.log

rm group_gemm_deepseek_*p_bf16.log
./tp.sh 256 8 1024 7168 0 |& tee group_gemm_deepseek_tp_bf16_6144_4096.log
./tp.sh 256 8 7168 512 0  |& tee group_gemm_deepseek_tp_bf16_4096_3072.log
./tp.sh 256 8 512 7168 0  |& tee group_gemm_deepseek_tp_bf16_3072_4096.log
./tp.sh 256 8 7168 256 0  |& tee group_gemm_deepseek_tp_bf16_4096_1536.log
./ep.sh 64 4096 7168 0    |& tee group_gemm_deepseek_ep_bf16_4096_12288.log
./ep.sh 64 7168 2048 0    |& tee group_gemm_deepseek_ep_bf16_12288_4096.log
./ep.sh 32 4096 7168 0    |& tee group_gemm_deepseek_ep_bf16_4096_12288.log
./ep.sh 32 7168 2048 0    |& tee group_gemm_deepseek_ep_bf16_12288_4096.log

grep "ck_moe_stage1" group_gemm_qwen*.log
grep "ck_moe_stage1" group_gemm_deepseek*.log
