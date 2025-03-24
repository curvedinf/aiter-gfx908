asm_mla_decode_fwd_test:
	hipcc asm_mla_decode_fwd.cpp asm_mla_decode_fwd_torch.cpp asm_mla_decode_fwd_test.cpp -std=c++17 -O0 -g -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[0])") \
	  -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[1])") \
	  -Wl,-rpath,$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") \
	  -L$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") -lgtest -lgtest_main -L/usr/local/lib -ltorch -ltorch_cpu -ltorch_hip -lc10 -lc10_hip -lfmt -lcrypto -o asm_mla_decode_fwd_test.out

asm_mla_decode_fwd_aot.so:
	hipcc asm_mla_decode_fwd.cpp asm_mla_decode_fwd_torch.cpp -o asm_mla_decode_fwd_lib.so -fPIC -shared -I../include -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[0])") \
	  -I$(shell python3 -c "from torch.utils import cpp_extension; print(cpp_extension.include_paths()[1])") \
	  -Wl,-rpath,$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") \
	  -L$(shell python3 -c "from torch.utils import cpp_extension; print(' '.join(cpp_extension.library_paths()))") -std=c++17 -O3 -lfmt -lcrypto -ltorch -ltorch_cpu -ltorch_hip -lc10 -lc10_hip

clean:
	rm -f asm_mla_decode_fwd_test.out