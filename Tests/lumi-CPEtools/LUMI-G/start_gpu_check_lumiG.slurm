#!/bin/bash
#SBATCH --job-name=gpu_check-test
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --gpus-per-node=8
#SBATCH --hint=nomultithread
#SBATCH --time=15:00
#SBATCH --output %x-%j.txt
## The following line does not work as it seems not to pass other variables that are 
## important to clean the environment.
###SBATCH --export=LUMI_STACK_VERSION,EBVERSIONLUMIMINCPETOOLS

echo "Read from the environment: LUMI_STACK_VERSION = ${LUMI_STACK_VERSION}, EBVERSIONLUMIMINCPETOOLS = ${EBVERSIONLUMIMINCPETOOLS}."
stack_version=${LUMI_STACK_VERSION:-'22.12'}
CPE_version=${EBVERSIONLUMIMINCPETOOLS:-'1.1-cpeCray-22.12'}
CPE_version=${CPE_version%-cpe*}
echo -e "Running with lumi-CPEtools/${CPE_version}-cpe*-${stack_version}\n"

#init-lumi-h
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

echo "OMP variables:"
env | grep -e ^OMP_

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    #module show lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    #ls $EBROOTLUMIMINCPETOOLS/bin
    
    cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
	gpu_bind="--gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03"
	
	echo "CPU bind argument: $cpu_bind"
	echo "GPU binding: $gpu_bind"
	echo -e "\nsrun -N ${SLURM_NNODES} -n $4 ${cpu_bind} ${gpu_bind} gpu_check -l"
	timeout -k 10s 20s srun -N ${SLURM_NNODES} -n 4 ${cpu_bind} ${gpu_bind} gpu_check -l
	#srun -N ${SLURM_NNODES} -n 4 ${cpu_bind} ${gpu_bind} gpu_check -l

    module unload rocm
    
done
