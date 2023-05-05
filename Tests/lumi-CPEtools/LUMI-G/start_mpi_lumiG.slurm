#!/bin/bash
#SBATCH --job-name=mpi-test
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --gpus-per-task=1
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

CPU_BIND="map_cpu:49,57,17,25,1,9,33,41"

export MPICH_GPU_SUPPORT_ENABLED=1

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun --cpu-bind=${CPU_BIND} mpi_check -r
    
    module unload rocm
    
done
