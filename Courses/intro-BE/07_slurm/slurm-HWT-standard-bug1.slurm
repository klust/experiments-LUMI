#! /usr/bin/bash
#SBATCH --job-name=slurm-HWT-standard-bug1
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt
#SBATCH --hint=nomultithread

module load LUMI/24.03 partition/C lumi-CPEtools/1.2-cpeGNU-24.03

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

set -x
omp_check -r

srun -n 1 -c 4 --hint=nomultithread omp_check -r

srun -n 1 -c 4 --hint=multithread omp_check -r

OMP_NUM_THREADS=8 srun -n 1 -c 4 --hint=multithread omp_check -r

srun -n 1 -c 4 omp_check -r
set +x
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"

set -x
srun -n 1 -c 256 --hint=multithread omp_check -r
