#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=small
#SBATCH --nodes=2
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=8
#SBATCH --hint=multithread
#SBATCH --time=5:00

#init-lumi-h
ml LUMI/22.08
ml lumi-CPEtools/1.0-cpeAOCC-22.08

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

srun  hybrid_check -r
