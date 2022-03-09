#! /bin/bash

for number in $(seq $1 $2)
do
	echo "Executing sbatch unbound${number}.slurm"
	sbatch unbound${number}.slurm
	sleep 3
done
