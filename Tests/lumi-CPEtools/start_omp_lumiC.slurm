#!/bin/bash
#SBATCH --job-name=omp-test
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --hint=multithread
#SBATCH --time=5:00

#init-lumi-h
ml LUMI/24.03
ml lumi-CPEtools/1.2-cpeAOCC-24.03

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

srun  omp_check -r
