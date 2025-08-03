# export PYTHONPATH=/home/jun_chen2_qle/aiter/

bench_file=bench_moe.py

#model=$1
model=deepseek
# bf16
for M in 128 256 512 1024 2048 4096 8192 10240; do
    python3 bench_moe.py --model "$model" -M $M -dtype bf16
done

# fp8 
# for M in 128 256 512 1024 2048 4096 8192 10240; do
#    python3 bench_moe.py --model "deepseek" -M $M -fp8_w8a8 -fp8_e e4m3fnuz 
# done

model=qwen3
for M in 128 256 512 1024 2048 4096 8192 10240; do
    python3 bench_moe.py --model "$model" -M $M -dtype bf16
done

