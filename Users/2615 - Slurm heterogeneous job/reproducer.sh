#! /usr/bin/bash
#=============================================================================

# Lumi het batch job parameters
# --------------------------------

#SBATCH --job-name=hetgpucpu
#SBATCH --output=LOG.%x.%j.txt
#SBATCH --error=LOG.%x.%j.txt
#SBATCH --exclusive
#SBATCH --time=00:01:00
#=============================================================================
#
# LUMI-G: atmosphere computation (het_group_0)
#
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --gpus-per-node=8
#SBATCH --tasks-per-node=8
#______________________________________________________________________________
#
#SBATCH hetjob
#______________________________________________________________________________
#
# LUMI-C: ocean computation (het_group_1)
#
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=4
#
#=============================================================================

set +x

touch a.out

chmod 755 ./a.out

srun \
     -n 8 \
     a.out \
     : \
     -n 32 \
     a.out

     