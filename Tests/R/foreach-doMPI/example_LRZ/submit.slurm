#!/usr/bin/bash
#SBATCH --job-name=R_foreach_SNOW_test
#SBATCH --partition=small
#SBATCH --time=5:00
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --output=%x_%j.txt

module load LUMI/23.09 partition/C
module load R/4.3.2-cpeGNU-23.09

echo -e "\\n# Running on 2 task\n\n"
srun -n 2 Rscript script_foreach_MPI.R

echo -e "\\n# Running on 3 task\n\n"
srun -n 3 Rscript script_foreach_MPI.R

echo -e "\\n# Running on 4 task\n\n"
srun -n 4 Rscript script_foreach_MPI.R

echo -e "\\n# Running on $((SLURM_NTASKS + 1)) tasks\n\n"
srun -n $((SLURM_NTASKS + 1)) -O Rscript script_foreach_MPI.R
