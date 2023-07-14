#!/bin/bash
#SBATCH --job-name=heterogeneous_gpu_check-test-small
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt
#SBATCH --partition=small-g
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH hetjob
#SBATCH --partition=small-g
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=6
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
export OMP_PLACES=cores
export OMP_PROC_BIND=true

echo -e "\nFound OMP variables:"
env | egrep ^OMP_

export MPICH_GPU_SUPPORT_ENABLED=1

for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version"

    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    
    echo -e "Running/nsrun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_0 hybrid_check -l exe1 -r : \n     --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_1 hybrid_check -l exe2\n"
    srun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_0 hybrid_check -l exe1 -r : \
         --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_1 hybrid_check -l exe2

    echo -e "Running:\nsrun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_0 gpu_check -l : \n     --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_1 gpu_check -l'\n"
    srun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_0 gpu_check -l : \
         --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 --gpus-per-task=$SLURM_GPUS_PER_TASK_HET_GROUP_1 gpu_check -l
    
 
    module unload rocm
    
done
