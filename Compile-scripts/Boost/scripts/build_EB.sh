#! /usr/bin/bash

echo "Working in $(pwd)."

cpe_version='23.09'

module load LUMI/$cpe_version partition/L
module load cpeCray/$cpe_version

ml bzip2/1.0.8-cpeCray-$cpe_version
ml zlib/1.2.13-cpeCray-$cpe_version

#
# Are the latter used? It looks like ICU may be useful when building b2, but is
# dangerous as another compiler is being used?
#
ml zstd/1.5.5-cpeCray-$cpe_version
ml ICU/73.2-cpeCray-$cpe_version
#ml libunwind/1.6.2-cpeCray-$cpe_version

./bootstrap.sh --with-toolset=gcc --prefix="$PWD/../INSTALL" --without-libraries=python

cat >user-config.jam <<EOF
using clang : : /opt/cray/pe/craype/2.7.23/bin/CC ;
using mpi : : <include>. : srun ;
EOF

# The next variable should solve the linking problem with libunwind.
export CCC_OVERRIDE_OPTIONS="x--target=x86_64-pc-linux"
export CRAYROOTLIBUNWIND="/opt/cray/pe/cce/16.0.1/cce-clang/x86_64/lib/x86_64-unknown-linux-gnu"
export CXX=CC
#export CXXFLAGS="-O2 -fPIC -craype-verbose -std=c++11 -L$CRAYROOTLIBUNWIND -Qunused-arguments"
export CXXFLAGS="-O2 -fPIC -craype-verbose -std=c++11 -Qunused-arguments"
export LDFLAGS="-L$EBROOTICU/lib -L$EBROOTZSTD/lib -L$EBROOTZLIB/lib -L$EBROOTBZIP2/lib"
# LDFLAGS="$LDFLAGS -L$CRAYROOTLIBUNWIND"
# LDFLAGS="$LDFLAGS -L/opt/cray/pe/libsci/23.09.1.1/CRAY/12.0/x86_64/lib "
# LDFLAGS="$LDFLAGS -L$EBROOTLIBUNWIND/lib "

./b2  \
    --prefix=/project/project_462000008/kurtlust/LUMI-links/SW/LUMI-23.09/L/EB/Boost/1.82.0-cpeCray-23.09 \
    --user-config=user-config.jam \
    toolset=clang \
    cxxflags="$CXXFLAGS" \
    linkflags="$LDFLAGS" \
    -s ZLIB_INCLUDE="$EBROOTZLIB/include" -s ZLIB_LIBPATH="$EBROOTZLIB/lib" \
    -s BZIP2_INCLUDE="$EBROOTBZIP2/include" -s BZIP2_LIBPATH="$EBROOTBZIP2/lib" \
    --without-python \
    threading=single,multi \
    --layout=tagged \
    -j 256
   
 