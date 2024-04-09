#! /usr/bin/bash
#SBATCH --job-name=slurm-HWT-standard-full
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

set -x
omp_check -r

srun -n 1 -c 128 --hint=nomultithread omp_check -r

srun -n 1 -c 128 --hint=multithread omp_check -r

srun -n 1 -c 256 --hint=multithread omp_check -r

srun -n 1 -c 128 omp_check -r
set +x
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
