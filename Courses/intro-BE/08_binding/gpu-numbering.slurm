#!/bin/bash
#SBATCH --job-name=gpu-numbering
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=15:00
#SBATCH --output %x-%j.txt

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


set -x
lstopo

OMP_NUM_THREADS=1 gpu_check

srun -n 1 -c 1 --gpus=8 gpu_check -l

# The next one does not work as Slurm resets ROCR_VISIBLE_DEVICES
ROCR_VISIBLE_DEVICES="0,4" srun -n 1 -c 1 --gpus=8 ./echo_ROCR_$SLURM_JOB_ID gpu_check -l

srun -n 1 -c 1 --gpus=4 gpu_check -l

srun -n 1 -c 1 --gpus-per-task=4 gpu_check -l

srun -n 1 -c 1 --gpus-per-task=4 bash -c 'echo $ROCR_VISIBLE_DEVICES'

srun -n 1 -c 1 --gpus-per-task=4 lstopo

srun -n 2 -c 1 --gpus-per-task=4 ./echo_ROCR_$SLURM_JOB_ID gpu_check -l

srun -n 2 -c 1 --gpus-per-task=4  ./select_specialgpu_$SLURM_JOB_ID gpu_check -l

srun -n 2 -c 1 --gpus=8 ./select_1gpu_$SLURM_JOB_ID gpu_check -l

#gpu_check -h

set +x
/bin/rm echo_ROCR_$SLURM_JOB_ID
/bin/rm select_1gpu_$SLURM_JOB_ID
/bin/rm select_specialgpu_$SLURM_JOB_ID
sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID -o JobID%14,AllocCPUS,State,ExitCode,Elapsed)\n"

