#!/bin/bash

#SBATCH --account=EUHPC_T_Boot-AI
#SBATCH --reservation=s_tra_bootAI
#SBATCH --job-name=1gpu_100
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH --time=01:30:00
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --partition=boost_usr_prod

module load profile/candidate
module load cineca-ai/4.3.0

wandb disabled

python ft_imdb_distilbert_complete.py

echo "END"
