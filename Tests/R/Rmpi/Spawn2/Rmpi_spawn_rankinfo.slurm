#!/usr/bin/bash
#SBATCH --job-name=Rmpi_spawn_rankinfo
#SBATCH --partition=standard
#SBATCH --time=2:00
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --output=%x_%j.txt

module load LUMI/22.12 partition/C
module load R/4.2.3-cpeGNU-22.12
#module load CrayEnv
#module load cray-R/4.2.1.1

srun Rscript Rmpi_spawn_rankinfo.R

