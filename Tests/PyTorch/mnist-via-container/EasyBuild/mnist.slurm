#!/bin/bash -e
#SBATCH --nodes=4
#SBATCH --gpus-per-node=8
#SBATCH --tasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --output="output_%x_%j.txt"
#SBATCH --partition=standard-g
#SBATCH --mem=480G
#SBATCH --time=00:10:00

init-lumi-h
module load LUMI  # Which version doesn't matter, it is only to get the container and wget.
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-debugsymbols-singularity-20231110
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-debugsymbols-singularity-20240207
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-singularity-20231110
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-singularity-20240207
#module load PyTorch/2.1.0-rocm-5.6.1-python-3.10-singularity-20231123 
#module load PyTorch/2.1.0-rocm-5.6.1-python-3.10-singularity-20240207
#module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240208
#module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240209
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240315

# Optional: Inject the environment variables for NCCL debugging into the container.   
# This will produce a lot of debug output!     
#export SINGULARITYENV_NCCL_DEBUG=INFO
#export SINGULARITYENV_NCCL_DEBUG_SUBSYS=INIT,COLL

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

cd mnist
srun --cpu-bind=mask_cpu:$MYMASKS \
  singularity exec $SIFPYTORCH \
    conda-python-distributed -u mnist_DDP.py --gpu --modelpath model
