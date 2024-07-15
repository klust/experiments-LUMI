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
module load cray-python

# Default ROCm – more recent versions are preferable (e.g. ROCm 5.6.0).
module load rocm/5.2.3.lua

set -x

# Install pytorch if it doesn't exist already.
if [ ! -d $wd/cray-python-virtualenv ] ; then
    python -m venv --system-site-packages cray-python-virtualenv
    source cray-python-virtualenv/bin/activate
    pip3 install --pre torch==1.13.1 --extra-index-url https://download.pytorch.org/whl/rocm5.2/
else
    source cray-python-virtualenv/bin/activate
fi

srun --jobid=$jobid -n1 --gpus 8 \
    python -c 'import torch; print("I have this many devices:", torch.cuda.device_count())'
