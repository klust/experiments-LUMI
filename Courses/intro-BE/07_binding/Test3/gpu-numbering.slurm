#!/bin/bash
#SBATCH --job-name=gpu-numbering
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=15:00
#SBATCH --output %x-%j.txt

module use /appl/lumi/modules/init-LUMI-SoftwareStack
module use /appl/lumi/modules/SoftwareStack
module load init-lumi
module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:'\$(cat $0)\n"
echo "SLURM_*, SRUN_*, ROCR_* environment variables:"
env | egrep ^SLURM_
env | egrep ^SRUN_
env | egrep ^ROCR_

cat << EOF > echo_ROCR_$SLURM_JOB_ID
#!/bin/bash
echo "Task \$SLURM_LOCALID found ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"

exec \$*
EOF

chmod +x ./echo_ROCR_$SLURM_JOB_ID

cat << EOF > select_1gpu_$SLURM_JOB_ID
#!/bin/bash
echo "Task \$SLURM_LOCALID found ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"

export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x ./select_1gpu_$SLURM_JOB_ID

cat << EOF > select_specialgpu_$SLURM_JOB_ID
#!/bin/bash
echo "Task \$SLURM_LOCALID found ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"

export ROCR_VISIBLE_DEVICES=2
exec \$*
EOF
chmod +x ./select_specialgpu_$SLURM_JOB_ID

function echo_cmd {
    echo -e "CMD: $*\n"
    eval $*
}

echo -e "\n## Whole node topology\n"
echo_cmd lstopo

echo_cmd OMP_NUM_THREADS=1 gpu_check

echo -e "\n##Single task single thread with all GPUs in a node.\n"
echo_cmd srun -n 1 -c 1 --gpus=8 gpu_check -l

# The next one does not work as Slurm resets ROCR_VISIBLE_DEVICES
echo -e "\n## Show that Slurm sets ROCR_VISIBLE_DEVICES when using srun\n"
echo_cmd ROCR_VISIBLE_DEVICES="0,4" srun -n 1 -c 1 --gpus=8 ./echo_ROCR_$SLURM_JOB_ID gpu_check -l

echo -e "\n## Single task single thread with 4 GPUs requested with --gpus.\n"
echo_cmd srun -n 1 -c 1 --gpus=4 gpu_check -l

echo -e "\n## Single task single thread with 4 GPUs requested with --gpus-per-task: gpu_check, extra verification ROCR_VISIBLE_DEVICES, topo check..\n"
echo_cmd srun -n 1 -c 1 --gpus-per-task=4 gpu_check -l

set -x
srun -n 1 -c 1 --gpus-per-task=4 bash -c 'echo $ROCR_VISIBLE_DEVICES'
set +x

echo_cmd srun -n 1 -c 1 --gpus-per-task=4 lstopo

echo -e "\n## Two tasks each one core and 4 GPUs with --gpus-per-task.\n"
echo_cmd srun -n 2 -c 1 --gpus-per-task=4 ./echo_ROCR_$SLURM_JOB_ID gpu_check -l

echo -e "\n## Two tasks each one core and 4 GPUs, then further restrict GPU to GPU 2 for each task.\n"
echo_cmd srun -n 2 -c 1 --gpus-per-task=4  ./select_specialgpu_$SLURM_JOB_ID gpu_check -l

echo -e "\n## Two tasks, using --gpus=8, then selecting GPU based on SLURM_LOCALID. Note that both tasks see all GPUs befor select_1gpu\n"
echo_cmd srun -n 2 -c 1 --gpus=8 ./select_1gpu_$SLURM_JOB_ID gpu_check -l

#gpu_check -h

/bin/rm echo_ROCR_$SLURM_JOB_ID
/bin/rm select_1gpu_$SLURM_JOB_ID
/bin/rm select_specialgpu_$SLURM_JOB_ID
sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID -o JobID%14,AllocCPUS,State,ExitCode,Elapsed)\n"

