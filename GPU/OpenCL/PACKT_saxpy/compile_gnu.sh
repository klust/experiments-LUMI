ml cpe/23.09
ml cpe/23.09
ml PrgEnv-gnu
ml rocm/5.2.3

export OPENCLROOT=/opt/rocm-5.2.3/opencl
CC -I$OPENCLROOT/include -L$OPENCLROOT/lib -lOpenCL -craype-verbose saxpy.cpp -o saxpy.x
