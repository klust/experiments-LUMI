#! /usr/bin/env bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00
#SBATCH --partition=debug

# Initialize the LUMI software stack as this is not yet automatic.
echo "Reading bash_functions.sh..."
source $HOME/.bash_functions.sh
echo "Initializing the software stack..."
init-lumi-h

echo "Loading the modules..."
module load LUMI/21.08 partition/L
module load GROMACS/2020.4-cpeGNU-21.08-PLUMED-2.6.4-CPU

echo -e "\n\nCan I find GROMACS?"
which gmx_mpi_d

echo -e "\n\nAnd let's check the environment..."
env
