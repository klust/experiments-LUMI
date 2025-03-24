#!/bin/bash
#
# This test script should be submitted with sbatch from within a CPE 24.11 container.
# It shows very strange behaviour as the `module load` of some modules fails to show
# those in `moudlule list` and also fails to change variables that should be changed.
#
#SBATCH -J example5
#SBATCH -p small
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -t 5:00
#SBATCH -o %x-%j.md
#SBATCH --export=SINGULARITY_BIND,SIF,SIFCCPE
# And add line for account


echo -e "\n\n# Body of the job script\n"

echo -e "Detected version of the module tool (should be the container one): \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n"
echo -e "List of modules currently loaded (should be the system ones):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now doing a \`module unload cce\`:\n\n\`\`\`\n$(module unload cce 2>&1)\n\`\`\`\n"
echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`. Is it empty now?\n"
echo -e "Now executing a 'module purge':\n\n\`\`\`\n$(module purge 2>&1)\n\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now executing \`module load cce\`':\n\n\`\`\`\n$(module load cce 2>&1)\n\`\`\`\n"
echo -e "And listing the modules with 'module list':\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "Now executing a 'module purge' again:\n\n\`\`\`\n $(module purge 2>&1)\n\`\`\`\n"
echo -e "List of modules currently loaded (should be almost empty):\n\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`.\n"
echo -e "But check if we still now the path to the container via the SIFCCPE environment variable:\n\`${SIFCCPE}\`"
