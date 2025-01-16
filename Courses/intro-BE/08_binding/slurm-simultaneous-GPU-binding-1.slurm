#! /usr/bin/bash
#SBATCH --job-name=slurm-simultaneous-GPU-binding-1
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt
#SBATCH --gpus-per-node=8

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* environment variables:"
env | egrep ^SLURM

CPU_BIND=(0x00000000000000fe 0x000000000000fe00
          0x0000000000fe0000 0x00000000fe000000
          0x000000fe00000000 0x0000fe0000000000
          0x00fe000000000000 0xfe00000000000000)

GPU_BIND=(4 5 2 3 6 7 0 1)

for i in $(seq 0 7)
do 
    # Without --overlap the job steps will still run sequentially as Slurm doesn't
    # realise that only a few cores are used by each and not the same ones, so we
    # use --overlap.
    srun --ntasks=1 --cpu-bind=mask_cpu:${CPU_BIND[$i]} --overlap --output="slurm-simultaneous-GPU-binding-1-$SLURM_JOB_ID-$i.txt" \
        bash -c "export ROCR_VISIBLE_DEVICES=${GPU_BIND[$i]} && gpu_check -l && omp_check -w 30" &
        
    sleep 2
done

wait

sleep 2
echo -e "\nsacct for the job:\n$(sacct -j $SLURM_JOB_ID --format JobID%-13,Start,End,AllocCPUS,NCPUS,TotalCPU,MaxRSS --units=M )\n"
