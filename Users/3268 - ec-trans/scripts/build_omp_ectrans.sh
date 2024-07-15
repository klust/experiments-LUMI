#! /bin/bash

set -ex

#cd "$(dirname "$0")"
#cd ..
build_dir="$PWD/build"

ecbuild_install_dir="$build_dir/ecbuild"
fiat_install_dir="$build_dir/fiat"
ectrans_install_dir="$build_dir/ectrans"
# Use a higher value for the next one to get a parallel make, or 1 for a serial make
make_parallel=32

set +x
module purge
module load LUMI/23.09 partition/C
module load PrgEnv-gnu cray-fftw cray-libsci buildtools
set -x

#
# Install ecTrans
#
cd "$build_dir"
wget https://github.com/ecmwf-ifs/ectrans/archive/refs/tags/1.2.0.tar.gz
tar xvf 1.2.0.tar.gz
rm -rf 1.2.0.tar.gz
cd ectrans-1.2.0
export ecbuild_ROOT="$ecbuild_install_direcbuild_install_dir"
export fiat_ROOT="fiat_install_dir"
ectrans_src_dir="$build_dir/ectrans-1.2.0"
mkdir build && cd build
module load cray-fftw cray-libsci
#
# The next is OK if you want a multithreaded BLAS. But according to the developers it is better to use
# a single threaded BLAS (ticket #3268)
#
cmake .. -DCMAKE_INSTALL_PREFIX="$ectrans_install_dir" \
         -DENABLE_TESTS=OFF -DENABLE_SINGLE_PRECISION=ON -DENABLE_DOUBLE_PRECISION=ON -DENABLE_TRANSI=OFF \
         -Dfiat_ROOT="$fiat_install_dir" \
         -DCMAKE_C_COMPILER=cc \
         -DCMAKE_Fortran_COMPILER=ftn \
         -DCMAKE_SHARED_LINKER_FLAGS="-craype-verbose -fopenmp" -DCMAKE_EXE_LINKER_FLAGS="-craype-verbose -fopenmp"
sed -i -e 's|/opt/cray/pe/fftw.*libfftw3f.so -lsci_gnu ||' src/trans/CMakeFiles/trans_dp.dir/link.txt
sed -i -e 's|/opt/cray/pe/fftw.*libfftw3f.so -lsci_gnu ||' src/trans/CMakeFiles/trans_sp.dir/link.txt
#
# The next hack links a single-threaded version of the BLAS libraries:
# The trick is to
#   (a) Remove all the rubish that CMake adds to the link line for some unclear reasons
#   (b) Avoid specifying -fopenmp when linking.
# 
cmake .. -DCMAKE_INSTALL_PREFIX="$ectrans_install_dir" \
         -DENABLE_TESTS=OFF -DENABLE_SINGLE_PRECISION=ON -DENABLE_DOUBLE_PRECISION=ON -DENABLE_TRANSI=OFF \
         -Dfiat_ROOT="$fiat_install_dir" \
         -DCMAKE_C_COMPILER=cc \
         -DCMAKE_Fortran_COMPILER=ftn  \
         -DCMAKE_SHARED_LINKER_FLAGS="-craype-verbose" -DCMAKE_EXE_LINKER_FLAGS="-craype-verbose"
sed -i -e 's|/opt/cray/pe/fftw.*libfftw3_omp.so ||' src/trans/CMakeFiles/trans_dp.dir/link.txt
sed -i -e 's|/opt/cray/pe/fftw.*libfftw3_omp.so ||' src/trans/CMakeFiles/trans_sp.dir/link.txt
#
# Now build and install        
#
make -j$make_parallel VERBOSE=1
make install
cd "$build_dir"
/bin/rm -rf ectrans-1.2.0

set +ex



