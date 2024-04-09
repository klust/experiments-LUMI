#! /usr/bin/bash
#SBATCH --job-name=slurm-perNode-jobstart-standard-demo1
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt

module load LUMI/23.09 partition/C lumi-CPEtools/1.1-cpeCray-23.09

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

set -x
# This works
srun --ntasks=32 --cpus-per-task=8 hybrid_check -r

# This does not work
srun --ntasks-per-node=16 --cpus-per-task=8 hybrid_check -r

# But this works again
unset SLURM_NTASKS
unset SLURM_NPROCS
srun --ntasks-per-node=16 --cpus-per-task=8 hybrid_check -r
set +x
sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
