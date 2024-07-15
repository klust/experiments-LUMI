#!/bin/bash
#SBATCH --nodes=1               # number of nodes
#SBATCH --ntasks-per-node=4     # number of tasks per node
#SBATCH --cpus-per-task=8       # number of threads per task
#SBATCH --gres=gpu:4            # number of gpus per node
#SBATCH --time 0:10:00          # format: HH:MM:SS
#SBATCH -p boost_usr_prod       # partition for resource allocation
#SBATCH -A EUHPC_T_Boot-AI      # account name for allocation
#SBATCH --reservation s_tra_bootAI
#SBATCH --exclusive
  
module load profile/candidate
module load cineca-ai/4.3.0

module load profile/deeplrn
module load imagenet
  
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# export MASTER_ADDR and MASTER_PORT
...
  
# run the script
...

