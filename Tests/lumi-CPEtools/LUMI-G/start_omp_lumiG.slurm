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

#init-lumi-h
stack_version='22.12'
CPE_version='1.0'

module load LUMI/$stack_version partition/G

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

#export OMP_NUM_THREADS=8
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

env | egrep ^OMP_

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun omp_check -r
    
    module unload rocm
    
done
