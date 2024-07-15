#! /usr/bin/bash
#SBATCH --job-name=slurm-small-environment-nologin
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --export=NONE
#SBATCH --time=1:00
#SBATCH --output %x-%j.txt

echo -e "Environment found:\n$(env)\n"

module list

module load LUMI/22.12


[[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'
shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'

