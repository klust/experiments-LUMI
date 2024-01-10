#! /usr/bin/bash

echo "Working in $(pwd)."

cpe_version='23.09'

module load LUMI/$cpe_version partition/L
module load cpeCray/$cpe_version

./bootstrap.sh --with-toolset=CC --prefix="$PWD/../INSTALL" --without-libraries=python
#./bootstrap.sh --with-toolset=clang --cxx="c++" --prefix="$PWD/../INSTALL" --without-libraries=python
 
 