#!/bin/bash
GPUSID=( "4,5" "2,3" "6,7" "0,1" )
if [ ${#GPUSID[@]} -gt 0 -a -n "${SLURM_NTASKS_PER_NODE}" ]; then
   if [ ${#GPUSID[@]} -gt $SLURM_NTASKS_PER_NODE ]; then
        export ROCR_VISIBLE_DEVICES=${GPUSID[$(($SLURM_LOCALID))]}
    else
        export ROCR_VISIBLE_DEVICES=${GPUSID[$((SLURM_LOCALID / ($SLURM_NTASKS_PER_NODE / ${#GPUSID[@]})))]}
    fi
fi
#echo "select_gpu_opt: LocalID $SLURM_LOCALID: ROCR_VISIBLE_DEVICES=$ROCR_VISIBLE_DEVICES"
exec $*
