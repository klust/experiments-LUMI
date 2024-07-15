#!/bin/bash

#SBATCH -J perftools
#SBATCH -t 10
#SBATCH -N 1
#SBATCH --exclusive

#module load perftools
module load perftools-preload
module load cray-python

export PAT_RT_MPI_THREAD_REQUIRED=3
time srun -n 4 pat_run `which python` heat-p2p.py
