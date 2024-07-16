#! /bin/bash

for number in $(seq $1 $2)
do
	#echo "Executing sbatch healthy$(printf '%05d' $number).slurm"
	#sbatch healthy$(printf '%05d' $number).slurm
	echo "Executing sbatch healthy_unbound$(printf '%05d' $number).slurm"
	sbatch healthy_unbound$(printf '%05d' $number).slurm
	sleep 2
done
