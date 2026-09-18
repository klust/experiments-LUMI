#! /usr/bin/bash
#SBATCH --job-name=QE-25.09-N1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --time=01:00:00
#SBATCH --output=%x-%j.out.txt
#SBATCH --error=%x-%j.err.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --mem-per-gpu=60G

init-lumi-h
module purge
module load LUMI/25.09 partition/G
module load QuantumESPRESSO/7.5-cpeCray-25.09-rocm
module load lumi-CrayPath

export FI_CXI_RX_MATCH_MODE=software
export MPICH_GPU_SUPPORT_ENABLED=1
export OMP_NUM_THREADS=7

srun --cpu-bind=verbose,mask_cpu:fe000000000000,fe00000000000000,fe0000,fe000000,fe,fe00,fe00000000,fe0000000000 \
     --gpu-bind=map_gpu:0,1,2,3,4,5,6,7 --gres-flags=allow-task-sharing \
     pw.x -nk 1 -input Ta2O5-2x2xz-552-N1.in
