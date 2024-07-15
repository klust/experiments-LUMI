#!/bin/bash
#SBATCH --job-name=map-linear-GCD
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

cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

CPU_BIND1="map_cpu:49,57,17,25,1,9,33,41"

CPU_BIND2="mask_cpu:0xfe000000000000,0xfe00000000000000"
CPU_BIND2="$CPU_BIND2,0xfe0000,0xfe000000"
CPU_BIND2="$CPU_BIND2,0xfe,0xfe00"
CPU_BIND2="$CPU_BIND2,0xfe00000000,0xfe0000000000"

export MPICH_GPU_SUPPORT_ENABLED=0

echo -e "\nPure MPI:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l

echo -e "\nHybrid:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID hybrid_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND2 ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
