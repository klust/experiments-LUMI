#!/bin/bash -e

wd=$(pwd)
jobid=$(squeue --me | head -2 | tail -n1 | awk '{print $1}')


#
# Example assume allocation was created, e.g.:
# N=1 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus $((N*8)) -t 4:00:00 --mem 0
#

module purge
module load CrayEnv
module load PrgEnv-cray/8.3.3
module load craype-accel-amd-gfx90a

# Default ROCm – more recent versions are preferable (e.g. ROCm 5.6.0).
module load rocm/5.2.3.lua

set -x

# Install pytorch dependencies if it doesn't exist already.
if [ ! -d $wd/miniconda3/envs/pytorch-from-source ] ; then

    # Miniconda should exist already

    source $wd/miniconda3/bin/activate base
    conda create -y -n pytorch-from-source python=3.8
    source $wd/miniconda3/bin/activate pytorch-from-source

    conda install -y --only-deps pytorch
    conda install -y cmake mkl-include pyyaml
else
    source $wd/miniconda3/bin/activate pytorch-from-source
fi

# Clone source
if [ ! -d $wd/pytorch-source ] ; then
    git clone -b v1.13.1 --recursive https://github.com/pytorch/pytorch $wd/pytorch-source 
    cd $wd/pytorch-source 
    git submodule sync
    git submodule update --init --recursive --jobs 0
fi

# Build pytorch wheel file from source
if [ ! -f $wd/pytorch-source/dist/torch-*.whl ] ; then
    cd $wd/pytorch-source

    # Hipify source
    nice python3 tools/amd_build/build_amd.py

    # Build with debug symbols
    CMAKE_PREFIX_PATH=$CONDA_PREFIX:$CMAKE_PREFIX_PATH \
        PYTORCH_ROCM_ARCH=gfx90a \
        CMAKE_MODULE_PATH=$CMAKE_MODULE_PATH:$(pwd)/pytorch/cmake/Modules_CUDA_fix \
        LIBRARY_PATH=$CONDA_PREFIX/lib:$LIBRARY_PATH LDFLAGS="-ltinfo" \
        PYTORCH_ROCM_ARCH="gfx90a" \
        RCCL_PATH=$ROCM_PATH/rccl \
        RCCL_DIR=$ROCM_PATH/rccl/lib/cmake \
        hip_DIR=${ROCM_PATH}/hip/cmake/ \
        REL_WITH_DEB_INFO=1 \
        nice python3 setup.py bdist_wheel

    pip install $wd/pytorch-source/dist/torch-*.whl

    # Fix libstdc++ imcompatibility in CONDA
    rm -rf $wd/miniconda3/envs/pytorch-from-source/lib/libstdc++.so*
    ln -s /usr/lib64/libstdc++.so*  $wd/miniconda3/envs/pytorch-from-source/lib/
fi

# Make sure conda libs can be loaded.
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH 

srun --jobid=$jobid -n1 --gpus 8 \
    python -c 'import torch; print("I have this many devices:", torch.cuda.device_count())'
