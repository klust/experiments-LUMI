module --force purge

unset LMOD_RC
export LMOD_PACKAGE_PATH=/users/kurtlust/experiments-LUMI/LMOD/TEST-SETUP/LMOD

# Clear the lmod cache as we may be switching between versions of Lmod.
[ -d $HOME/.lmod.d/.cache ] && /bin/rm -rf $HOME/.lmod.d/.cache  # System Lmod 8.3.1
[ -d $HOME/.cache/lmod ]    && /bin/rm -rf $HOME/.cache/lmod     # Own Lmod 8.7.x

#export MODULEPATH=/opt/cray/pe/lmod/modulefiles/core:/opt/cray/pe/lmod/modulefiles/craype-targets/default:/opt/cray/modulefiles:/opt/modulefiles
export MODULEPATH=/users/kurtlust/experiments-LUMI/LMOD/TEST-SETUP/modules

source $HOME/appl_lmod/share/lmod/lmod/init/bash

#module load craype-x86-rome craype-network-ofi perftools-base xpmem
#eval "module load craype-x86-rome craype-network-ofi craype-accel-host perftools-base xpmem"
#eval $(/usr/share/lmod/lmod/libexec/lmod load craype-x86-rome craype-network-ofi craype-accel-host perftools-base xpmem)

export LMOD_SHORT_TIME=0

module spider

module --version

ls -l ~/.lmod.d/.cache
