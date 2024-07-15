#!/bin/bash -l
#SBATCH --job-name=hybrid-ntsrun-cptsrun
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
#SBATCH --partition=standard-g 
#SBATCH --exclusive
#SBATCH --nodes=1  
#SBATCH --gpus-per-node=8
#SBATCH --time=2:00 
#SBATCH --reservation=lust

module use /appl/lumi/modules/init-LUMI-SoftwareStack
module use /appl/lumi/modules/SoftwareStack
module load init-lumi
module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash

export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod +x ./select_gpu_$SLURM_JOB_ID

export OMP_NUM_THREADS=2

srun --ntasks=8 --cpus-per-task=2 ./select_gpu_$SLURM_JOB_ID gpu_check -l
rm -rf ./select_gpu_$SLURM_JOB_ID
