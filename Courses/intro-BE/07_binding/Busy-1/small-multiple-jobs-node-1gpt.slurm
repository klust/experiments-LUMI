#! /bin/bash
#SBATCH --job-name=small-multiple-jobs-node-1gpt
#SBATCH --output %x-%j.txt
#SBATCH --partition=spec-small
#SBATCH --ntasks=10
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

set -x
srun gpu_check -l
set +x
sleep 30

/bin/rm -f select_gpu_$SLURM_JOB_ID echo_dev_$SLURM_JOB_ID