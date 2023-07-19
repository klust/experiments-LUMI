#!/bin/bash
#SBATCH --job-name=R_parallel_test
#SBATCH --partition=small
#SBATCH --time=2:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --output=%x_%j.txt
 
module load LUMI/22.12 partition/C R/4.3.1-cpeGNU-22.12
#module load CrayEnv cray-R/4.2.1.1

echo -e "Running Rscript from $(which Rscript).'\n"

srun Rscript script_parallel.R
