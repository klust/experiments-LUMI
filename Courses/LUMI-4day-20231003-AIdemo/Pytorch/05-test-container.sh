#!/bin/bash -e

wd=$(pwd)
jobid=$(squeue --me | head -2 | tail -n1 | awk '{print $1}')


#
# Example assume allocation was created, e.g.:
# N=1 ; salloc -p standard-g  --threads-per-core 1 --exclusive -N $N --gpus $((N*8)) -t 4:00:00 --mem 0
#

set -x

#SIF=/pfs/lustrep2/projappl/project_462000125/samantao-public/containers/lumi-pytorch-rocm-5.5.1-python-3.10-pytorch-v2.0.1-dockerhash-4305da4654f4.sif
SIF=/pfs/lustrep2/projappl/project_462000125/samantao-public/containers/lumi-pytorch-rocm-5.5.1-python-3.10-pytorch-v2.0.1-debugsymbols-dockerhash-ed0246bfde67.sif

rm -rf $wd/run-me.sh 
cat > $wd/run-me.sh << EOF
#!/bin/bash -e

# Start conda environment inside the container
\$WITH_CONDA

# Run application
python -c 'import torch; print("I have this many devices:", torch.cuda.device_count())'

EOF
chmod +x $wd/run-me.sh

srun --jobid=$jobid -n1 --gpus 8 \
  singularity exec \
    -B /var/spool/slurmd:/var/spool/slurmd \
    -B /opt/cray:/opt/cray \
    -B /usr/lib64/libcxi.so.1:/usr/lib64/libcxi.so.1 \
    -B $wd:/workdir \
    $SIF /workdir/run-me.sh
   