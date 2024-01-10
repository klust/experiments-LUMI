#! /usr/bin/bash

echo "Working in $(pwd)."

boost_version='1.82.0'

boost_file="boost_${boost_version//./_}.tar.bz2"
[ -f "$boost_file" ] || wget https://boostorg.jfrog.io/artifactory/main/release/${boost_version}/source/$boost_file


boost_dir="boost_${boost_version//./_}"
[ -d "$boost_dir" ] && /bin/rm -rf $boost_dir
tar -xf $boost_file

[ -d "INSTALL" ] && /bin/rm -rf INSTALL
mkdir -p INSTALL

echo "Useful to copy:"
echo "export boost_dir='$(pwd)/$boost_dir'"

 