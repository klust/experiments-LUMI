#!/bin/bash -e

wd=$(pwd)
jobid=$(squeue --me | head -2 | tail -n1 | awk '{print $1}')


# Example assume allocation was created, e.g.:
# N=1 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus $((N*8)) -t 4:00:00 --mem 0
#

set -x

SIF=/pfs/lustrep2/projappl/project_462000125/samantao-public/containers/lumi-pytorch-rocm-5.5.1-python-3.10-pytorch-v2.0.1-dockerhash-4305da4654f4.sif

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
    rocm-smi
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

# Start conda environment inside the container
\$WITH_CONDA

# Add omnitrace environment
export PATH=/pfs/lustrep2/projappl/project_462000125/samantao-public/omnitools/rocm-5.5.x/omniperf/bin:\$PATH
# Installed redquirements from inside the container with "python -m venv omniperf-venv"
export PYTHONPATH=/pfs/lustrep2/projappl/project_462000125/samantao-public/omnitools/removeme/omniperf-venv/lib64/python3.10/site-packages:\$PYTHONPATH

# Set interfaces to be used by RCCL.
export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3

# Set environment for the app
export MASTER_ADDR=\$(python /workdir/get-master.py "\$SLURM_NODELIST")
export MASTER_PORT=29500
export WORLD_SIZE=\$SLURM_NPROCS
export RANK=\$SLURM_PROCID
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID

# Run app
cd /workdir/mnist

pcmd=''
if [ \$RANK -eq 0 ] ; then
    omniperf profile -n myprof --device 0 --roof-only -- \$(which python) -u mnist_DDP.py --gpu --modelpath /workdir/mnist/model
else 
    for i in {1..4} ; do 
        sleep 10
        python -u mnist_DDP.py --gpu --modelpath /workdir/mnist/model
    done
fi

EOF
chmod +x $wd/run-me.sh

c=fe
MYMASKS="0x${c}000000000000,0x${c}00000000000000,0x${c}0000,0x${c}000000,0x${c},0x${c}00,0x${c}00000000,0x${c}0000000000"

Nodes=2
srun --jobid=$jobid -N $((Nodes)) -n $((Nodes*8)) --gpus $((Nodes*8)) --cpu-bind=mask_cpu:$MYMASKS \
  singularity exec \
    -B /var/spool/slurmd:/var/spool/slurmd \
    -B /opt/cray:/opt/cray \
    -B /usr/lib64/libcxi.so.1:/usr/lib64/libcxi.so.1 \
    -B $wd:/workdir \
    -B /pfs/lustrep2/projappl/project_462000125/samantao-public/omnitools:/pfs/lustrep2/projappl/project_462000125/samantao-public/omnitools \
    -B /usr/lib64/libpciaccess.so.0:/usr/lib64/libpciaccess.so.0 \
    $SIF /workdir/run-me.sh
   

exit 0

################
# Analyse with #
################
module use /pfs/lustrep2/projappl/project_462000125/samantao-public/mymodules
module load omniperf/1.0.10-rocm-5.5.x
source /pfs/lustrep2/projappl/project_462000125/samantao-public/omnitools/venv/bin/activate
cd $wd/mnist
omniperf analyze -p workloads/myprof/mi200 --gui 12345
