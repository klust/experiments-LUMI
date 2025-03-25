#!/bin/bash
#
# This test script should be submitted with sbatch from within a CPE 24.11 container.
# It shows very strange behaviour as the `module load` of some modules fails to show
# those in `module list` and also fails to change variables that should be changed.
#
#SBATCH -J example1
#SBATCH -p small
#SBATCH -n 1
#SBATCH -c 1
#SBATCH -t 5:00
#SBATCH -o %x-%j.md
# And add line for account

echo -e "The script inherits the environment from the container, but uses the module tool from the system.\n"
echo -e "Detected version of the module tool: \n\`\`\`\n$(module --version 2>&1)\n\`\`\`\n\n"
echo -e "List of modules currently loaded:\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n\n"
echo -e "Environment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\` (should be 18.0.1, the version from the container)\n"
echo -e "Now executing a 'module purge':\n\n\`\`\`\n"
module purge 2>&1
echo -e "\n\`\`\`\n\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`. Not unset as 'module purge' has no access to the module file.\n"
echo -e "Now executing 'module load cce':\n\`\`\`\n"
module load cce 2>&1
echo -e "\n\`\`\`\n"
echo -e "And listing the modules with 'module list':\n\`\`\`\n$(module list 2>&1)\n\`\`\`\n"
echo -e "**Note a major issue: We see the modules from the container even though the output of \`module load\` suggests differently.**\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
echo -e "Now executing a 'module purge' again:\n\n\`\`\`\n"
module purge 2>&1
echo -e "\n\`\`\`\n"
echo -e "\n\nEnvironment variable CRAY_CC_VERSION: \`${CRAY_CC_VERSION}\`\n"
echo -e "Can we even unset of \`CRAY_CC_VERSION\`? Let's try:\n\n\`\`\`"
unset CRAY_CC_VERSION
echo -e "\`\`\`\nEnvironment variable CRAY_CC_VERSION: ${CRAY_CC_VERSION}\n"
echo -e "**So it looks like 'unset CRAY_CC_VERSION' did the job, so the variables are not read-only, but it appears that Lmod is completely broken and not re-initialised.**\n" 
echo -e "But check if we still now the path to the container via the SIFCCPE environment variable:\n\`${SIFCCPE}\`"
