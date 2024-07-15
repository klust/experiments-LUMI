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

# Install pytorch if it doesn't exist already.
if [ ! -d $wd/miniconda3/envs/pytorch ] ; then
    curl -LO https://repo.anaconda.com/miniconda/Miniconda3-py310_23.3.1-0-Linux-x86_64.sh
    bash ./Miniconda3-* -b -p $wd/miniconda3 -s
    rm -rf ./Miniconda3-*

    source $wd/miniconda3/bin/activate base
    conda create -y -n pytorch python=3.8
    source $wd/miniconda3/bin/activate pytorch
    pip3 install --pre torch==1.13.1 --extra-index-url https://download.pytorch.org/whl/rocm5.2/
else
    source $wd/miniconda3/bin/activate pytorch
fi

srun --jobid=$jobid -n1 --gpus 8 \
    python -c 'import torch; print("I have this many devices:", torch.cuda.device_count())'
