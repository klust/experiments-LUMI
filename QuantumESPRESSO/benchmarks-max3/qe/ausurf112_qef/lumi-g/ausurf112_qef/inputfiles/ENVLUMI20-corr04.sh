# We have had a solution without PE_LD_LIBRARY_PATH=system that
# is supported by older versions of the Cray PE also:
module purge
module load LUMI/25.09 partition/G
# Load the Cray programming environment
module load cpeCray/25.09
# Now load other libraries/packages
module load cray-fftw
module load cray-python
# But now we have access to a newer ROCm module:
module load rocm/6.4.4
# Should you want gcc to be a more recent version, load gcc-native-mixed.
# There is something strange with these modules also. Version numbers used
# to be major.minor, but then they realised that the way the module works
# (basically making available symbolic links for the gcc-<major> etc commands
# installed by SUSE development packages) makes this unlogical. During the 
# January update (from SP5 to SP6), these commands got replaced from version 14.2 
# to 14.3 while obviously they could not change the 14.2 module name as that
# would break the 25.03 programming environment. So they introduced major-only
# version names in 25.09.
module load gcc-native-mixed/14
# Now correct LD_LIBRARY_PATH
module load lumi-CrayPath
# And all the other stuff for QE:
export PE_MPICH_GTL_DIR_amd_gfx90a=${PE_MPICH_GTL_DIR_amd_gfx90a}
export PE_MPICH_GTL_LIBS_amd_gfx90a=${PE_MPICH_GTL_LIBS_amd_gfx90a}
export gcc_already_loaded=1
export CRAY_PRGENVGNU=loaded
export MPICH_GPU_SUPPORT_ENABLED=1
export CRAY_CCE_OPT_ARGS="--passes=default<O1>"
# Some checks
# Wrappers are the Cray compilers:
cc --version
CC --version
ftn --version
# But we do get recent GNU compilers:
gcc --version
g++ --version
gfortran --version
# List the modules
module list
# Now the order of directories in LD_LIBRARY_PATH will be different
# from ENVLUMI20-corr03.sh, but as they all contain different libraries,
# this does not really matter. There is one difference though: It looks
# like perftools does not support PE_LD_LIBRARY_PATH=system. Here the
# perfools libraries will be in LD_LIBRARY_PATH, but they are not in
# ENVLUMI20-corr03.sh.
function echopath { echo "$1=" ; eval echo \$$1 | tr ":" "\n" | nl - ; }
echopath PATH
echopath LD_LIBRARY_PATH