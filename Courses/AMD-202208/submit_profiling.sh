#!/bin/bash
#SBATCH --job-name=profile_saxpy
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH -p pilot
#SBATCH --output=prof_%j.out
#SBATCH --error=prof_%j.err
#SBATCH -A project_462000031

module load LUMI/22.06
module load rocm 

srun -N 1 -n 1 --gpus=1  ./rocprof_wrapper.sh /users/$USER/ saxpy ./saxpy 

