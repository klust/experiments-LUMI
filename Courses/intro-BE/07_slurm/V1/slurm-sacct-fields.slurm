#! /usr/bin/bash
#SBATCH --job-name=slurm-sacct-fields
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

srun --ntasks=16 --cpus-per-task=8 --hint=nomultithread hybrid_check -w 10

srun --ntasks=32 --cpus-per-task=4 --hint=nomultithread hybrid_check -w 10

sleep 10

echo -e "\nExample use of sacct\n"

set -x
sacct -j $SLURM_JOB_ID -o JobID%14,JobName%30,AllocCPUS,State,ExitCode,Elapsed,AveCPU,MinCPU,MinCPUTask,MaxRSS,MaxVMSize
