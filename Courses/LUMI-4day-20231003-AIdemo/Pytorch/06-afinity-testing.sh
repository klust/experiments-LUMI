#!/bin/bash -e

wd=$(pwd)
jobid=$(squeue --me | head -2 | tail -n1 | awk '{print $1}')


#
# Example assume allocation was created, e.g.:
# N=1 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus $((N*8)) -t 4:00:00 --mem 0
#

set -x

#
# Using 7 cores per L3 
#
srun \
    --jobid=$jobid \
    -c 7 \
    -N 2 \
    -n 16 \
    --gpus 16 \
    bash -c 'echo "$SLURM_PROCID -- GPUS $ROCR_VISIBLE_DEVICES -- $(taskset -p $$)"' | sort -n -k1

set +x
echo " ^^^^^^^^^ "
echo "  WRONG!!! "
echo ""
echo ""
echo ""


#
# Using 7 cores per L3 but ordered by the correct NUMA domain.
#

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

srun \
    --jobid=$jobid \
    --cpu-bind=mask_cpu:$MYMASKS \
    -N 2 \
    -n 16 \
    --gpus 16 \
    bash -c 'echo "$SLURM_PROCID -- GPUS $ROCR_VISIBLE_DEVICES -- $(taskset -p $$)"' | sort -n -k1

set +x
echo " ^^^^^^^^^ "
echo "  CORRECT! "
