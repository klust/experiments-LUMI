#!/bin/bash

#SBATCH -J deadlock
#SBATCH -t 10
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --exclusive

srun -n 2 ./deadlock
