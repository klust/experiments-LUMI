#!/bin/bash
#
# This test script should be submitted with sbatch from within a CPE 24.11 container.
# It shows very strange behaviour as the `module load` of some modules fails to show
# those in `module list` and also fails to change variables that should be changed.
#
#SBATCH -J example4
#SBATCH -p small
#SBATCH -n 2
#SBATCH -c 1
#SBATCH -t 5:00
#SBATCH -o %x-%j.md
#SBATCH --export=SINGULARITY_BIND,SIF,SIFCCPE
# And add line for account

#
# Ensure that we can find the container. This might not be the case if this job script
# is launched from outside the container with the ccpe module not loaded.
#
if [ -z "${SIFCCPE}" ]
then
    module load CrayEnv ccpe/24.11-LUMI
fi

#
# Block that can simply be copied, but note that the --export above is
# important to have a clean shell on the system side.
#
if [ ! -d "/.singularity.d" ]
then

    echo -e "# Prequel - In batch script but not in the container\n"

    echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
    echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
    echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
    echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for \`17.0.1\`, the value in the system environment.\n"
    
    echo -e "Do we have any modules loaded? Let's check with \`module list\`:\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
    
    echo -e "Let's try a full clean-up saving \`SINGULARIT_BIND\`, \`SIF\`and \`SIFCCPE\`:\n\n\`\`\`\n"
    
    save_SIF="$SIF"
    save_SIFCCPE="$SIFCCPE"
    save_BIND="$SINGULARITY_BIND"
    
    module --force purge
    eval $($LMOD_DIR/clearLMOD_cmd --shell bash --full --quiet)
    unset LUMI_INIT_FIRST_LOAD
    ## Make sure that /etc/profile does not quit immediately when called.
    unset PROFILEREAD
    
    export SIF="$save_SIF"
    export SIFCCPE="$save_SIFCCPE"
    export SINGULARITY_BIND="$save_BIND"
    
    echo -e "\n\`\`\`\n" 

    echo -e "Check the variables again:\n"    
    echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
    echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
    echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
    echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. If empty then cleaning up worked.\n"
    
    echo -e "Now restarting the script in the container..."
    exec singularity exec "$SIFCCPE" "$0" "$@"
    
else

    echo -e "\n\n# Intermediate: Set up the container environment"
   
    echo -e "Check the value of \`INITCCPE\`:\n\`\`\`\n$INITCCPE\n\`\`\`\n"
   
    echo -e "Calling \`eval \$INITCCPE\`:\n\n\`\`\`\n"
    eval $INITCCPE
    echo -e "\n\`\`\`\n "
   
    echo -e "Check the variables again:\n"    
    echo -e "-   Environment variable \`SINGULARITY_BIND\`: \`${SINGULARITY_BIND}\`.\n"
    echo -e "-   Environment variable \`SIF\`: \`${SIF}\`.\n"
    echo -e "-   Environment variable \`SIFCCPE\`: \`${SIFCCPE}\`.\n"
    echo -e "-   Environment variable \`CRAY_CC_VERSION\`: \`${CRAY_CC_VERSION}\`. Hope for\`18.0.1\`, the value for 24.11 in the container.\n"

fi

echo -e "\n\n# Body of the job script - Building and investigating the environment\n"

echo -e "Detected version of the module tool (should be the container one, 8.3.37 for 24.11): \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n"
echo -e "List of modules currently loaded (should be the container ones):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now doing a \`module unload cce\`:\n\n\`\`\`\n"
module unload cce 2>&1
echo -e "\n\`\`\`\n"
echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`. This should be empty\n"
echo -e "Now executing a 'module purge':\n\n\`\`\`\n"
module purge 2>&1
echo -e "\n\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now executing \`module load cce\`':\n\n\`\`\`\n"
module load cce 2>&1
echo -e "\n\`\`\`\n"
echo -e "And listing the modules with 'module list':\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now executing a 'module purge' again:\n\n\`\`\`\n "
module purge 2>&1
echo -e "\n\`\`\`\n"
echo -e "List of modules currently loaded (should be almost empty):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"

echo -e "\n\n# Trying an srun...\n\n"
echo -e "Check if we still now the path to the container via the SIFCCPE environment variable:\n\`${SIFCCPE}\`\n"

# Note the unexpected name of the next environment variable!
# We want to export the whole environment that we just built via srun
echo -e "Before calling \`srun\`, we need to unset \`SLURM_EXPORT_ENV\` to avoid propagation of the \`--export\` option that we used for the batch script.\n"

unset SLURM_EXPORT_ENV

echo -e "Now calling srun, excuting a \`module list\`, then print the value of \`CRAY_CC_VERSION\`, then \`module load cce\` and finally print the value of \`CRAY_CC_VERSION\` again."
echo -e "We would like to to see the small list of modules from above again, then an empty variable and then the CCE version from the container.\n"

# Note that we want srun to take over the environment we just built.
echo -e "\n\`\`\`"
srun -n2 -c1 -t1:00 --label singularity exec $SIFCCPE bash -c \
   'module list 2>&1 ; 
   echo "Before loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION" ; 
   module load cce ; 
   echo "After loading cce: CRAY_CC_VERSION=$CRAY_CC_VERSION, should be the container version."' \
   | sort -t : -k 1,1n -s
echo -e "\n\`\`\`\n"
