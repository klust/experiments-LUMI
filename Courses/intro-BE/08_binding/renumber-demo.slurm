#!/bin/bash
#SBATCH --job-name=renumber-demo
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/24.03 partition/C lumi-CPEtools/1.2-cpeGNU-24.03

set -x
echo -e "\nSMP-style distribution on top of block."
export MPICH_RANK_REORDER_METHOD=1
srun -n 8 -c 32 -m block mpi_check -r
echo -e "\nSMP-style distribution on top of cyclic."
export MPICH_RANK_REORDER_METHOD=1
srun -n 8 -c 32 -m cyclic mpi_check -r
echo -e "\nRound-robin distribution on top of block."
export MPICH_RANK_REORDER_METHOD=0
srun -n 8 -c 32 -m block mpi_check -r
echo -e "\nFolded distribution on top of block."
export MPICH_RANK_REORDER_METHOD=2
srun -n 8 -c 32 -m block mpi_check -r
echo -e "\nCustom distribution on top of block."
export MPICH_RANK_REORDER_METHOD=3
cat >MPICH_RANK_ORDER <<EOF
0,1,4,5,2,3,6,7
EOF
cat MPICH_RANK_ORDER
srun -n 8 -c 32 -m block mpi_check -r
/bin/rm MPICH_RANK_ORDER
set +x
