#! /usr/bin/bash
#

version='5.2.0-pre'
sourcedir="dl-poly-$version"
builddir=build-dspoly-cray

module load CrayEnv
module load cpe/23.09
module load cpe/23.09
module load PrgEnv-cray
module load craype-x86-milan

module load buildtools/23.09


git clone -b $version https://gitlab.com/ccp5/dl-poly $sourcedir

#export CMAKE_FC_COMPILER=ftn
export FC=ftn
#export F90=ftn
#export F77=ftn
export MPIFC=ftn
#export MPIF90=ftn
#export MPIF77=ftn

cmake -S $sourcedir -B $builddir -DCMAKE_BUILD_TYPE=Release
cd $builddir ; make 
