#!/bin/bash
#SBATCH --job-name=mpi-test
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00
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

echo
egrep "^#SBATCH" $0

echo
env | egrep ^SLURM

module list

CPU_BIND="map_cpu:49,57,17,25,1,9,33,41"

export MPICH_GPU_SUPPORT_ENABLED=1

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version"
    echo -e "Running 'srun --cpu-bind=${CPU_BIND} mpi_check -r' after loading the appropriate modules.\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun --cpu-bind=${CPU_BIND} mpi_check -r
    
    module unload rocm
    
done
