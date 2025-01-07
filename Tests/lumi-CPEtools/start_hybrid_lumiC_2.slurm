#!/bin/bash
#SBATCH --job-name=hybrid-test
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=8
#SBATCH --mem=224G
#SBATCH --hint=multithread
#SBATCH --time=30:00
#SBATCH --output=bip_%j.out
#SBATCH --error=bip_%j.err
#SBATCH --mail-user=kurt.lust@uantwerpen.be
#SBATCH --mail-type=ALL


#init-lumi-h
ml LUMI/24.03 partition/C
ml lumi-CPEtools/1.2-cpeGNU-24.03

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

export OMP_NUM_THREADS=8
export OMP_PLACES=cores
export OMP_PROC_BIND=true

env | egrep ^OMP_

srun  hybrid_check -r
for i in {1..10};
do 
    srun --unbuffered hybrid_check -r -w 240
    sleep 30
done
