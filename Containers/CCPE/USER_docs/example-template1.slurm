#!/bin/bash
#
# This test script should be submitted with sbatch from within a CPE 24.11 container.
# It shows very strange behaviour as the `module load` of some modules fails to show
# those in `module list` and also fails to change variables that should be changed.
#
#SBATCH -J example-jobscript
#SBATCH -p small
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -t 5:00
#SBATCH -o %x-%j.md
# And add line for account

#
# Ensure that we can find the container. This might not be the case if this job script
# is launched from outside the container with the ccpe module not loaded.
#
if [ -z "${SWITCHTCCPE}" ]
then
    module load CrayEnv ccpe/24.11-LUMI || exit
fi

eval $SWITCHTCCPE

#
# Here you have the container environment and can simply work as you would normally do:
# Build your environment and start commands. But you'll still have to be careful with
# srun as whatever you start with srun will not automatically run in the container.
#

module list
