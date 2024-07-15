#!/bin/bash
#SBATCH -J libsci_acc
#SBATCH -t 10
#SBATCH -N 1
#SBATCH --gres=gpu:8
#SBATCH --exclusive

N=10000
Niter=10

module load PrgEnv-cray
module load craype-x86-trento

export OMP_NUM_THREADS=4

echo "Compile and run CPU only"
make clean
make
time srun -n 4 -c ${OMP_NUM_THREADS} ./pdgemm.x ${N} ${Niter}

echo 
echo "Run with LibSci_ACC, automatic interface"
module load craype-accel-amd-gfx90a
module load rocm
module load cray-libsci_acc/22.08.1.1
export LD_LIBRARY_PATH=${CRAY_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}
export ROCR_VISIBLE_DEVICES=0 # use a single GPU
make clean
make
time srun -n 4 -c ${OMP_NUM_THREADS} ./pdgemm.x ${N} ${Niter}

echo
echo "Adding avoiding heuristics on input data"
export LIBSCI_ACC_BYPASS_BLAS3=3
time srun -n 4 -c ${OMP_NUM_THREADS} ./pdgemm.x ${N} ${Niter}

echo 
echo "Adding MPI G2G enabled"
export MPICH_GPU_SUPPORT_ENABLED=1
time srun -n 4 -c ${OMP_NUM_THREADS} ./pdgemm.x ${N} ${Niter}

echo
echo "Adding GPU resident data"
make clean
make USE_GPU_DATA=1
time srun -n 4 -c ${OMP_NUM_THREADS} ./pdgemm.x ${N} ${Niter}
