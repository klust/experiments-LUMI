#! /usr/bin/bash
#SBATCH --job-name=ccpe-hybrid_check
#SBATCH --partition=standard
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=8
#SBATCH --time=2:00
#SBATCH --output=%x-%j.txt

#
# Launch either from outside the container or from within the right container.
#

#
# Ensure that the environment variable SWITCHTOCCPE and with it 
#
if [ -z "${SWITCHTOCCPE}" ]
then
    init-lumi-h
    module load CrayEnv ccpe/25.03-B-rocm-6.3-SP5-LUMI || exit
fi

#
# Now switch to the container and clean up environments when needed and possible.
#
type ccpe-srun
eval $SWITCHTOCCPE
type ccpe-srun

#
# And this is what we really want to do...
#

module load LUMI/25.03 partition/C lumi-CPEtools/1.2-cpeCray-25.03-hpcat-0.9

echo -e "\n\nRunning with ccpe-srun\n"
ccpe-srun singularity exec $SIFCCPE hybrid_check

echo -e "\n\nRunning with regular srun method 1\n"

SINGULARITYENV_PATH=$PATH SINGULARITYENV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH srun \
  singularity exec $SIFCCPE hybrid_check
  
echo -e "\n\nRunning with regular srun method 2\n"

export SINGULARITYENV_PATH=$PATH 
export SINGULARITYENV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH 
srun singularity exec $SIFCCPE hybrid_check

echo "\n\nAnd now trying hpcat...\n"
ccpe-srun singularity exec $SIFCCPE hpcat
