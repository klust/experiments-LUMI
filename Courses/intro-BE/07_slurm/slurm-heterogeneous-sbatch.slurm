#! /usr/bin/bash
#SBATCH --job-name=slurm-herterogeneous-sbatch
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=4
#SBATCH hetjob
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=32

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

srun --het-group=0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0  --export=ALL,OMP_NUM_THREADS=4  hybrid_check -l app_A : \
     --het-group=1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 --export=ALL,OMP_NUM_THREADS=32 hybrid_check -l app_B

srun --het-group=0 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_0 hybrid_check -l hybrid_check -l app_A : \
     --het-group=1 --cpus-per-task=$SLURM_CPUS_PER_TASK_HET_GROUP_1 hybrid_check -l hybrid_check -l app_B

echo "Now testing with srun environment variables."

for namevalue in $(env | egrep ^SLURM_CPUS_PER_TASK)
do
    name=${namevalue%=*}
    name=${name/SLURM_/SRUN_}
    value=${namevalue#*=}
    eval "$name=$value"
    export $name
done

srun --het-group=0 hybrid_check -l hybrid_check -l app_A : \
     --het-group=1 hybrid_check -l hybrid_check -l app_B

export SRUN_CPUS_PER_TASK_PACK_GROUP_0=4
export SRUN_CPUS_PER_TASK_PACK_GROUP_1=32
export SRUN_CPUS_PER_TASK_HET_GROUP_0=4
export SRUN_CPUS_PER_TASK_HET_GROUP_1=32

srun --het-group=0 hybrid_check -l hybrid_check -l app_A : \
     --het-group=1 hybrid_check -l hybrid_check -l app_B

echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
