#!/bin/bash
#
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --time=00:05:00
#SBATCH --hint=nomultithread
#SBATCH --gpus-per-node=8

echo "Starting job $SLURM_JOB_ID at `date`"

module load LUMI/22.12 partition/G

EXE='./hello_jobstep-cce.x' ; module load cpeCray
#EXE='./hello_jobstep-gcc.x' ; module load cpeGNU
#EXE='./hello_jobstep-rocm.x' ; module load cpeAMD

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

export OMP_NUM_THREADS=2
export OMP_PROC_BIND=close
export OMP_PLACES=cores

#
# Print some info
#

2>&1 $EXE -h

testnr=0

#
# Test: No binding whatsoever
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: cpus-per-task and gpus-per-task, no optimal binding.\n"

cpu_bind="--cpus-per-task=2"
gpu_bind="--gpus-per-task=2"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE | sort"
echo -e "\nFlags: -u"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -u | sort
echo -e "\nFlags: -l -u"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l -u | sort
echo -e "\nFlags: None"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE | sort
echo -e "\nFlags: -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l | sort

#
# Test: Optimal binding with masks, reordering the GPUs.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Optimal reordering with masks, reordering the GPUs.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
gpu_bind="--gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE | sort"
echo -e "\nFlags: -u"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -u | sort
echo -e "\nFlags: -l -u"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l -u | sort
echo -e "\nFlags: None"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE | sort
echo -e "\nFlags: -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l | sort


echo -e "\n... finished job $SLURM_JOB_ID at `date`"
