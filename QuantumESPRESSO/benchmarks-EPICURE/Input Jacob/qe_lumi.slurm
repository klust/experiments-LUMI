#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --time=02:00:00
#SBATCH --output=qe.out
#SBATCH --error=qe.err
#SBATCH --account=project_465003188
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --mem-per-gpu=60G

export FI_CXI_RX_MATCH_MODE=software
export MPICH_GPU_SUPPORT_ENABLED=1
export OMP_NUM_THREADS=7

export EBU_USER_PREFIX=/project/project_465003188/EasyBuild/
module purge
module load LUMI/25.09 partition/G
module load QuantumESPRESSO/7.5-cpeCray-25.09-rocm
module load lumi-CrayPath


srun --cpu-bind=verbose,mask_cpu:fe000000000000,fe00000000000000,fe0000,fe000000,fe,fe00,fe00000000,fe0000000000 --gpu-bind=map_gpu:0,1,2,3,4,5,6,7 --gres-flags=allow-task-sharing pw.x -nk 1 -input Ta2O5-2x2xz-552.in
