#! /usr/bin/bash
#SBATCH --job-name=slurm-small-parameters
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=1:00
#SBATCH --output %x-%j.txt

echo "Batch script parameter 0: $0"
echo "Batch script parameter 1: $1"
echo "Environment variable PAR1: $PAR1"

env | egrep ^PAR
