#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=debug
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#bin/omp_hello
bin/hybrid_ello -r
