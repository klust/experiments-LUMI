#!/bin/bash

set -e

TAICHI_VERSION=1.7.1

module --force purge

#git clone -b v$TAICHI_VERSION --depth 1 https://github.com/taichi-dev/taichi.git
cd taichi/
#git submodule update --init --recursive

# Taichi expect a integer "compute capability". It doesn't work with MI250X arch which contain a letter
# Just hard code the architecture as we only have one GPU architecture 
#sed -i 's/"gfx{}", compute_capability_/"gfx{}", "gfx90a"/' taichi/rhi/amdgpu/amdgpu_context.cpp
# Probably LUMI specific, doesn't really matter
#sed -i 's/if ensurepip:/if False:/' .github/workflows/scripts/ti_build/bootstrap.py


# Just in case
rm -rf ~/.cache/ti-build-cache/

module load LUMI/23.09
module load X11/23.09-cpeGNU-23.09
module load cray-python rocm craype-accel-host craype-network-none
module rm cray-libsci

python -m venv --system-site-packages venv && . venv/bin/activate

export PATH=$ROCM_PATH/llvm/bin:$PATH
export CCC_OVERRIDE_OPTIONS="+--gcc-toolchain=/opt/cray/pe/gcc/12.2.0/snos"
export TAICHI_CMAKE_ARGS="-DTI_WITH_AMDGPU:BOOL=ON -DTI_WITH_CUDA:BOOL=OFF -DTI_WITH_VULKAN:BOOL=OFF -DTI_BUILD_TESTS:BOOL=OFF -DTI_WITH_OPENGL:BOOL=OFF"
export CC=clang
export CXX=clang++

NPROCS=1 ./build.py --python=native wheel

rm -rf ~/.cache/ti-build-cache/

deactivate

cp dist/*.whl ..

#cd .. && rm -rf taichi

