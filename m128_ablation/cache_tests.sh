#!/usr/bin/bash

rm -rf ~/.triton/cache/

run_mxfp4() {
  scale_a="$1"
  scale_b="$2"
  tensor_a="$3"
  tensor_b="$4"
  printf "\n\n\n################################################################\n"
  echo "cache_config:"
  echo "sa=" ${scale_a}
  echo "sb=" ${scale_b}
  echo "ta=" ${tensor_a}
  echo "tb=" ${tensor_b}
  result_file_name="cache_test_results_0/sa${scale_a}.sb${scale_b}.ta${tensor_a}.tb${tensor_b}.results.stats.csv"
  result_file_name="${result_file_name// /_}"
  echo "file_name=" $result_file_name

override_dir="/home/dtanner/repos/aiter/m128_ablation/triton_override_dir/WSUMGFNE3ZDPBNYVHLITN6EAWYN4BC36BN2ZBPN7ZHZPSE45ACQA"
original_cache_file="cache_labels.amdgcn"

  orig="${override_dir}/${original_cache_file}"
  tmp="${override_dir}/tmp.amdgcn"
  final="${override_dir}/_gemm_afp4_wfp4_kernel.amdgcn"
  cp $orig $tmp
  sed -i "s/offen lds ; scale_a/offen ${scale_a} lds ; scale_a/" $tmp
  sed -i "s/offen lds ; scale_b/offen ${scale_b} lds ; scale_b/" $tmp
  sed -i "s/offen lds ; tensor_a/offen ${tensor_a} lds ; tensor_a/" $tmp
  sed -i "s/offen lds ; tensor_b/offen ${tensor_b} lds ; tensor_b/" $tmp
  cp $tmp $final

TRITON_ALWAYS_COMPILE=1 \
  TRITON_PRINT_AUTOTUNING=1 \
  AMD_SERIALIZE_KERNEL=3 \
  TRITON_HIP_USE_ASYNC_COPY=1 \
  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 \
  TRITON_HIP_ASYNC_FAST_SWIZZLE=1 \
  TRITON_KERNEL_OVERRIDE=1 \
  TRITON_OVERRIDE_DIR=triton_override_dir \
  rocprof --stats python ../op_tests/op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth
mv results.stats.csv $result_file_name
}

cache_options=(
  ''
  'nt'
  'sc1'
  'sc1 nt'
  'sc0'
  'sc0 nt'
  'sc0 sc1'
  'sc0 sc1 nt'
)
echo ${cache_options[@]}
for scale_a in "${cache_options[@]}"; do
  echo "scale_a=" $scale_a
  for scale_b in "${cache_options[@]}"; do
    echo "scale_b=" $scale_b
    for tensor_a in "${cache_options[@]}"; do
      echo "tensor_a=" $tensor_a
      for tensor_b in "${cache_options[@]}"; do
        echo "tensor_b=" $tensor_b
        run_mxfp4 "$scale_a" "$scale_b" "$tensor_a" "$tensor_b"
done
done
done
done

#  rocprof --stats python op_tests/op_benchmarks/triton/bench_gemm_afp4wfp4.py --shape 128 106496 16384 --metric bandwidth
#  TRITON_HIP_AGGREGATE_LOAD_FACTOR=0 \
# rocprof --stats 
#  TRITON_HIP_AGGREGATE_LOAD_FACTOR=2 \
#  TRITON_HIP_ASYNC_COPY_OVERLAP=0 \
# TRITON_HIP_AGGREGATE_LOAD_FACTOR=2
# AMD_SERIALIZE_KERNEL=0
# TRITON_HIP_USE_ASYNC_COPY=0

#  TRITON_HIP_ASYNC_COPY_OVERLAP=0 \
#  TRITON_HIP_USE_BLOCK_PINGPONG=1 \
#  TRITON_HIP_ASYNC_COPY_OVERLAP=0 \
#  TRITON_HIP_ASYNC_FAST_SWIZZLE=1 \
#  AMDGCN_USE_BUFFER_OPS=1 \
#  TRITON_HIP_USE_BLOCK_PINGPONG=0 \
#  TRITON_HIP_ASYNC_FAST_SWIZZLE=1 \
# head -n 2 results.stats.csv

################################################################
# Dump & Override Options
#  TRITON_KERNEL_DUMP=1 \
#  TRITON_DUMP_DIR=triton_dump_dir \
#  TRITON_KERNEL_OVERRIDE=1 \
#  TRITON_OVERRIDE_DIR=triton_override_dir \

################################################################
# Compilation Options
#  TRITON_HIP_USE_ASYNC_COPY=1 \
#  TRITON_HIP_ASYNC_COPY_BYPASS_PERMUTE=1 \
#  TRITON_HIP_GLOBAL_PREFETCH=1 \
#  TRITON_HIP_LOCAL_PREFETCH=1 \

################################################################
# Problem Sizes
#  python bench_gemm_afp4wfp4.py --model llama3-405B -M 16 --metric bandwidth
#  python bench_gemm_afp4wfp4.py --model all -M 16 --metric bandwidth
#  python bench_gemm_afp4wfp4.py --shape 32 106496 16384 --metric bandwidth
#  python bench_gemm_afp4wfp4.py --shape 32 53248 16384 --metric bandwidth


# sort data
# grep gemm cache_test_results_0/* | sort -t ',' -nrk 4,4
# grep gemm cache_test_results_0/* | awk -F',' '{print $4}' | sort -r
