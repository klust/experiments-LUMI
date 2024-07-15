#! /bin/bash

set -ex

cd "$(dirname "$0")"
build_dir=../build
rm -rf $build_dir
mkdir -p $build_dir
build_dir=$PWD/../build
cd $build_dir
build_dir=$PWD

set +x
module purge
module load LUMI/23.09 partition/C PrgEnv-gnu cray-fftw cray-libsci
set -x

ecbuild_dir=$build_dir/ecbuild
wget https://github.com/ecmwf/ecbuild/archive/refs/heads/develop.zip
unzip develop.zip
/bin/rm -f develop.zip
mkdir $ecbuild_dir
mv ecbuild-develop/* $ecbuild_dir/
/bin/rm -rf ecbuild-develop
export PATH=$ecbuild_dir/bin:$PATH

#install fiat
export ecbuild_ROOT=$build_dir/ecbuild
#export MPI_HOME=$OPENMPI_HOME
wget https://github.com/ecmwf-ifs/fiat/archive/refs/heads/main.zip
fiat_dir=$build_dir/fiat
unzip main.zip
rm main.zip
mkdir $fiat_dir
mv fiat-main/* $fiat_dir/
rm -rf fiat-main
cd $fiat_dir
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTS=OFF -DENABLE_OMP=ON -DENABLE_MPI=ON -DCMAKE_PREFIX_PATH=$MPI_HOME/bin -DCMAKE_C_COMPILER=cc -DCMAKE_Fortran_COMPILER=ftn
make -j
fiat_dir=$fiat_dir/build

cd $build_dir
wget https://github.com/ecmwf-ifs/ectrans/archive/refs/tags/1.2.0.tar.gz
tar xvf 1.2.0.tar.gz
rm -rf 1.2.0.tar.gz
cd ectrans-1.2.0
export ecbuild_ROOT=$ecbuild_dir
export fiat_ROOT=$fiat_dir
ectrans_src_dir=$build_dir/ectrans-1.2.0
ectrans_install_dir=$build_dir/ectrans
mkdir $ectrans_install_dir
cd $ectrans_install_dir
cmake -DENABLE_TESTS=OFF -DENABLE_SINGLE_PRECISION=ON -DENABLE_DOUBLE_PRECISION=ON -DENABLE_TRANSI=OFF -Dfiat_ROOT=$fiat_dir -DCMAKE_C_COMPILER=cc -DCMAKE_Fortran_COMPILER=ftn $ectrans_src_dir
make
rm -rf $ectrans_src_dir
