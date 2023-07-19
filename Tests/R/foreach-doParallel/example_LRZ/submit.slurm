#!/bin/bash
#SBATCH --job-name=R_foreach_doParallel_test
#SBATCH --partition=standard
#SBATCH --time=2:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --output=%x_%j.txt
 
module load LUMI/22.12 partition/C R/4.3.1-cpeGNU-22.12
#module load CrayEnv cray-R/4.2.1.1

echo -e "Running Rscript from $(which Rscript).'\n"

echo -e "\n\nStarting on 1 core.\n\n"
srun -n 1 -c 1 Rscript script_foreach_MC.R

echo -e "\n\nStarting on 4 cores.\n\n"
srun -n 1 -c 4 Rscript script_foreach_MC.R

