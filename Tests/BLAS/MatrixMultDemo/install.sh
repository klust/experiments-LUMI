#! /bin/bash
#
# This script takes two arguments:
# * Name of the subdirectory of $VSC_SCRATCH
# * Name of the PBS job description file to copy.
#

if (( $# != 2 )); then
    echo 'This script takes two arguments:'
    echo '* Name of the subdirectory of $VSC_SCRATCH'
    echo '* Name of the PBS job description file to copy.'
    exit
fi

dirname=$VSC_SCRATCH/$1
pbsscript=$2

mkdir -p $dirname

find . \( -name makefile -o -name "*.[f|F]90" -o -name "*.c" \) -exec cp --parents {} $dirname \;
cp $pbsscript $dirname/$pbsscript
