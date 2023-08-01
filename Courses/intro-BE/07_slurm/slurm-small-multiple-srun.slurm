#! /usr/bin/bash
#SBATCH --job-name=slurm-small-multiple-srun
#SBATCH --partition=small
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=4
#SBATCH --nodes=2-4
#SBATCH --hint=nomultithread
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

set -x
serial_check

omp_check

srun --ntasks=1 --cpus-per-task=3 omp_check

srun --ntasks=2 --cpus-per-task=4 hybrid_check

srun --ntasks=4 --cpus-per-task=1 mpi_check

srun --ntasks=16 --cpus-per-task=1 mpi_check

srun --ntasks=1 --cpus-per-task=16 omp_check

set +x
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
