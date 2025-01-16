#! /usr/bin/bash
#SBATCH --job-name=slurm-perNode-minimal-small
#SBATCH --partition=small
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --mem=224G
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
omp_check

set +x
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
