#! /usr/bin/bash
#SBATCH --job-name=slurm-simultaneous-CPU-1
#SBATCH --partition=standard
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

#
# WERKT NOG NIET! De jobsteps overlappen niet zoals het hoort, noch met noch zonder --overlap.
#

module load LUMI/23.09 partition/C lumi-CPEtools/1.1-cpeCray-23.09

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

for i in $(seq 0 7)
do 
    srun --ntasks=1 --cpus-per-task=16 --output="slurm-simultaneous-CPU-1-$SLURM_JOB_ID-$i.txt" \
        bash -c "export ROCR_VISIBLE_DEVICES=${GPU_BIND[$i]} && omp_check -w 30" &
        
    sleep 2
done

wait

sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID --format JobID%-13,Start,End,AllocCPUS,NCPUS,TotalCPU,MaxRSS --units=M )\n"
