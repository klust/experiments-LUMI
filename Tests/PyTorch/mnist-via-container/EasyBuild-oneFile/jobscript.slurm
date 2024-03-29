#!/bin/bash -e
#SBATCH --nodes=4
#SBATCH --gpus-per-node=8
#SBATCH --tasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --output="output_%x_%j.txt"
#SBATCH --partition=standard-g
#SBATCH --mem=480G
#SBATCH --time=00:10:00
###SBATCH --account=project_<your_project_id>

cat $0
echo -e "\n#######################################################################################\n"

init-lumi-h
module load LUMI/23.09
module load wget       # Compute nodes don't have wget preinstalled. Version and toolchain don't matter in this example.

#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-debugsymbols-singularity-20231110
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-debugsymbols-singularity-20240207
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-singularity-20231110
#module load PyTorch/2.0.1-rocm-5.5.1-python-3.10-singularity-20240207
#module load PyTorch/2.1.0-rocm-5.6.1-python-3.10-singularity-20231123 
#module load PyTorch/2.1.0-rocm-5.6.1-python-3.10-singularity-20240207
#module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240208
#module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240209
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240315

# Get the files from the LUMI ReFrame repository
wget https://raw.githubusercontent.com/Lumi-supercomputer/lumi-reframe-tests/main/checks/containers/ML_containers/src/pytorch/mnist/mnist_DDP.py
mkdir -p model ; cd model
wget https://github.com/Lumi-supercomputer/lumi-reframe-tests/raw/main/checks/containers/ML_containers/src/pytorch/mnist/model/model_gpu.dat
cd ..

#export SINGULARITYENV_NCCL_DEBUG=INFO
#export SINGULARITYENV_NCCL_DEBUG_SUBSYS=INIT,COLL

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

srun --cpu-bind=mask_cpu:$MYMASKS \
  singularity exec $SIFPYTORCH \
    conda-python-distributed -u mnist_DDP.py --gpu --modelpath model
