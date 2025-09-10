#!/usr/bin/env bash

# Configuration of Chapel for AMD (multi-)GPU-accelerated experiments on the
# LUMI pre-exascale supercomputer (https://docs.lumi-supercomputer.eu/).

# Load modules
module purge
module load LUMI/24.03
module load partition/G
module load rocm/6.0.3
module load buildtools/24.03 # contains CMake
module load syslibs/24.03    # Static ncurses
module load cpeAMD/24.03

export HERE=$(pwd)

#export CHPL_VERSION=$(cat CHPL_VERSION)
export CHPL_VERSION=2.5.0
#export CHPL_HOME=~/chapel-${CHPL_VERSION}_MCG_amd
export CHPL_HOME=$HERE/chapel-${CHPL_VERSION}_MCG_amd

# Download Chapel if not found
if [ ! -d "$CHPL_HOME" ]; then
  cd $HERE
  [ -f chapel-${CHPL_VERSION}.tar.gz ] || wget https://github.com/chapel-lang/chapel/releases/download/${CHPL_VERSION}/chapel-${CHPL_VERSION}.tar.gz
  #wget -c https://github.com/chapel-lang/chapel/releases/download/${CHPL_VERSION}/chapel-${CHPL_VERSION}.tar.gz -O - | tar xz
  tar -xf chapel-${CHPL_VERSION}.tar.gz
  mv chapel-$CHPL_VERSION $CHPL_HOME
  # Patch hwloc Makefile
  sed -e 's|(RUNTIME_LFLAGS)|(RUNTIME_LFLAGS) -L$(EBROOTSYSLIBS) -lncursesw|' -i $CHPL_HOME/third-party/hwloc/Makefile
fi

CHPL_BIN_SUBDIR=$("$CHPL_HOME"/util/chplenv/chpl_bin_subdir.py)
export PATH="$PATH":"$CHPL_HOME/bin/$CHPL_BIN_SUBDIR:$CHPL_HOME/util"

export CHPL_HOST_PLATFORM=$("$CHPL_HOME"/util/chplenv/chpl_platform.py)
export CHPL_TARGET_COMPILER="llvm"
# LLVM backend to the Chapel compiler (recommended to use)
export CHPL_LLVM="bundled" # required for ROCm 6
#export CHPL_LLVM_CONFIG=$CRAY_CCE_CLANGSHARE/../bin/llvm-config
export CHPL_LLVM_CONFIG="$ROCM_PATH/llvm/bin/llvm-config"
# Only single-locale executaion required
export CHPL_COMM="none"
export CHPL_LAUNCHER="none"
#export CHPL_HWLOC=none
export CHPL_HWLOC=bundled

export CHPL_LOCALE_MODEL="gpu"
export CHPL_GPU="amd"
export CHPL_GPU_ARCH="gfx90a"
export CHPL_GPU_MEM_STRATEGY="array_on_device" # default
export CHPL_ROCM_PATH=$EBROOTROCM
export CHPL_RT_NUM_THREADS_PER_LOCALE=4
export CHPL_RT_NUM_GPUS_PER_LOCALE=4     # Why not 8?

export GASNET_PHYSMEM_MAX='64 GB'

cd $CHPL_HOME
#patch -N -p1 < $HERE/perf_patch.patch # see Chapel PR #24970 on Github (remove it when Chapel 2.1 is released)

# The next line is a very dangerous way of determining the value for -j for the make command!
# MAXPARALLEL=$(cat /proc/cpuinfo | grep processor | wc -l)
# Maybe safer if not all cores are available:
# MAXPARALLEL=$(lstopo | grep '+ Core' | wc -l)
MAXPARALLEL=16
#make -j $MAXPARALLEL
make -j $MAXPARALLEL V=1 VERBOSE=1
cd $HERE
