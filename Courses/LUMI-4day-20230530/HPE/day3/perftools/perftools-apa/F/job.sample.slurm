#!/bin/bash

#SBATCH -p haswell
#SBATCH -J himeno
#SBATCH -t 30
#SBATCH -N 1
#SBATCH --exclusive

#NOW=$(date +"%S-%M-%H-%m-%d-%Y")

# Change the name of the perftools experiment file/directory
export PAT_RT_EXPDIR_NAME=sample_exp.${SLURM_JOBID}

time srun -n 8 himeno.exe+pat > my_output.sample_exp.${SLURM_JOBID}  2>&1


