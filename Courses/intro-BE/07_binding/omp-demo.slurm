#!/bin/bash
#SBATCH --job-name=omp-demo
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --hint=multithread
#SBATCH --time=5:00

# Note: We won't use a whole node but need this to have a proper binding.

module load LUMI/23.09 partition/C lumi-CPEtools/1.1-cpeCray-23.09

set -x
export OMP_NUM_THREADS=4
export OMP_PROC_BIND=false
srun -n 1 -c 32 --hint=multithread   omp_check -r
srun -n 1 -c 16 --hint=nomultithread omp_check -r

export OMP_NUM_THREADS=4
unset OMP_PROC_BIND
srun -n 1 -c 32 --hint=multithread   omp_check -r
srun -n 1 -c 16 --hint=nomultithread omp_check -r

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
srun -n 1 -c 32 --hint=multithread   omp_check -r
srun -n 1 -c 16 --hint=nomultithread omp_check -r

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=spread
srun -n 1 -c 32 --hint=multithread   omp_check -r
srun -n 1 -c 16 --hint=nomultithread omp_check -r

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
export OMP_PLACES=threads
srun -n 1 -c 32 --hint=multithread   omp_check -r
export OMP_PLACES=cores
srun -n 1 -c 32 --hint=multithread   omp_check -r

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
export OMP_PLACES="{0:8}:4:8"
srun -n 1 -c 32 --hint=multithread   omp_check -r

export OMP_PLACES="{0:4,16:4}:4:4"
srun -n 1 -c 32 --hint=multithread   omp_check -r
set +x

