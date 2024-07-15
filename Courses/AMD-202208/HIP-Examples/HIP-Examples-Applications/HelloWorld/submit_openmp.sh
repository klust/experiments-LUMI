#!/bin/bash
#SBATCH --job-name=openmphello
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
##SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=16
#SBATCH --hint=nomultithread
#SBATCH --time=00:05:00
#SBATCH -p pilot
#SBATCH --output=hello.out
#SBATCH --error=hello.err
##SBATCH -A project_462000031

export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export OMP_NUM_THREADS=16
export OMP_DISPLAY_AFFINITY=TRUE

srun  ./HelloWorld
