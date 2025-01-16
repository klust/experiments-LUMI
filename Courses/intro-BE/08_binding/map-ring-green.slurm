#!/bin/bash
#SBATCH --account=project_46YXXXXXX
#SBATCH --job-name=map-ring-green
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --time=5:00

module load LUMI/24.03 partition/G lumi-CPEtools/1.2-cpeCray-24.03

# Mapping:
# | Task | GCD | CCD | Available cores | CPU mask (w/o HWTs) |
# |-----:|----:|----:|:----------------|--------------------:|
# |    0 |   0 |   6 | 49-55, 113-119  |   0xfe000000000000  |
# |    1 |   1 |   7 | 57-63, 121-127  | 0xfe00000000000000  |
# |    2 |   3 |   3 | 25-32, 89-95    |         0xfe000000  |
# |    3 |   2 |   2 | 17-23, 81-87    |           0xfe0000  |
# |    4 |   4 |   0 | 1-7, 65-71      |               0xfe  |
# |    5 |   5 |   1 | 9-15, 73-79     |             0xfe00  |
# |    6 |   7 |   5 | 41-47, 105-111  |     0xfe0000000000  |
# |    7 |   6 |   4 | 33-39, 97-103   |       0xfe00000000  |

# Mapping from column 2 (GCD)
cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
# GPU order: Column 2 of the table
GPU_ORDER=(0 1 3 2 4 5 7 6)
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

# Core order: Column 4 (Available cores)
CPU_BIND1="map_cpu:49,57,25,17,1,9,41,33"

# Mask: Column 5 of the table, top to bottom, or column 3 (CCD) for the trick we use here.
CCD_MASK=( 0x00000000000000fe \
           0x000000000000fe00 \
           0x0000000000fe0000 \
           0x00000000fe000000 \
           0x000000fe00000000 \
           0x0000fe0000000000 \
           0x00fe000000000000 \
           0xfe00000000000000 )
CPU_BIND2="mask_cpu"
CPU_BIND2="$CPU_BIND2:${CCD_MASK[6]},${CCD_MASK[7]}"
CPU_BIND2="$CPU_BIND2,${CCD_MASK[3]},${CCD_MASK[2]}"
CPU_BIND2="$CPU_BIND2,${CCD_MASK[0]},${CCD_MASK[1]}"
CPU_BIND2="$CPU_BIND2,${CCD_MASK[5]},${CCD_MASK[4]}"

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
