#!/bin/bash
#SBATCH --job-name=heterogeneous-test
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH hetjob
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gpus-per-task=2
#SBATCH --hint=nomultithread

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

#export OMP_NUM_THREADS=4
#export OMP_PLACES=cores
#export OMP_PROC_BIND=true

echo -e "\nFound OMP variables:"
env | egrep ^OMP_

CPU_BIND1="mask_cpu:fe000000000000,fe00000000000000"
CPU_BIND1="${CPU_BIND1},fe0000,fe000000"
CPU_BIND1="${CPU_BIND1},fe,fe00"
CPU_BIND1="${CPU_BIND1},fe00000000,fe0000000000"
CPU_BIND2="mask_cpu:fefe000000000000"
CPU_BIND2="${CPU_BIND2},fefe0000"
CPU_BIND2="${CPU_BIND2},fefe"
CPU_BIND2="${CPU_BIND2},fefe00000000"

export MPICH_GPU_SUPPORT_ENABLED=1

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version"
    echo -e "Running 'srun --ntasks=8 --cpu-bind=${CPU_BIND1} --export=all,OMP_NUM_THREADS=2 hybrid_check -l exe1 -r : \n              --ntasks=4 --cpu-bind=${CPU_BIND2} --export=all,OMP_NUM_THREADS=4 hybrid_check -l exe2' after loading the appropriate modules.\n\n"

    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    srun --ntasks=8 --cpu-bind=${CPU_BIND1} --export=all,OMP_NUM_THREADS=2 hybrid_check -l exe1 -r : \
         --ntasks=4 --cpu-bind=${CPU_BIND2} --export=all,OMP_NUM_THREADS=4 hybrid_check -l exe2
    
    
    module unload rocm
    
done
