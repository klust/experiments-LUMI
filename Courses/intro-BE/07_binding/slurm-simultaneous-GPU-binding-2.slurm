#! /usr/bin/bash
#SBATCH --job-name=slurm-simultaneous-GPU-binding-2
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt
#SBATCH --gpus-per-node=8

#
# Example that does not work!
#

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

GPU_BIND=(4 5 2 3 6 7 0 1)

for i in $(seq 0 7)
do 
    # With --overlap, all tjob steps end up on the same CCD
    # Without --overlap, job steps are executed sequentially
    # Combining with --exact is certainly no solution.
    srun --ntasks=1 --cpus-per-task=7 --gpu-bind=map_gpu:${GPU_BIND[$i]} --overlap --output="slurm-simultaneous-GPU-binding-2-$SLURM_JOB_ID-$i.txt" \
        bash -c "gpu_check -l && omp_check -w 30" &
        
    sleep 2
done

wait

sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID --format JobID%-13,Start,End,AllocCPUS,NCPUS,TotalCPU,MaxRSS --units=M )\n"
