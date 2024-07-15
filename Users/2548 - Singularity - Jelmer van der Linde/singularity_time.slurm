#!/usr/bin/bash
#
#SBATCH --partition=small
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00
#SBATCH --job-name=singularity-time
#SBATCH --output %x-%j.txt

echo -e "\nSlurm variables:\n"
env | grep -e ^SLURM

echo -e "\nSingularity binary: $(which singularity)"

echo -e "\nTry a cat of a file on scratch with singularity\n"
singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cat /scratch/project_462000008/kurtlust/README.txt

echo -e "\nTry a cat of a file on scratch with singularity and a simple time statement\n"
/usr/bin/time singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cat /scratch/project_462000008/kurtlust/README.txt

echo -e "\nTry a cat of a file on scratch with singularity and a the modified long time statement\n"
/usr/bin/time -f '{"task":"cat-experiment", "time":{"user":"%U", "system":"%S", "elapsed":"%E", "cpu":"%P", "max":%M, "major":%F, "minor":%R}}' singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cat /scratch/project_462000008/kurtlust/README.txt

echo -e "\nTry a cat of a file on scratch with singularity and the user long time statement\n"
/usr/bin/time -f '{"task":"docalign", "pair":{"shard": "2", "mt":1, "en":1}, "time":{"user":"%U", "system":"%S", "elapsed":"%E", "cpu":"%P", "text":%X, "data":%D, "max":%M, "inputs":%I, "output":%O, "major":%F, "minor":%R, "swaps":%W}}' singularity exec -B /scratch/project_462000008 /project/project_462000008/kurtlust/Singularity/Julia/julia_latest.sif cat /scratch/project_462000008/kurtlust/README.txt

echo -e "\nReached the end of the job script.\n"
