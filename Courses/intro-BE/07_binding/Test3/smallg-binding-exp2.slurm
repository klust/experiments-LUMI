#! /bin/bash
#SBATCH --job-name=smallg-binding-exp2
#SBATCH --output %x-%j.txt
#SBATCH --partition=small-g
#SBATCH --ntasks=6
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=2
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module use /appl/lumi/modules/init-LUMI-SoftwareStack
module use /appl/lumi/modules/SoftwareStack
module load init-lumi
module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

cat << EOF > select_1gpu_$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$((SLURM_LOCALID*2)),\$((SLURM_LOCALID*2+1))
exec \$*
EOF
chmod +x ./select_1gpu_$SLURM_JOB_ID

cat << EOF > task_lstopo_$SLURM_JOB_ID
#!/bin/bash
sleep \$((SLURM_LOCALID * 3))
echo "Task \$SLURM_PROCID"                                                                              > output-\$SLURM_JOB_ID-\$SLURM_PROCID
echo "  GPUs with PCI bus ID via lstopo:"                                                              >> output-\$SLURM_JOB_ID-\$SLURM_PROCID
lstopo -p | awk 'BEGIN { FS=" "}; /PCI.*Display/ {PCI=\$2}; /GPU.RSMI/ {print "    GPU " PCI " " \$2}' >> output-\$SLURM_JOB_ID-\$SLURM_PROCID
echo "  GPUs with PCI bus ID via rocm-smi:"                                                            >> output-\$SLURM_JOB_ID-\$SLURM_PROCID
rocm-smi --showbus | awk '/PCI Bus:/ {print "    " \$0}'                                               >> output-\$SLURM_JOB_ID-\$SLURM_PROCID
echo "  ROCR_VISIBLE_DEVICES: \$ROCR_VISIBLE_DEVICES"                                                  >> output-\$SLURM_JOB_ID-\$SLURM_PROCID
EOF
chmod +x ./task_lstopo_$SLURM_JOB_ID

echo -e "##\n## Run 1: Just srun without arguments:\n##\n\n"

srun ./task_lstopo_$SLURM_JOB_ID

for num in $(seq 0 $((SLURM_NTASKS-1)))
do 
    cat output-$SLURM_JOB_ID-$num
done

srun gpu_check -l

echo -e "##\n## Run 2: srun --gpu-bind=none:\n##\n\n"

srun --gpu-bind=none ./task_lstopo_$SLURM_JOB_ID

for num in $(seq 0 $((SLURM_NTASKS-1)))
do 
    cat output-$SLURM_JOB_ID-$num
done

srun --gpu-bind=none gpu_check -l

echo -e "##\n## Run 3: srun --gpu-bind=none ./slect_1gpu:\n##\n\n"

srun --gpu-bind=none ./select_1gpu_$SLURM_JOB_ID ./task_lstopo_$SLURM_JOB_ID

for num in $(seq 0 $((SLURM_NTASKS-1)))
do 
    cat output-$SLURM_JOB_ID-$num
done

srun --gpu-bind=none ./select_1gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_1gpu_$SLURM_JOB_ID task_lstopo_$SLURM_JOB_ID output-$SLURM_JOB_ID-*
