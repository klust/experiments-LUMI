#!/bin/bash
#SBATCH --job-name=hpcat-test
#SBATCH --partition=standard-g
#SBATCH --nodes=2
#SBATCH --gpus-per-node=8
#SBATCH --hint=nomultithread
#SBATCH --time=15:00
#SBATCH --output %x-%j.txt
## The following line does not work as it seems not to pass other variables that are 
## important to clean the environment.
###SBATCH --export=LUMI_STACK_VERSION,EBVERSIONLUMIMINCPETOOLS

echo "Read from the environment: LUMI_STACK_VERSION = ${LUMI_STACK_VERSION}, EBVERSIONLUMIMINCPETOOLS = ${EBVERSIONLUMIMINCPETOOLS}."
stack_version=${LUMI_STACK_VERSION:-'24.03'}
hpcat_version=${EBVERSIONHPCAT:-'0.8'}
echo -e "Running with hpcat/${hpcat_version}-cpe*-${stack_version}\n"

init-lumi-h
module load LUMI/$stack_version partition/G

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

echo
egrep "^#SBATCH" $0

echo
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
    
    #module show hpcat/${hpcat_version}-cpe${prgenv}-${stack_version}
    module load hpcat/${hpcat_version}-cpe${prgenv}-${stack_version}
    #ls $EBROOTLUMIMINCPETOOLS/bin
    
    cpu_bind="--cpu-bind=mask_cpu:0xfefe,0xfefe0000,0xfefe00000000,0xfefe000000000000"
	gpu_bind="--gpu-bind=mask_gpu:0x03,0x0c,0x30,0xc0"
	
	export MPICH_OFI_NIC_POLICY=NUMA
	
	echo "CPU bind argument: $cpu_bind"
	echo "GPU binding: $gpu_bind"
	
	echo -e "\nsrun -N ${SLURM_NNODES} -n $((4*SLURM_NNODES)) ${cpu_bind} ${gpu_bind} hpcat"
	timeout -k 10s 20s srun -N ${SLURM_NNODES} -n $((4*SLURM_NNODES)) ${cpu_bind} ${gpu_bind} hpcat

    module unload rocm
    
done
