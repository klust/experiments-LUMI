#!/bin/bash
#SBATCH --job-name=heterogeneous_gpu_check-test
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
stack_version=${LUMI_STACK_VERSION:-'24.03'}
CPE_version=${EBVERSIONLUMIMINCPETOOLS:-'1.1-cpeCray-24.03'}
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

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

#export OMP_NUM_THREADS=4
#export OMP_PROC_BIND=close
#export OMP_PLACES=cores

echo -e "\nFound OMP variables:"
env | egrep ^OMP_


for prgenv in GNU Cray AMD
do

    echo -e "\n\n### Testing cpe${prgenv} version\n\n"
    
    #module show lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    module load lumi-CPEtools/${CPE_version}-cpe${prgenv}-${stack_version}
    #ls $EBROOTLUMIMINCPETOOLS/bin
    
    cpu_bind1="mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
	gpu_bind1="mask_gpu:0x10,0x20,0x04,0x08,0x40,0x80,0x01,0x02"
    cpu_bind2="mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
	gpu_bind2="mask_gpu:0x30,0x0c,0xc0,0x03"
	
	echo -e "\nsrun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpu-bind=${cpu_bind1} --gpu-bind=${gpu_bind1} --export=all,OMP_NUM_THREADS=2 hybrid_check -l exe1 -r : \n     --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpu-bind=${cpu_bind2} --gpu-bind=${gpu_bind2} --export=all,OMP_NUM_THREADS=4 hybrid_check -l exe2"
    timeout -k 10s 20s srun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpu-bind=${cpu_bind1} --gpu-bind=${gpu_bind1} --export=all,OMP_NUM_THREADS=2 hybrid_check -l exe1 -r : \
                            --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpu-bind=${cpu_bind2} --gpu-bind=${gpu_bind2} --export=all,OMP_NUM_THREADS=4 hybrid_check -l exe2
 
	echo -e "\nsrun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpu-bind=${cpu_bind1} --gpu-bind=${gpu_bind1} --export=all,OMP_NUM_THREADS=2 gpu_check -l exe1 -r : \n     --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpu-bind=${cpu_bind2} --gpu-bind=${gpu_bind2} --export=all,OMP_NUM_THREADS=4 gpu_check -l exe2"
    timeout -k 10s 20s srun --ntasks=$SLURM_NTASKS_HET_GROUP_0 --cpu-bind=${cpu_bind1} --gpu-bind=${gpu_bind1} --export=all,OMP_NUM_THREADS=2 gpu_check -l : \
                            --ntasks=$SLURM_NTASKS_HET_GROUP_1 --cpu-bind=${cpu_bind2} --gpu-bind=${gpu_bind2} --export=all,OMP_NUM_THREADS=4 gpu_check -l
 
    module unload rocm
    
done
