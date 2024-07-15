#!/bin/bash
#SBATCH -J valgrind4hpc
#SBATCH -t 10
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --exclusive

module load valgrind4hpc/2.12.11

valgrind4hpc -n 2 --launcher-args="-u" --valgrind-args="--track-origins=yes --leak-check=full" ./test.exe


