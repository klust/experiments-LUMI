#!/bin/bash

#$export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD:/opt/cray/pe/cce/15.0.1/cce-clang/x86_64/lib:/opt/cray/pe/cce/15.0.1/cce/x86_64/lib/
#ls /opt/cray/pe/cce/15.0.1/cce/x86_64/lib/

python3 hello.py & 
sleep 5
for i in {1..30}; do
sleep .3
rocm-smi
done
wait
