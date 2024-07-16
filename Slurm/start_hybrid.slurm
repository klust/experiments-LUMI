#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=8
#SBATCH --hint=multithread
#SBATCH --time=5:00
#SBATCH --mail-type=BEGIN
#SBATCH --mail-user=k.w.a.lust@gmail.com

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

#srun  bin/hybrid_hello -r
srun  hybrid_check -r
