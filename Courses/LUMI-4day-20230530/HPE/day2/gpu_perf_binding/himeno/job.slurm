#!/bin/bash
#
#SBATCH --exclusive
#SBATCH -J himeno_gpu
##SBATCH -o %x-j%j.out
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:10:00
#SBATCH --gres=gpu:8
#SBATCH --hint=nomultithread

echo "Starting job $SLURM_JOB_ID at `date`"

module load craype-x86-trento
module load craype-accel-amd-gfx90a
module load rocm
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=NUMA

export OMP_NUM_THREADS=1
export OMP_PROC_BIND=close
export OMP_PLACES=cores

exe1=../hello_jobstep/hello_jobstep
exe2=./himeno.exe

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"


# Default binding and performance
time srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind} ${exe1} | sort
wait
time srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind} ${exe2}
wait

#TODO : uncomment the following line to get the right binding
# gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"
time srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind} ${exe1} | sort
wait
time srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind} ${exe2}
wait

echo "... finished job $SLURM_JOB_ID at `date`"
