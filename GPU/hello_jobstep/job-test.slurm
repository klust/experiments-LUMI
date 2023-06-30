#!/bin/bash
#
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:05:00
#SBATCH --hint=nomultithread
#SBATCH --gpus-per-node=8

echo "Starting job $SLURM_JOB_ID at `date`"

module load LUMI/22.12 partition/G

EXE='hello_jobstep-cce.x' ; module load cpeCray
#EXE='hello_jobstep-gcc.x' ; module load cpeGNU
#EXE='hello_jobstep-rocm.x' ; module load cpeAMD

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
export OMP_PLACES=cores

#
# Print some info
#
cat - <<EOF

Proper mapping:

CPU die 0 providing HWT 000-007 and 064-071 to GPU die 4 with Bus_ID d1
CPU die 1 providing HWT 008-015 and 072-079 to GPU die 5 with Bus_ID d6
CPU die 2 providing HWT 016-023 and 080-087 to GPU die 2 with Bus_ID c9
CPU die 3 providing HWT 024-031 and 088-095 to GPU die 3 with Bus_ID ce
CPU die 4 providing HWT 032-039 and 096-103 to GPU die 6 with Bus_ID d9
CPU die 5 providing HWT 040-047 and 104-111 to GPU die 7 with Bus_ID de
CPU die 6 providing HWT 048-055 and 112-119 to GPU die 0 with Bus_ID c1
CPU die 7 providing HWT 056-063 and 120-127 to GPU die 1 with Bus_ID c6

GPU die 0 with Bus_ID c1 to CPU die 6 providing HWT 048-055 and 112-119
GPU die 1 with Bus_ID c6 to CPU die 7 providing HWT 056-063 and 120-127
GPU die 2 with Bus_ID c9 to CPU die 2 providing HWT 016-023 and 080-087
GPU die 3 with Bus_ID ce to CPU die 3 providing HWT 024-031 and 088-095
GPU die 4 with Bus_ID d1 to CPU die 0 providing HWT 000-007 and 064-071
GPU die 5 with Bus_ID d6 to CPU die 1 providing HWT 008-015 and 072-079
GPU die 6 with Bus_ID d9 to CPU die 4 providing HWT 032-039 and 096-103
GPU die 7 with Bus_ID de to CPU die 5 providing HWT 040-047 and 104-111

RT_GPU_ID: HIP runtime GPU ID, a local ID, a series starting from 0 for each process.
GPU_ID:    Global GPU ID, but can become local to the process depending on how 
           Slurm is used.
Bus_ID:    PCIe bus ID and the only truly reliable way to identify a physical GPU.

EOF

testnr=0

#
# Test: No binding whatsoever
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: No binding.\n"

cpu_bind=
gpu_bind="--gpus-per-task=1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort
echo
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE -l | sort


echo -e "\n... finished job $SLURM_JOB_ID at `date`"
