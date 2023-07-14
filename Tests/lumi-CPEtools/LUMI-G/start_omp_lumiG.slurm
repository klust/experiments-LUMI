#!/bin/bash
#SBATCH --job-name=omp-test
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=7
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

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

echo -e "\nFound OMP variables:"
env | egrep ^OMP_

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version"
    echo -e "Running 'srun omp_check -r' after loading the appropriate modules.\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun omp_check -r
    
    module unload rocm
    
done
