#! /usr/bin/bash
#SBATCH --job-name=slurm-HWT-standard-multithread
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --hint=multithread
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt

module load LUMI/23.09 partition/C lumi-CPEtools/1.1-cpeGNU-23.09

#echo "Submitted from $SLURM_SUBMIT_HOST"
#echo "Running on $SLURM_JOB_NODELIST"
#echo
echo -e "Job script:\n$(cat $0)\n"
#echo "SLURM_* and SRUN_* environment variables:"
#env | egrep ^SLURM
#env | egrep ^SRUN

set -x
srun -n 1 -c 4 omp_check -r
set +x
sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
