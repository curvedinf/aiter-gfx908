# export PYTHONPATH=/home/jun_chen2_qle/aiter/

export AMDGCN_USE_BUFFER_OPS=1
export TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1
export TRITON_HIP_ASYNC_FAST_SWIZZLE=1
bench_file=bench_mha.py
b=$1 # batch size
hq=$2 # number of q heads
hk=$3 # number of k heads
sq=$4 # q seq len
sk=$5 # k seq len
d=$6 # dim

# bf16
echo "-b $b -hq $hq -hk $hk -sq $sq -sk $sk -d $d bf16"
rocprofv2 --kernel-trace -o res python3 /app/aiter/op_tests/op_benchmarks/triton/${bench_file}  -b $b -hq $hq -hk $hk -sq $sq -sk $sk -d $d --dtype bf16 --metric time
python3 rprof.py results_res.csv -k attn

# fp8
echo "-b $b -hq $hq -hk $hk -sq $sq -sk $sk -d $d fp8"
rocprofv2 --kernel-trace -o res python3 /app/aiter/op_tests/op_benchmarks/triton/${bench_file}  -b $b -hq $hq -hk $hk -sq $sq -sk $sk -d $d --dtype bf16 -fp8 --metric time    
python3 rprof.py results_res.csv -k attn
