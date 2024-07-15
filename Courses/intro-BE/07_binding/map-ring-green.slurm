#!/bin/bash
#SBATCH --job-name=map-ring-green
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

# Mapping:
# | Task | GCD | CCD | Available cores |
# |-----:|----:|----:|:----------------|
# |    0 |   0 |   6 | 49-55, 113-119  |
# |    1 |   1 |   7 | 57-63, 121-127  |
# |    2 |   3 |   3 | 25-32, 89-95    |
# |    3 |   2 |   2 | 17-23, 81-87    |
# |    4 |   4 |   0 | 1-7, 65-71      |
# |    5 |   5 |   1 | 9-15, 73-79     |
# |    6 |   7 |   5 | 41-47, 105-111  |
# |    7 |   6 |   4 | 33-39, 97-103   |

cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
GPU_ORDER=(0 1 3 2 4 5 7 6)
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

CPU_BIND1="map_cpu:49,57,25,17,1,9,41,33"

CPU_BIND2="mask_cpu"
CPU_BIND2="$CPU_BIND2:0x00fe000000000000,0xfe00000000000000"
CPU_BIND2="$CPU_BIND2,0x00000000fe000000,0x0000000000fe0000"
CPU_BIND2="$CPU_BIND2,0x00000000000000fe,0x000000000000fe00"
CPU_BIND2="$CPU_BIND2,0x0000fe0000000000,0x000000fe00000000"

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

export MPICH_GPU_SUPPORT_ENABLED=0

echo -e "\nPure MPI:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l

echo -e "\nHybrid:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID hybrid_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
