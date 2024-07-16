#!/usr/bin/bash

module load LUMI/23.09 partition/L
module load lumi-container-wrapper/0.3.1-cray-python-3.10.10

mkdir -p INSTALL

pip-containerize new --prefix $PWD/INSTALL requirements.txt
