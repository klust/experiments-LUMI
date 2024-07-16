#!/bin/bash -l
#SBATCH --job-name=seissol-gpu        # Job name
#SBATCH --output=y-seissol-gpu.o      # Name of stdout output file
#SBATCH --error=y-seissol-gpu.e       # Name of stderr error file
#SBATCH --partition=standard-g        # Partition (queue) name
#SBATCH --nodes=1                     # Total number of nodes 
#SBATCH --ntasks-per-node=8           # 8 MPI ranks per node, 128 total (16x8)
#SBATCH --gpus-per-node=8             # Allocate one gpu per MPI rank
#SBATCH --time=00:05:00               # Run time (d-hh:mm:ss)
#SBATCH --mail-user=kurt.lust@uantwerpen.be

####SBATCH --cpus-per-task=6             # 6 threads per ranks

export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH

cat << EOF > select_gpu
#!/bin/bash

export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF

chmod +x ./select_gpu


CPU_BIND="mask_cpu"
CPU_BIND="${CPU_BIND}:007e000000000000"
CPU_BIND="${CPU_BIND},7e00000000000000"
CPU_BIND="${CPU_BIND},00000000007e0000"
CPU_BIND="${CPU_BIND},000000007e000000"
CPU_BIND="${CPU_BIND},000000000000007e"
CPU_BIND="${CPU_BIND},0000000000007e00"
CPU_BIND="${CPU_BIND},0000007e00000000"
CPU_BIND="${CPU_BIND},00007e0000000000"

export OMP_NUM_THREADS=6
export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

module load LUMI/22.08 partition/G
module load lumi-CPEtools/1.0-cpeGNU-22.08

srun --cpu-bind=${CPU_BIND} ./select_gpu hybrid_check

rm -rf ./select_gpu


