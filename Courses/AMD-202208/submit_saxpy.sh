#!/bin/bash
#SBATCH --job-name=saxpy
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus=1
#SBATCH --time=00:05:00
#SBATCH -p eap
#SBATCH --output=saxpy.out
#SBATCH --error=saxpy.err
##SBATCH -A project_462000008

MASKS="ff000000000000,ff00000000000000,ff0000,ff000000,ff,ff00,ff00000000,ff0000000000"

module load LUMI/22.06
module load rocm

srun -n 1  bash -c 'ROCR_VISIBLE_DEVICES=$SLURM_PROCID ./saxpy'
