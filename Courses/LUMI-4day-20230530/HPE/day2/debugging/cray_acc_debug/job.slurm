#!/bin/bash

#SBATCH -t 10
#SBATCH -N 2
#SBATCH --ntasks-per-node=4
#SBATCH --gres=gpu:8
#SBATCH --exclusive

#NOW=$(date +"%S-%M-%H-%m-%d-%Y")

# Change the name of the perftools experiment file/directory

time srun -n 8 himeno.exe > my_output_acc_debug.${SLURM_JOBID} 2>&1
