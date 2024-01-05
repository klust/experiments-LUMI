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
srun -W 10 -n 2 $EBROOTR/lib/R/library/snow/RMPISNOW <script_foreach_SNOW.R

echo -e "\\n# Running on 3 task\n\n"
srun -W 10 -n 3 $EBROOTR/lib/R/library/snow/RMPISNOW <script_foreach_SNOW.R

echo -e "\\n# Running on 4 tasks\n\n"
srun -W 10 -n 4 $EBROOTR/lib/R/library/snow/RMPISNOW <script_foreach_SNOW.R

echo -e "\\n# Running on $((SLURM_NTASKS + 1)) tasks\n\n"
srun -W 10 -n $((SLURM_NTASKS + 1)) -O $EBROOTR/lib/R/library/snow/RMPISNOW <script_foreach_SNOW.R
