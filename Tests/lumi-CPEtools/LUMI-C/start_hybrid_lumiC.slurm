#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=4
#SBATCH --hint=multithread
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt
## The following line does not work as it seems not to pass other variables that are 
## important to clean the environment.
###SBATCH --export=LUMI_STACK_VERSION,EBVERSIONLUMIMINCPETOOLS

echo "Read from the environment: LUMI_STACK_VERSION = ${LUMI_STACK_VERSION}, EBVERSIONLUMIMINCPETOOLS = ${EBVERSIONLUMIMINCPETOOLS}."
stack_version=${LUMI_STACK_VERSION:-'24.03'}
CPE_version=${EBVERSIONLUMIMINCPETOOLS:-'1.1-cpeCray-24.03'}
CPE_version=${CPE_version%-cpe*}
echo -e "Running with lumi-CPEtools/${CPE_version}-cpe*-${stack_version}\n"

#init-lumi-h
module load LUMI/$stack_version partition/C

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

for prgenv in GNU Cray AOCC
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun hybrid_check -r
    
done
