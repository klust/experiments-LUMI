#!/bin/bash -l
#SBATCH --job-name=compile_test
#SBATCH --partition=small
#SBATCH --reservation=csc_proj_changes3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --hint=nomultithread
#SBATCH --time=15:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

hostname
module --version
module list

#module purge
module load LUMI/21.08
module load EasyBuild-user
module list

eb --show-config

cd $HOME/LUMI/LUMI-EasyBuild-contrib/easybuild/easyconfigs/b/BLIS
eb BLIS-3.0.1-cpeGNU-21.08.eb -f
clear-eb
