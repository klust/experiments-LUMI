#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=debug
#SBATCH --nodes=2
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

export OMP_NUM_THREADS=8
export OMP_PLACES=cores
export OMP_PROC_BIND=true

srun bin/mpi_omp_hello
