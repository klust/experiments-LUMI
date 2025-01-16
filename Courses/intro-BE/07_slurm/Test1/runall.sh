#! /bin/bash

for f in $(/bin/ls -1 example*.slurm)
do
    #sbatch --reservation=pahse3_integration $f
    sbatch --reservation=lust $f
    sleep 1
done