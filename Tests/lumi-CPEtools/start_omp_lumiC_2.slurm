#!/bin/bash
#SBATCH --job-name=omp-test
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --hint=multithread
#SBATCH --time=30:00
#SBATCH --output=bip_%j.out
#SBATCH --error=bip_%j.err

#init-lumi-h
ml LUMI/22.08
ml lumi-CPEtools/1.0-cpeGNU-22.08

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

for i in {1..25};
do 
    srun  omp_check -r
    sleep 30
done
