#!/bin/bash
#SBATCH --job-name=map-linear-CCD-cpt2
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
GPU_ORDER=(4 5 2 3 6 7 0 1)
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID


export MPICH_GPU_SUPPORT_ENABLED=0

echo -e "\nPure MPI:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpus-per-task=1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
OMP_NUM_THREADS=1 srun --ntasks=$((SLURM_NNODES*8)) --cpus-per-task=7 ./select_gpu_$SLURM_JOB_ID gpu_check -l

echo -e "\nHybrid with 4 threads per task:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpus-per-task=4 ./select_gpu_$SLURM_JOB_ID hybrid_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpus-per-task=4 ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
