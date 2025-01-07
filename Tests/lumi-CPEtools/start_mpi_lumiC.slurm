#!/bin/bash
#SBATCH --job-name=mpi-test
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --cpus-per-task=1
#SBATCH --hint=multithread
#SBATCH --time=5:00

#init-lumi-h
ml LUMI/24.03
ml lumi-CPEtools/1.2-cpeAOCC-24.03

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

srun  mpi_check -r
