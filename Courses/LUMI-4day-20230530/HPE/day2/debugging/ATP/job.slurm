#! /bin/bash

#SBATCH -J ATP
#SBATCH -t 10
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --exclusive

export OMP_NUM_THREADS=1

export ATP_ENABLED=1
ulimit -c unlimited
module load atp
make clean
make

srun -n 2 --cpus-per-task=$OMP_NUM_THREADS ./hello.exe > $SLURM_SUBMIT_DIR/my_output 2>&1
