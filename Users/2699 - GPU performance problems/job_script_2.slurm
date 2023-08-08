#!/bin/bash -l
#SBATCH --job-name=test-gpu-binding-2
#SBATCH --output=%x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=8
#SBATCH --gpus-per-node=8
#SBATCH --time=0-00:5:00

#module load PrgEnv-cray
#module load craype-accel-amd-gfx90a
#module load rocm
#module load cray-python/3.9.12.1
module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

export MPICH_GPU_SUPPORT_ENABLED=1

cat << EOF > select_gpu-$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x ./select_gpu-$SLURM_JOB_ID

CPU_BIND="map_cpu:49,57,17,25,1,9,33,41"

set -x
srun --cpu-bind=${CPU_BIND} gpu_check -l

srun --cpu-bind=${CPU_BIND} ./select_gpu-$SLURM_JOB_ID gpu_check -l

srun --cpu-bind=${CPU_BIND} ./test_GPU.x | sort

srun --cpu-bind=${CPU_BIND} ./select_gpu-$SLURM_JOB_ID ./test_GPU_mapping.x | sort
set +x

/bin/rm select_gpu-$SLURM_JOB_ID
