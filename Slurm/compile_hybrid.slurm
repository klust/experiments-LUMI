#!/bin/bash
#SBATCH --job-name=compile_hybrid-test
#SBATCH --partition=standard
#SBATCH --reservation=csc_proj_changes
#SBATCH --nodes=3
#SBATCH --ntasks=48
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

ml LUMI/21.08
ml cpeCray

module list

cd $HOME/experiments-LUMI/Slurm/src
make clean mpi_omp_hello

export OMP_NUM_THREADS=8
export OMP_PLACES=cores
export OMP_PROC_BIND=true

srun ../bin/mpi_omp_hello
