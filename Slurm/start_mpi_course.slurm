#!/bin/bash
#SBATCH --job-name=mpi-test
#SBATCH --partition=small
#SBATCH --nodes=2
#SBATCH --tasks-per-node=128
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

srun -n 256 bin/mpi_hello
