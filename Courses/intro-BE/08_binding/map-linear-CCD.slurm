#!/bin/bash
#SBATCH --account=project_46YXXXXXX
#SBATCH --job-name=map-linear-CCD
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --time=5:00

module load LUMI/24.03 partition/G lumi-CPEtools/1.2-cpeCray-24.03

# Mapping:
# | Task | CCD | HWTs           | Available HWTs | CPU mask (w/o HWTs) | GCD |
# |-----:|----:|:---------------|:---------------|--------------------:|----:|
# |    0 |   0 | 0-7, 64-71     | 1-7, 65-71     |               0xfe  |   4 |
# |    1 |   1 | 8-15, 72-79    | 9-15, 73-79    |             0xfe00  |   5 |
# |    2 |   2 | 16-23, 80-87   | 17-23, 81-87   |           0xfe0000  |   2 |
# |    3 |   3 | 24-32, 88-95   | 25-32, 89-95   |         0xfe000000  |   3 |
# |    4 |   4 | 32-39, 96-103  | 33-39, 97-103  |       0xfe00000000  |   6 |
# |    5 |   5 | 40-47, 104-111 | 41-47, 105-111 |     0xfe0000000000  |   7 |
# |    6 |   6 | 48-55, 112-119 | 49-55, 113-119 |   0xfe000000000000  |   0 |
# |    7 |   7 | 56-63, 120-127 | 57-63, 121-127 | 0xfe00000000000000  |   1 |

# Mapping from column 6 (GCD)
cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
GPU_ORDER=(4 5 2 3 6 7 0 1)
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

# Mapping from column 4 (Available HWTs)
CPU_BIND1="map_cpu:1,9,17,25,33,41,49,57"

# Mapping from column 5 (CPU masks)
CPU_BIND2="mask_cpu"
CPU_BIND2="$CPU_BIND2:0x00000000000000fe,0x000000000000fe00"
CPU_BIND2="$CPU_BIND2,0x0000000000fe0000,0x00000000fe000000"
CPU_BIND2="$CPU_BIND2,0x000000fe00000000,0x0000fe0000000000"
CPU_BIND2="$CPU_BIND2,0x00fe000000000000,0xfe00000000000000"

export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU

echo -e "\nPure MPI:\n"
sleep 0 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
sleep 5 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l
sleep 5 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID hpcat --disable-nic

echo -e "\nHybrid:\n"
sleep 5 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID hybrid_check -r
sleep 5 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID gpu_check -l
sleep 5 ; srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID hpcat --disable-nic

/bin/rm -f select_gpu_$SLURM_JOB_ID
