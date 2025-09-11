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
#export SOURCE_DIR=~/chapel-${CHPL_VERSION}_MCG_amd
export SOURCE_DIR=$HERE/chapel-${CHPL_VERSION}_MCG_amd

# Download Chapel if not found
if [ ! -d "$SOURCE_DIR" ]; then
  cd $HERE
  [ -f chapel-${CHPL_VERSION}.tar.gz ] || wget https://github.com/chapel-lang/chapel/releases/download/${CHPL_VERSION}/chapel-${CHPL_VERSION}.tar.gz
  #wget -c https://github.com/chapel-lang/chapel/releases/download/${CHPL_VERSION}/chapel-${CHPL_VERSION}.tar.gz -O - | tar xz
  tar -xf chapel-${CHPL_VERSION}.tar.gz
  mv chapel-$CHPL_VERSION $SOURCE_DIR
  # Patch hwloc Makefile
  sed -e 's|(RUNTIME_LFLAGS)|(RUNTIME_LFLAGS) -L$(EBROOTSYSLIBS) -lncursesw|' -i $SOURCE_DIR/third-party/hwloc/Makefile
  # Patch the install script as it looks like lib/cmake/chpl does not exist, or maybe this
  # is only generated in special cases.
  sed -e 's|\(myinstalldir  lib/cmake/chpl.*\)|if [ -d lib/cmake/chpl ]; then \1; fi|' -i $SOURCE_DIR/util/buildRelease/install.sh
  # Install script calls make but does not do a parallel make unfortunately.
  sed -e 's|"$MAKE"|"$MAKE" -j 16|' -i $SOURCE_DIR/util/buildRelease/install.sh
fi

CHPL_BIN_SUBDIR=$("$SOURCE_DIR"/util/chplenv/chpl_bin_subdir.py)
export PATH="$PATH":"$SOURCE_DIR/bin/$CHPL_BIN_SUBDIR:$SOURCE_DIR/util"

export CHPL_HOST_PLATFORM=$("$SOURCE_DIR"/util/chplenv/chpl_platform.py)
export CHPL_TARGET_PLATFORM=$("$SOURCE_DIR"/util/chplenv/chpl_platform.py)
export CHPL_TARGET_COMPILER="llvm"
# Target CPU
export CHPL_TARGET_ARCH=x86_64
export CHPL_TARGET_CPU=x86-trento
# Target GPU
export CHPL_LOCALE_MODEL="gpu"        # flat or gpu
export CHPL_GPU="amd"
export CHPL_GPU_ARCH="gfx90a"
export CHPL_GPU_MEM_STRATEGY="array_on_device" # default
export CHPL_ROCM_PATH=$EBROOTROCM
# Communication
# Only single-locale execution required
export CHPL_COMM="none"
export CHPL_ATOMICS='cstdlib'        # cstdlib, intrinsics, locks. Default is cstdlib.
export CHPL_LAUNCHER="none"
export CHPL_TASKS=qthreads           # qthreads or fifo (POSIX threads)
# Memory management
export CHPL_HOST_MEM=jemalloc        # cstdlib, jemalloc, mimalloc. jemalloc is the default for LUMI anyway.
export CHPL_HOST_JEMALLOC=bundled    # system, bundled or none. But bundled is the only supported one on Linux.
export CHPL_TARGET_MEM=jemalloc      # cstdlib, jemalloc, mimalloc. jemalloc is the default for LUMI anyway.
export CHPL_TARGET_JEMALLOC=bundled  # system, bundled or none. But bundled is the only supported one on Linux.
# LLVM backend to the Chapel compiler (recommended to use)
export CHPL_LLVM="bundled" # required for ROCm 6
# Other dependencies
export CHPL_HWLOC=bundled      # system, bundled or none
export CHPL_TIMERS=generic     # Only valid value at the moment
export CHPL_GMP=bundled        # system, bundled or none
export CHPL_RE2=bundled        # bundled or none, enabling support for regular expressions
export CHPL_AUX_FILESYS=none   # none or lustre. lustre does not work at the moment on LUMI as it cannot find lustre/lustreapi.h.
export CHPL_UNWIND=bundled     # system, bundled or none
export CHPL_LIB_PIC=none       # none or pic, set to pic if you want to call from other languages, e.g., Python


cd $SOURCE_DIR
#patch -N -p1 < $HERE/perf_patch.patch # see Chapel PR #24970 on Github (remove it when Chapel 2.1 is released)

# The next line is a very dangerous way of determining the value for -j for the make command!
# MAXPARALLEL=$(cat /proc/cpuinfo | grep processor | wc -l)
# Maybe safer if not all cores are available:
# MAXPARALLEL=$(lstopo | grep '+ Core' | wc -l)
MAXPARALLEL=16

# Looks like `make install` is broken when installing to a directory outside the sources and 
# using --prefix=. It tries to copy some files that do not exist.
echo -e "#\n#\n#\n# Starting configure step.\n#\n#\n#"
#./configure --chpl-home=$HERE/INSTALL
./configure --prefix=$HERE/INSTALL

echo -e "#\n#\n#\n# Starting build step.\n#\n#\n#"
#make -j $MAXPARALLEL
make -j $MAXPARALLEL VERBOSE=1

echo -e "#\n#\n#\n# Starting install step.\n#\n#\n#"
make -j $MAXPARALLEL install

cd $HERE
