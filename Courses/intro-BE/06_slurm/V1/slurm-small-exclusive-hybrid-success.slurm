#! /usr/bin/bash
#SBATCH --job-name=slurm-small-exlcusive-hybrid-success
#SBATCH --partition=small
#SBATCH --exclusive
#SBATCH --nodes=2
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:'\$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

srun --ntasks=8 --cpus-per-task=8 --hint=nomultithread hybrid_check : \
     --ntasks=16 --cpus-per-task=4 --hint=nomultithread hybrid_check

sleep 5
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID -o JobID%14,AllocCPUS,State,ExitCode,Elapsed)\n"
