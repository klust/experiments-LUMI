#! /usr/bin/bash
#SBATCH --job-name=slurm-small-g-minimal-1
#SBATCH --partition=small-g
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=4
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

srun hybrid_check

srun gpu_check -l
