decode_mla_stage2_asm:
	python3 ../../aiter/aot/decode_mla.py

decode_mla_test:
	hipcc -o decode_mla_test.out -lgtest -lgtest_main ../py_itfs_cu/asm_mla.cpp decode_mla.cpp decode_mla_stage2_asm.f51b00db_0d1d2d3d45678910.cpp decode_mla_test.cpp -I../include -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[0])") \
	  -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[1])") \
	  -Wl,-rpath,$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") \
	  -L$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") -std=c++17 -O0 -g -ltorch -ltorch_cpu -ltorch_hip -lc10 -lc10_hip

clean:
	rm -f ./decode_mla_test.out