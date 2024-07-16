#! /bin/bash

for number in $(seq $1 $2)
do
	echo "Executing sbatch unhealthy_unbound$(printf '%05d' $number).slurm"
	sbatch unhealthy2_unbound$(printf '%05d' $number).slurm
	sleep 2
done
