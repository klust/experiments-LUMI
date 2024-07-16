#!/bin/bash
#SBATCH --job-name=omp-multithread
#SBATCH --partition=debug
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=5:00
#SBATCH --hint=multithread
#SBATCH --output=%x-%j.out

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#bin/omp_hello
bin/hybrid_hello -r
