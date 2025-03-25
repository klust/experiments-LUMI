#!/bin/bash
#SBATCH --job-name=cpu-numbering-demo1
#SBATCH --output %x-%j.txt
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/24.03 partition/C lumi-CPEtools/1.2-cpeGNU-24.03

cat << EOF > task_lstopo_$SLURM_JOB_ID
#!/bin/bash
echo "Task \$SLURM_LOCALID"                            > output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "Output of lstopo:"                              >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
lstopo -p                                             >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
echo "Taskset of current shell: \$(taskset -p \$\$)"  >> output-\$SLURM_JOB_ID-\$SLURM_LOCALID
EOF

chmod +x ./task_lstopo_$SLURM_JOB_ID

echo -e "\nFull lstopo output in the job:\n$(lstopo -p)\n\n"
echo -e "Taskset of the current shell: $(taskset -p $$)\n"

echo "Running two tasks on 4 cores each, extracting parts from lstopo output in each:"
srun -n 2 -c 4 ./task_lstopo_$SLURM_JOB_ID
echo
cat output-$SLURM_JOB_ID-0
echo
cat output-$SLURM_JOB_ID-1

echo -e "\nRunning hybrid_check in the same configuration::"
srun -n 2 -c 4 hybrid_check -r

/bin/rm task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-0 output-$SLURM_JOB_ID-1
