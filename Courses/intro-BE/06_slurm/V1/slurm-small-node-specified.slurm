#! /usr/bin/bash
#SBATCH --job-name=slurm-small-node-specified
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

srun hybrid_check
