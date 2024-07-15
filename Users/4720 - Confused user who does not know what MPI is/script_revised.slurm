#!/bin/bash -l
#SBATCH --job-name=FEP-revised
#SBATCH --output=FEP-rebised.log
#SBATCH --error=FEP-revised.error
#SBATCH --partition=small-g
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=1
#SBATCH --gpus=2
#SBATCH --time=00:05:00

# Create the select_gpu script
cat << EOF > select_gpu_$SLURM_JOBID
#!/bin/bash

# Load the conda environment
#export PATH="$PATH:/scratch/project_465000973/Singularity_Envs/cheminf_opencl/bin"

# Distribute the GPU for the ranks equally
export ROCR_VISIBLE_DEVICES=\$((SLURM_LOCALID % SLURM_GPUS_PER_NODE))

echo "GPU: \$ROCR_VISIBLE_DEVICES -- RANK: \$SLURM_LOCALID -- EXE: \$*"

exec \$*
EOF

# Make the select_gpu script executable
chmod +x select_gpu_$SLURM_JOBID

# Make a dummy program to run
cat << EOF > dummy_job_$SLURM_JOBID
#!/bin/bash
module load LUMI/23.09 partition/G
module load lumi-CPEtools/1.1-cpeGNU-23.09

echo "Running at \$(date)."

gpu_check -l

sleep 30

echo "Finishing at \$(date)."
EOF

# Make this executable
chmod +x dummy_job_$SLURM_JOBID


module load LUMI/23.09 partition/G
module load lumi-CPEtools/1.1-cpeGNU-23.09


srun -n 1 -c 1 --gpus 1 --exact ./select_gpu_$SLURM_JOBID ./dummy_job_$SLURM_JOBID > output-rev1.txt &
sleep 5

srun -n 1 -c 1 --gpus 1 --exact ./select_gpu_$SLURM_JOBID ./dummy_job_$SLURM_JOBID > output-rev2.txt &
sleep 5

#srun -n 1 -c 1 --gpus 1 ./select_gpu_$SLURM_JOBID ./dummy_job_$SLURM_JOBID > output-rev3.txt
#sleep 5

#srun -n 1 -c 1 --gpus 1 ./select_gpu_$SLURM_JOBID ./dummy_job_$SLURM_JOBID > output-rev4.txt
#sleep 5

#wait

#rm -f select_gpu_$SLURM_JOBID dummy_job_$SLURM_JOBID
