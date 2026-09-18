# We don't want a --force purge as we don't want to break the
# LUMI environment
# (Well, if you really want 'module --force purge' then at least
# follow it by a 'module load init-lumi'.)
module purge
# Want classical behaviour instead of Cray behaviour from the PE: 
# Add to LD_LIBRARY_PATH instead of CRAY_LD_LIBRARY_PATH
export PE_LD_LIBRARY_PATH=system
# Use the LUMI stacks: 25.09 for the GPUs
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
# Check PATH and LD_LIBRARY_PATH
function echopath { echo "$1=" ; eval echo \$$1 | tr ":" "\n" | nl - ; }
echopath PATH
echopath LD_LIBRARY_PATH