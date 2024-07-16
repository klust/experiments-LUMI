#!/bin/bash
#SBATCH --job-name=mpi-nomultithread
#SBATCH --partition=debug
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=32
#SBATCH --time=5:00
#SBATCH --hint=nomultithread
#SBATCH --output=%x-%j.out

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#bin/omp_hello
srun bin/hybrid_hello -r
