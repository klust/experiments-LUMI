#! /bin/bash
#SBATCH --job-name=map-smallg-1gpt
#SBATCH --output %x-%j.txt
#SBATCH --partition=small-g
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x ./select_gpu_$SLURM_JOB_ID

cat << EOF > echo_dev_$SLURM_JOB_ID
#!/bin/bash
printf -v task "%02d" \$SLURM_PROCID
echo "Task \$task or node.local_id \$SLURM_NODEID.\$SLURM_LOCALID sees ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"
EOF
chmod +x ./echo_dev_$SLURM_JOB_ID

set -x
srun gpu_check -l
srun ./echo_dev_$SLURM_JOB_ID | sort
srun --gpu-bind=none ./echo_dev_$SLURM_JOB_ID | sort
srun --gpu-bind=none ./select_gpu_$SLURM_JOB_ID ./echo_dev_$SLURM_JOB_ID | sort
srun --gpu-bind=none ./select_gpu_$SLURM_JOB_ID gpu_check -l
set +x

/bin/rm -f select_gpu_$SLURM_JOB_ID echo_dev_$SLURM_JOB_ID