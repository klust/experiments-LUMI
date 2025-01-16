#! /usr/bin/bash
#SBATCH --job-name=slurm-perNode-2nodes-gres
#SBATCH --partition=standard-g
#SBATCH --nodes=2
#SBATCH --gres=gpu:mi250:8
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

echo -e "\nGPU allocation on the first node:\n"
set -x
OMP_NUM_THREADS=1 gpu_check
set +x

echo -e "\nGPU allocation on both nodes:\n"
set -x
OMP_NUM_THREADS=1 srun --ntasks-per-node=1 gpu_check
set +x

echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
