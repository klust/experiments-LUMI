#!/bin/bash
#SBATCH --job-name=get_binding
#SBATCH --ntasks=8
#SBATCH --ntasks-per-node=8
##SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=8
#SBATCH --time=00:05:00
#SBATCH -p pilot
#SBATCH --output=get_bind.out
#SBATCH --error=get_bind.err

srun -n 8 -c 8  --gpus=8 --cpu-bind=verbose hostname

srun -n 8 --gpus=8 rocm-smi --showtopo
