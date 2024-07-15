#!/bin/bash
#SBATCH --job-name=distribution-demo
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module use /appl/lumi/modules/init-LUMI-SoftwareStack
module use /appl/lumi/modules/SoftwareStack
module load init-lumi
module load LUMI/22.12 partition/C lumi-CPEtools/1.1-cpeGNU-22.12

set -x
echo -e "\nDefault behaviour\n"
srun -n 6 -c 32 mpi_check -r
echo -e "\nFirst level: Block\n"
srun -n 6 -c 32 --distribution=block mpi_check -r
echo
srun -n 6 -c 32 --distribution=block,pack mpi_check -r
echo
srun -n 6 -c 32 --distribution=block,nopack mpi_check -r
echo -e "\nFirst level block, experimenting with second level:\n"
echo
srun -n 6 -c 32 --distribution="block:*" mpi_check -r
echo
srun -n 6 -c 32 --distribution="block:*,pack" mpi_check -r
echo
srun -n 6 -c 32 --distribution="block:*,nopack" mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:block mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:block,pack mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:block,nopack mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:cyclic mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:cyclic,pack mpi_check -r
echo
srun -n 6 -c 32 --distribution=block:cyclic,nopack mpi_check -r
set +x

