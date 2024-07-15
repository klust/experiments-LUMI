#!/bin/bash

#SBATCH -J perftools-lite-gpu
#SBATCH -t 10
#SBATCH -N 1
#SBATCH --gres=gpu:8
#SBATCH --exclusive

#NOW=$(date +"%S-%M-%H-%m-%d-%Y")

# Change the name of the perftools experiment file/directory
export PAT_RT_EXPDIR_NAME=expfile.${CRAYPAT_LITE}.${SLURM_JOBID}

time srun -n 8 himeno.exe > my_output.${CRAYPAT_LITE}.${SLURM_JOBID} 2>&1


