#!/bin/bash
#SBATCH --job-name=gpu-numbering-demo2
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

cat << EOF > select_1gpu_$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x ./select_1gpu_$SLURM_JOB_ID

cat << EOF > task_lstopo_$SLURM_JOB_ID
#!/bin/bash
sleep \$((SLURM_LOCALID * 5))
echo "Task \$SLURM_LOCALID"                                                   > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "Relevant lines of lstopo:"                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
lstopo -p | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
EOF
chmod +x ./task_lstopo_$SLURM_JOB_ID

# Start a background task to pick GPUs with global numbers 0 and 1
srun -n 1 -c 1 --gpus=2 sleep 60 &
sleep 5

set -x
srun -n 4 -c 1 --gpus=4 ./task_lstopo_$SLURM_JOB_ID
set +x

cat output-$SLURM_JOB_ID-0

set -x
srun -n 4 -c 1 --gpus=4 ./select_1gpu_$SLURM_JOB_ID gpu_check -l
set +x

wait

/bin/rm select_1gpu_$SLURM_JOB_ID task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-*
