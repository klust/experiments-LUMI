#!/bin/bash

#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH -t 10
#SBATCH --gres=gpu:1
#SBATCH --exclusive

module load craype-x86-trento
module load craype-accel-amd-gfx90a rocm perftools
export LD_LIBRARY_PATH=$CRAYPAT_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

srun ./pi_hip+pat > my_output.${SLURM_JOBID} 2>&1

