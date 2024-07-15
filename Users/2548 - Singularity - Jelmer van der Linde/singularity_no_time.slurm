#!/usr/bin/bash
#
#SBATCH --partition=small
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00
#SBATCH --job-name=singularity-no-time
#SBATCH --output %x-%j.txt

echo -e "\nSlurm variables:\n"
env | grep -e ^SLURM

echo -e "\nSingularity binary: $(which singularity)"

echo -e "\nTry a cat of a file on scratch with singularity\n"
singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cat /scratch/project_462000008/kurtlust/README.txt

echo -e "\nTry a cp from a file on scratch with singularity.\n"
singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cp -f /scratch/project_462000008/kurtlust/README.txt /scratch/project_462000008/kurtlust/README2.txt

echo -e "\nReached the end of the job script.\n"
