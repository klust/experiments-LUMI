#!/bin/bash
#
# This test script should be submitted with sbatch from within a CPE 24.11 container.
# It shows very strange behaviour as the `module load` of some modules fails to show
# those in `module list` and also fails to change variables that should be changed.
#
# Suggestion for running:
# sbatch example8.slurm ; sbatch --export=$EXPORTCCPE example8.slurm ; sbatch --export=NONE example8.slurm
# both inside and outside the container, and load PrgEnv-gnu inside the container first
# to see if the environment is preserved when using `sbatch example8.slurm`.
#
#SBATCH -J example8
#SBATCH -p small
#SBATCH -n 2
#SBATCH -c 1
#SBATCH -t 5:00
#SBATCH -o %x-%j.md
## The next line does not work unfortunately. We have to give the argument on the command line
## or via an environment variable.
##SBATCH --export=$EXPORTCCPE
##SBATCH --export=SINGULARITY_BIND,SWITHCTOCLEANCCPE,SIF,SIFCCPE
# And add line for account

if [ ! -d "/.singularity.d" ]
then 
    echo -e "# Entering the script to enter the container from the system\n" 
    echo -e "Environment when entering (if module works):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
else 
    echo -e "\n# Entering the script to enter the container from the container\n" 
fi

#
# Ensure that we can find the container. This might not be the case if this job script
# is launched from outside the container with the ccpe module not loaded.
#
if [ -z "${SWITCHTOCCPE}" ]
then
    echo -e '\n```'
    init-lumi-h
    module load CrayEnv ccpe/24.11-LUMI || exit
    echo -e '\n```\n'
fi

# Make sure we execute the remainder of this job script in the container.
eval $SWITCHTOCCPE


echo -e "\nAfter cleanup:\n  - SIF: $SIF\n  - SIFCCPE: $SIFCCPE\n  - SINGULARITY_BIND: $SINGULARITY_BIND\n  - EXPORTCCPE: $EXPORTCCPE\n"
echo -e "Checking if INITCCPE did its job:\n  - BASH_ENV: $BASH_ENV\n  - MODULEPATH: $MODULEPATH\n  - LMOD_SYSTEM_DEFAULT_MODULES: $LMOD_SYSTEM_DEFAULT_MODULES\n  - mod_paths: $mod_paths\n"

echo -e "\n\n# Body of the job script - Building and investigating the environment in the container\n"

echo -e "Detected version of the module tool (should be the container one, 8.3.37 for 24.11): \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n"
echo -e "List of modules currently loaded (should be the default container ones):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"

echo -e 'Now loading PrgEnv-gnu to see if it is preserved when calling `srun`:\n```\n'
module load PrgEnv-gnu
echo -e '\n```'
echo -e "List of modules currently loaded (should be with PrgEnv-gnu):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"



echo -e "\n\n# Trying an srun...\n\n"


echo -e "Now calling srun, excuting a \`module list\`, then print the value of \`CRAY_CC_VERSION\`, then \`module load cce\` and finally print the value of \`CRAY_CC_VERSION\` again."
echo -e "We would like to to see the list of modules from above again, then an empty variable and then the CCE version from the container.\n"

# Note that we want srun to take over the environment we just built.
echo -e "\n\`\`\`"
srun -n2 -c1 -t1:00 --label singularity exec $SIFCCPE bash -c \
   'module list 2>&1 ; 
   echo "Before loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION" ; 
   module load cce 2>&1 ; 
   echo "After loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION, should be the container version."' \
   | sort -t : -k 1,1n -s --buffer-size=1M
echo -e "\n\`\`\`\n"
