#!/bin/bash
#SBATCH --job-name=OpenCL-test
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --partition=dev-g

rocm-smi

ml cpe/23.09
ml cpe/23.09
ml PrgEnv-gnu
ml rocm/5.2.3

echo -e "\nRunning the OpenCL demo program.\n"
./saxpy.x
