# Force remove all modules which means that essential LUMI tools will also be lost (init-lumi)
module --force purge
# Want classical behaviour from the PE: Add to LD_LIBRARY_PATH instead of CRAY_LD_LIBRARY_PATH
export PE_LD_LIBRARY_PATH=system
# Load the cray-python module for the current default version of the PE.
# This may not be the newest one (but is at the moment of writing as 25.03 and
# 25.09 use the same version). In 09/26, this is cray-python 3.11.7 with cpe/25.03 
# the default CPE version.
module load cray-python
# We want to use the Cray compilers, so we load PrgEnv-cray
# This will load the Cray Programming Environment with Cray compilers.
# In 09/26, this gives:
# - PrgEnv-cray/8.67.0, the module that we actually loaded
# - libfabric/1.22.0 (and without loading this cray-mpich would actually not load)
# - craype-network-ofi (also needed to be able to load cray-mpich)
# - craype/2.7.34 (the compiler wrappers)
# - cray-dsmml/0.3.1
# - cce/19.0.0
# - cray-mpich/8.1.32
# - cray-libsci/25.03.0
# Notably missing at this point is a CPU target module though.
module load PrgEnv-cray
# The next 2 loads make no sense as they were loaded by PrgEnv-cray as
# Otherwise PrgEnv-cray would not even be able to load cray-mpich.
module load libfabric
module load craype-network-ofi
# Load the base module for perftools to enable performance profiling.
module load perftools-base
# Now do something stupid: By loading gcc, we unload several of the previously
# loaded modules. Moreover, the gcc module is one from an older release of the 
# Cray Programming Environment and should not be used with either 25.03 or 25.09,
# where gcc-native is the correct module.
# Result is even an inconsistent environment.
# - Loading the gcc module (which will be gcc/12/2/0) with load the PrgEnv-gnu module. 
#   However, as the correct cpe module is not loaded first, it takes the PrgEnv-gnu 
#   module from 25.03 which #   itself will also load the gcc-native module that should 
#   be used with 25.03.
# - PrgEnv-cray gets replaced by PrgEnv-gnu
# - cce/19.0.0 gets replaced by gcc-native/14.2, but this will have no effect as gcc 12.2.0
#   will be first in the PATH.
# - cray-libsci/25.03.0 will swap from the module for the CCE compiler to the version for the
#   GNU compilers.
# - cray-mpich for CCE will be replaced by cray-mpich for the GNU compilers. The order in which
#   Lmod does everything is such that actually an older version gets loaded that is compatible
#   with gcc/12.2.0 but not with gcc-native/14.2.
# Note also that the gcc module and older versions of other modules that it may trigger, do 
# not yet support PE_LD_LIBRARY_PATH=system which may lead to further issues with 
# environment variables set by various modules.
module load gcc
# At this point Lmod is in an inconsistent state as some strange behaviour in the previous 
# step bypassed the Lmod family mechanism that would ensure that no two regular compiler modules
# would be loaded.
# Now loading cce/20.0.0 will automatically trigger loading PrgEnv-cray again:
# - Loading cce/20.0.0 should remove the currently loaded compiler module. Due to the inconsistent
#   state that Lmod is in, the gcc/12.2.0 module will be removed but the gcc-native/14.2 module
#   remains loaded.
# - PrgEnv-cray is loaded.
# - With it, cray-libsci is replaced with the CCE version, but somehow with the correct one for 25.09.
# - With it, cray-mpich is also replaced with the correct default one for 25.09, cray-mpich/9.0.1.
module load cce/20.0.0
# The following 2 loads do nothing except for changing the order of the modules and hence can make
# changes to the order in PATH, LD_LIBRARY_PATH, etc. 
module load craype
module load cray-dsmml
# I was a bit concerned that this would load the default version but fortunately it doesn;t and
# keeps cray-libsci/25.09.0. Again just a change in the order of the modules.
module load cray-libsci
# This again does nothing except for changing the order of the modules
module load cray-mpich/9.0.1
# Load the CPU target. As there are no modules loaded yet that depend on that target, no other
# module changes occur.
module load craype-x86-trento
# Load the GPU target. This has no consequences on other modules.
module load craype-accel-amd-gfx90a
# Load cray-fftw. This requires the CPU target to be loaded.
# Note that this is the version of cray-fftw for 25.03 and not the one for 25.09!
module load cray-fftw/3.3.10.10
# Load the system ROCm module.
# Note though that CCE 20 is really made for ROCm 6.4. The management environment used on LUMI
# does not support installing multiple ROCm modules at the system level. Though there is a solution
# for that on LUMI and there is a ROCm 6.4.4 module, we chose not to use that one?
module load rocm/6.3.4
# Not clear why the next two lines are needed as they just re-assign the value of the
# environment variable.
export PE_MPICH_GTL_DIR_amd_gfx90a=${PE_MPICH_GTL_DIR_amd_gfx90a}
export PE_MPICH_GTL_LIBS_amd_gfx90a=${PE_MPICH_GTL_LIBS_amd_gfx90a}
# Looks like some variables used by the QE installation?
export gcc_already_loaded=1
export CRAY_PRGENVGNU=loaded
# Enable GPU-aware MPI
export MPICH_GPU_SUPPORT_ENABLED=1
# Not sure what this does, undocumented trick to inject extra options in the wrappers
# or is this something in the QE makefiles to add extra flags?
# Not sure what that option would do either, though Gemini gives an answer that sounds
# reasonable: LLVM pass manager option to force its backend LLVM optimizer to run only 
# the standard -O1 optimization pipeline. The frontend can still use the behaviour of
# any optimisation flag specified on the command line.
export CRAY_CCE_OPT_ARGS="--passes=default<O1>"
# Checking the environment shows another seriously inconsistency:
# gcc --version now reports the gcc from the gcc/12.2.0 module while the gcc-native/14.2
# module is loaded...
gcc --version
# Check PATH and LD_LIBRARY_PATH
function echopath { echo "$1=" ; eval echo \$$1 | tr ":" "\n" | nl - ; }
echopath PATH
echopath LD_LIBRARY_PATH
# Now this cannot be properly cleared anymore:
module --force purge
echopath PATH
echopath LD_LIBRARY_PATH