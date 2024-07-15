#! /usr/bin/bash
#SBATCH --job-name=slurm-perNode-jobstart-small-demo2
#SBATCH --partition=small
#SBATCH --exclusive
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=8
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

set -x
srun hybrid_check -r
set +x
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
