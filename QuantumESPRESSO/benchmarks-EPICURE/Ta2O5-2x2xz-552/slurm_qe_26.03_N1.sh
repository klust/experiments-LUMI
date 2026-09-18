#! /usr/bin/bash
#SBATCH --job-name=QE-26.03-N1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=7
#SBATCH --time=01:00:00
#SBATCH --output=%x-%j.out.txt
#SBATCH --error=%x-%j.err.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --mem-per-gpu=60G

################################################################################
#
# Always start with this block.
# Its function is to restart the execution of the job script in the container
# so that you can write a regular job script as if you are working in the
# version of the Cray PE in the container.
#

#
# Ensure that the environment variable SWITCHTOCCPE exists 
#
if [ -z "${SWITCHTOCCPE}" ]
then
    init-lumi-h
    module load CrayEnv ccpe/26.03-noRocm-SP7-LUMI || exit
fi

#
# Now switch to the container and clean up environments when needed and possible.
#
eval $SWITCHTOCCPE

################################################################################
#
# Here you have the container environment and can simply work as you would 
# normally do:  Build your environment and start commands. But you'll still 
# have to be careful with srun as whatever you start with srun will not 
# automatically run in the container.
#

# Always reconstruct the environment and don't rely on something inherited from
# the calling shell as this will be wrong if the job script is not launched from
# within the container.

init-lumi-h
module purge
module load LUMI/26.03 partition/G
module load QuantumESPRESSO/7.5-cpeCray-26.03-rocm
module load lumi-CrayPath

LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
echo "LD_LIBRARY_PATH is $LD_LIBRARY_PATH."
ldd $(which pw.x)

export FI_CXI_RX_MATCH_MODE=software
export MPICH_GPU_SUPPORT_ENABLED=1
export OMP_NUM_THREADS=7

echo -e "\n\nNow via ccpe-srun:\n"
ccpe-srun -n1 singularity exec $SIFCCPE bash -c 'ldd $(which pw.x)'

ccpe-srun \
    --cpu-bind=verbose,mask_cpu:fe000000000000,fe00000000000000,fe0000,fe000000,fe,fe00,fe00000000,fe0000000000 \
    --gpu-bind=map_gpu:0,1,2,3,4,5,6,7 --gres-flags=allow-task-sharing \
    singularity exec $SIFCCPE \
    pw.x -nk 1 -input Ta2O5-2x2xz-552-N1.in
