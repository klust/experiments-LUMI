#!/bin/bash
#
#SBATCH --exclusive
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:10:00
#SBATCH --hint=nomultithread
#SBATCH --gres=gpu:8

echo "Starting job $SLURM_JOB_ID at `date`"

module load craype-x86-trento
module load craype-accel-amd-gfx90a
module load rocm

#### TEST THE TWO VERSIONS FOLLOWING ####
# cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"

#### TEST THE THREE VERSION FOLLOWING ####
gpu_bind=../select_gpu_naive.sh
# gpu_bind=../select_gpu_opti.sh
# gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"


export OMP_NUM_THREADS=1
export OMP_PROC_BIND=close
export OMP_PLACES=cores
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./hello_jobstep | sort


echo "... finished job $SLURM_JOB_ID at `date`"
