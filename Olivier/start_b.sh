#! /bin/bash

for number in $(seq $1 $2)
do
	echo "Executing sbatch bound${number}.slurm"
	sbatch bound${number}.slurm
	sleep 3
done
