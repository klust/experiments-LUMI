#! /usr/bin/bash
#SBATCH --job-name=slurm-difference-sstat-sacct
#SBATCH --partition=small
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
echo -e "\nsstat for the job:\n$(sstat -j $SLURM_JOB_ID --allsteps)\n"

srun --ntasks=16 --cpus-per-task=8 --hint=nomultithread hybrid_check

srun --ntasks=32 --cpus-per-task=4 --hint=nomultithread hybrid_check

echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
echo -e "\nsstat for the job:\n$(sstat -j $SLURM_JOB_ID --allsteps)\n"
