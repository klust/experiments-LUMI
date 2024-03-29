#!/bin/bash -e

if [ $SLURM_LOCALID -eq 0 ] ; then
    rocm-smi
fi
sleep 2

$WITH_CONDA

export MIOPEN_USER_DB_PATH="/tmp/$(whoami)-miopen-cache-$SLURM_NODEID"
export MIOPEN_CUSTOM_CACHE_DIR=$MIOPEN_USER_DB_PATH

if [ $SLURM_LOCALID -eq 0 ] ; then
    rm -rf $MIOPEN_USER_DB_PATH
    mkdir -p $MIOPEN_USER_DB_PATH
fi
sleep 2

#export NCCL_DEBUG=INFO
#export NCCL_DEBUG_SUBSYS=INIT,COLL

export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3
export NCCL_NET_GDR_LEVEL=3

export ROCR_VISIBLE_DEVICES=$SLURM_LOCALID

echo "Rank $SLURM_PROCID --> $(taskset -p $$); GPU $ROCR_VISIBLE_DEVICES"

export MASTER_ADDR=$(python get-master.py "$SLURM_NODELIST")
export MASTER_PORT=29500
export WORLD_SIZE=$SLURM_NPROCS
export RANK=$SLURM_PROCID
export ROCR_VISIBLE_DEVICES=$SLURM_LOCALID

cd /workdir/mnist
python -u mnist_DDP.py --gpu --modelpath model
