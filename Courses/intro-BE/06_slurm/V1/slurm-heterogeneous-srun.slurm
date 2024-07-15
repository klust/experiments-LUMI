#! /usr/bin/bash
#SBATCH --job-name=slurm-herterogeneous-srun
#SBATCH --time=5:00
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard
#SBATCH --nodes=3

module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeCray-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

srun --ntasks=32 --cpus-per-task=4  --export=ALL,OMP_NUM_THREADS=4  hybrid_check -l app_A : \
     --ntasks=8  --cpus-per-task=32 --export=ALL,OMP_NUM_THREADS=32 hybrid_check -l app_B
     
srun --ntasks=32 --cpus-per-task=4  hybrid_check -l app_A : \
     --ntasks=8  --cpus-per-task=32 hybrid_check -l app_B
     
srun --nodes=1 --ntasks-per-node=32 --cpus-per-task=4  hybrid_check -l hybrid_check -l app_A : \
     --nodes=2 --ntasks-per-node=4  --cpus-per-task=32 hybrid_check -l hybrid_check -l app_B

echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID)\n"
