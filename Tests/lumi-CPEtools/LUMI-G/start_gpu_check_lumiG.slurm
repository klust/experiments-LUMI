#!/bin/bash
#SBATCH --job-name=gpu_check-test
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --gpus-per-node=8
#SBATCH --hint=nomultithread
#SBATCH --time=15:00
#SBATCH --output %x-%j.txt

init-lumi-h
stack_version='22.12'
CPE_version='1.1a'

module load LUMI/$stack_version partition/G

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

export OMP_NUM_THREADS=4
export OMP_PROC_BIND=close
export OMP_PLACES=cores

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
	gpu_bind="--gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03"
	
	echo "OMP variables:"
	env | grep -e ^OMP_
	echo "CPU bind argument: $cpu_bind"
	echo "GPU binding: $gpu_bind"
	echo -e "\nsrun -N ${SLURM_NNODES} -n $4 ${cpu_bind} ${gpu_bind} gpu_check -l"
	timeout -k 10s 20s srun -N ${SLURM_NNODES} -n 4 ${cpu_bind} ${gpu_bind} gpu_check -l

    module unload rocm
    
done
