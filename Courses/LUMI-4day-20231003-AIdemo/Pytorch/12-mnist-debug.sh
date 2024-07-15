#!/bin/bash -e

wd=$(pwd)
jobid=$(squeue --me | head -2 | tail -n1 | awk '{print $1}')

module purge
module load CrayEnv
module load PrgEnv-cray/8.3.3
module load craype-accel-amd-gfx90a
module load rocm/5.2.3.lua

if [ ! -d  $wd/miniconda3/envs/pytorch-debug ] ; then
    source $wd/miniconda3/bin/activate base
    conda create -y -n pytorch-debug python=3.8
    source $wd/miniconda3/bin/activate pytorch-debug
    pip3 install --pre torchvision==0.14.1 --extra-index-url https://download.pytorch.org/whl/rocm5.2/
else
    source $wd/miniconda3/bin/activate pytorch-debug 
fi

#
# Example assume allocation was created, e.g.:
# N=1 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus $((N*8)) -t 4:00:00 --mem 0
#

set -x

# Utility script to detect the master node
cat > $wd/get-master.py << EOF
import argparse
def get_parser():
    parser = argparse.ArgumentParser(description="Extract master node name from Slurm node list",
            formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("nodelist", help="Slurm nodelist")
    return parser


if __name__ == '__main__':
    parser = get_parser()
    args = parser.parse_args()

    first_nodelist = args.nodelist.split(',')[0]

    if '[' in first_nodelist:
        a = first_nodelist.split('[')
        first_node = a[0] + a[1].split('-')[0]

    else:
        first_node = first_nodelist

    print(first_node)
EOF

rm -rf $wd/run-me.sh 
cat > $wd/run-me.sh << EOF
#!/bin/bash -e

# Make sure GPUs are up
if [ \$SLURM_LOCALID -eq 0 ] ; then
    rocm-smi || true
fi
sleep 2

export MIOPEN_USER_DB_PATH="/tmp/$(whoami)-miopen-cache-\$SLURM_NODEID"
export MIOPEN_CUSTOM_CACHE_DIR=\$MIOPEN_USER_DB_PATH

# Set MIOpen cache to a temporary folder.
if [ \$SLURM_LOCALID -eq 0 ] ; then
    rm -rf \$MIOPEN_USER_DB_PATH
    mkdir -p \$MIOPEN_USER_DB_PATH
fi
sleep 2
  
# Report affinity
echo "Rank \$SLURM_PROCID --> \$(taskset -p \$\$)"

# Set interfaces to be used by RCCL.
export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3

# Set environment for the app
export MASTER_ADDR=\$(python $wd/get-master.py "\$SLURM_NODELIST")
export MASTER_PORT=29500
export WORLD_SIZE=\$SLURM_NPROCS
export RANK=\$SLURM_PROCID
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID

# Run app
cd $wd/mnist

python -u mnist_DDP_hang.py --gpu --modelpath $wd/mnist/model

EOF
chmod +x $wd/run-me.sh

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

Nodes=2
srun --jobid=$jobid -N $((Nodes)) -n $((Nodes*8)) --gpus $((Nodes*8)) --cpu-bind=mask_cpu:$MYMASKS \
  $wd/run-me.sh
   
# Attach to the node and check where is it hanging:
#  srun --jobid <my job id> --threads-per-core=2 --interactive --pty /bin/bash
#  rocm-smi --showpidgpus
#  rocgdb attach <process ID>