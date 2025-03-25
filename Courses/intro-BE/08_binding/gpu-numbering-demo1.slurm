#!/bin/bash
#SBATCH --job-name=gpu-numbering-demo1
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=15:00

module load LUMI/24.03 partition/G lumi-CPEtools/1.2-cpeCray-24.03

cat << EOF > task_lstopo_$SLURM_JOB_ID
#!/bin/bash
echo "Task \$SLURM_LOCALID"                                                   > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "Relevant lines of lstopo:"                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
lstopo -p | awk '/ PCI.*Display/ || /GPU/ || / Core / || /PU L/ {print \$0}' >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                          >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
EOF
chmod +x ./task_lstopo_$SLURM_JOB_ID

echo -e "\nFull lstopo output in the job:\n$(lstopo -p)\n\n"
echo -e "Extract GPU info:\n$(lstopo -p | awk '/ PCI.*Display/ || /GPU/ {print $0}')\n" 
echo "ROCR_VISIBLE_DEVICES at the start of the job script: $ROCR_VISIBLE_DEVICES"

echo "Running two tasks with 4 GPUs each, extracting parts from lstopo output in each:"
srun -n 2 -c 1 --gpus-per-task=4 ./task_lstopo_$SLURM_JOB_ID
echo
cat output-$SLURM_JOB_ID-0
echo
cat output-$SLURM_JOB_ID-1

echo -e "\nRunning gpu_check in the same configuration::"
srun -n 2 -c 1 --gpus-per-task=4 gpu_check -l

/bin/rm task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-0 output-$SLURM_JOB_ID-1
