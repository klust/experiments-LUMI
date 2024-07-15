#!/bin/bash
#SBATCH --job-name=binding
#SBATCH --ntasks=8
#SBATCH --ntasks-per-node=8
##SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=8
#SBATCH --time=00:05:00
#SBATCH -p pilot
#SBATCH --output=bind_%j.out
#SBATCH --error=bind_%j.err
##SBATCH -A project_462000008

MASKS="ff000000000000,ff00000000000000,ff0000,ff000000,ff,ff00,ff00000000,ff0000000000"
#MASKS="00ff000000000000,ff00000000000000,0000000000ff0000,00000000ff000000,00000000000000ff,000000000000ff00,000000ff00000000,0000ff0000000000"

srun -N 1 -n 8 -c 8  --cpu-bind=v,mask_cpu:$MASKS bash -c 'ROCR_VISIBLE_DEVICES=$SLURM_PROCID ; echo "--> Rank $SLURM_PROCID - GPUs $ROCR_VISIBLE_DEVICES - $(taskset -p $$)"'


