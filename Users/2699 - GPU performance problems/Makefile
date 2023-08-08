# Use with cpeCray

all : test_GPU.x test_GPU_mapping.x

test_GPU.x : test_GPU.cpp
	CC -xhip $< -o $@
	
test_GPU_mapping.x : test_GPU_mapping.cpp
	CC -xhip $< -o $@

clean :
	/bin/rm -f *.x
