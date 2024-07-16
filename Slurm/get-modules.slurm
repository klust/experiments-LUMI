#!/bin/bash -l
#SBATCH --job-name=get_modules
#SBATCH --partition=small
#SBATCH --reservation=csc_proj_changes3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

hostname
module --version
module list

module load LUMI
module list

module purge
module load LUMI

module load gzip/1.10-cpeGNU-21.08
which gzip
$EBROOTGZIP/bin/gzip testgzip.txt

