# Experiments with the helo_jobstep exercise.

## Compiling

-   We tested compilation in the `LUMI/22.12 partiton/G cpeCray/22.12` environment.

    Makefile: `Makefile.cpeCray`
    
    Executable: `hell_jobstep-cce.x`


## Running

Tested with `cpeCray`.

-   Job script using 1 GPU per task: `job-1gpuPerTask.slurm`.
    
    
    
    
-   Job script using 2 GPUs per task and 4 tasks per node:
    `job-2gpuPerTask.slurm`
    
    


**Note:** According to the Crusher documentation Cray MPICH does not support
multiple GPUs per task when using GPU-aware MPI.


## Conclusions

There are two ways to obtain an optimal mapping between MPI ranks and GPUS:

-   Reorder the CPU processes/threads but use the natural order of the GPUs.

-   Use a natural ordering of the CPU processes/threads but reorder the GPUs.

For the CPU binding, due to the single core on the first CCD taken by the 
low-noise mode, one will always have to use proper CPU binding through Slurm
to guarantee a proper allocation of the CPU processes and threads across the
CCDs and NUMA domains of the node.

The GPU binding can be done either through Slurm or through a script that
sets `ROCR_VISIBLE_DEVICES` for each process. 

One has to be careful though. Several options in Slurm that can be specified
with SBATCH already do some binding so may conflict with other mechanisms to 
do the binding. E.g., using `--cpus-per-task` will already reserve cores for 
tasks and make the other cores unavailable and hence can conflict with 
other binding options. The same actually holds for `--gpus-per-task` which
does a renumbering of the GPUs that will be seen by tasks and will conflict
with several mapping options.


### Optimal order.

The only reliable way to detect the physical GPU is through the PCIe bus ID. 
All other numberings can be influenced by either environment variables or
by Slurm (using an equivalent of CPU sets?)

The proper mapping is:

| CCD | HW threads          | GCD physical number | GCD Bus_ID |
|:----|:--------------------|:--------------------|:-----------|
| 0   | 000-007 and 064-071 | 4                   | d1         |
| 1   | 008-015 and 072-079 | 5                   | d6         |
| 2   | 016-023 and 080-087 | 2                   | c9         |
| 3   | 024-031 and 088-095 | 3                   | ce         |
| 4   | 032-039 and 096-103 | 6                   | d9         |
| 5   | 040-047 and 104-111 | 7                   | de         |
| 6   | 048-055 and 112-119 | 0                   | c1         |
| 7   | 056-063 and 120-127 | 1                   | c6         |

or the reverse mapping:

| GCD physical number | GCD Bus_ID | CCD | HW threads          |
|:--------------------|:-----------|:----|:--------------------|
| 0                   | c1         | 6   | 048-055 and 112-119 |
| 1                   | c6         | 7   | 056-063 and 120-127 |
| 2                   | c9         | 2   | 016-023 and 080-087 |
| 3                   | ce         | 3   | 024-031 and 088-095 |
| 4                   | d1         | 0   | 000-007 and 064-071 |
| 5                   | d6         | 1   | 008-015 and 072-079 |
| 6                   | d9         | 4   | 032-039 and 096-103 |
| 7                   | de         | 5   | 040-047 and 104-111 |


### Reordering the CPUs, natural GPU order

Some possible arguments for `--cpu-bind` (assuming hyperthreading is not used): 

-   1 thread per process, 8 processes per node (1 GPU per process): One can use `map_cpu` 
    instead of `mask_cpu`:
    
    ```
    --cpu-bind=map_cpu:49,57,17,25,1,9,33,41 \
    --gpus-per-task=1
    ```
    
-   7 threads per process, 8 processes per node (1 GPU per process): In this case `mask_cpu` 
    should be used:
    
    ```
    --cpu-bind=mask_cpu:0x00fe000000000000,0xfe00000000000000,0x00fe0000,0xfe000000,0x00fe,0xfe00,0x00fe00000000,0xfe0000000000 \
    --gpus-per-task=1
    ```
    
    In fact, it may always be better to work with a maximal mask and then restrict 
    the number of OpenMP threads through `OMP_NUM_THREADS` instead as the extra cores
    may still be usefull for background processing, e.g., asynchronous I/O and may 
    be used through libraries.
    
-   1 thread per process, 4 processes per node (2 GPUs per process): Here we use 1 
    core in each of the 4 NUMA domains instead, and again keep it symmetrical:
    
    ```
    --cpu-bind=map_cpu:49,17,1,33 \
    --gpus-per-task=2
    ```
    
-   15 threads per process, 4 processes per node (2 GPUs per process): Here we again 
    bind each process to a NUMA domain instead of a CCD using `mask_cpu`:
    
    ```
    --cpu-bind=mask_cpu:0xfffe000000000000,0xfffe0000,0xfffe,0xfffe00000000 \
    --gpus-per-task=2
    ```
    
These cases can be combined simply with `--gpus-per-task` as this will pick the GPUs 
for each task in the "natural" order.
    
    
### Natural order for the CPUs, remapping the GPUs

We will still need to do CPU binding as it is currently impossible on LUMI to get a 
proper mapping of tasks onto CCDs or NUMA domains using just options like `--cpus-per-task`.

The mapping of the GPUs can be done either through `--gpu-bind` in Slurm or through
setting `ROCR_VISIBLE_DEVICES` for each MPI rank through a script called by `srun`
that in its turn then calls the actual executable.

Note that the GPUs in the `#SBATCH` lines should not be requested through
`--gpus-pertask` as this will interfere with the mapping, buth through
`--gpus-per-node` or `--gres=gpu:8`.


#### Through Slurm `--gpu-bind`

The options are now:

-   1 thread per process, 8 processes per node (1 GPU per process): One can use `map_cpu` 
    instead of `mask_cpu`, and can use `map_gpu` instead of `mask_gpu`:
    
    ```
    --cpu-bind=map_cpu:1,9,17,25,33,41,49,57 \
    --gpu-bind=map_gpu:4,5,2,3,6,7,0,1
    ```
    
    The alternative with `mask_cpu` would be
    
    ```
    --cpu-bind=map_cpu:1,9,17,25,33,41,49,57 \
    --gpu-bind=mask_gpu:0x10,0x20,0x04,0x08,0x40,0x80,0x01,0x02
    ```
        
-   7 threads per process, 8 processes per node (1 GPU per process): In this case `mask_cpu` 
    should be used for the CPU mapping while for the GPU mapping we can use either `map_gpu`
    or `mask_gpu` with `--gpu-bind` as in the previous case.
    
    ```
    --cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000\
    --gpu-bind=map_gpu:4,5,2,3,6,7,0,1
    ```
    
    In fact, it may always be better to work with a maximal mask and then restrict 
    the number of OpenMP threads through `OMP_NUM_THREADS` instead as the extra cores
    may still be usefull for background processing, e.g., asynchronous I/O and may 
    be used through libraries.
    
-   1 thread per process, 4 processes per node (2 GPUs per process): Here we use 1 
    core in each of the 4 NUMA domains instead, and again keep it symmetrical:
    
    ```
    --cpu-bind=map_cpu:1,17,33,49 \
    --gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03
    ```
    
-   15 threads per process, 4 processes per node (2 GPUs per process): Here we again 
    bind each process to a NUMA domain instead of a CCD using `mask_cpu`:
    
    ```
    --cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000 \
    --gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03
    ```

#### Through a script that sets `ROCR_VISIBLE_DEVICES`

One such script can be generated in the job script itself:

```
[ -f select_gpu.sh ] && /bin/rm select_gpu.sh
cat - >select_gpu.sh <<EOF
#!/bin/bash
GPUSID="4 5 2 3 6 7 0 1"
GPUSID=(\${GPUSID})
if [ \${#GPUSID[@]} -gt 0 -a -n "\${SLURM_NTASKS_PER_NODE}" ]; then
   if [ \${#GPUSID[@]} -gt \$SLURM_NTASKS_PER_NODE ]; then
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((\$SLURM_LOCALID))]}
    else
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((SLURM_LOCALID / (\$SLURM_NTASKS_PER_NODE / \${#GPUSID[@]})))]}
    fi
fi
exec \$*
EOF
chmod u+x select_gpu.sh

```

to have a single GPU per task or similary

```
[ -f select_gpu.sh ] && /bin/rm select_gpu.sh
cat - >select_gpu.sh <<EOF
#!/bin/bash
GPUSID=( "4,5" "2,3" "6,7" "0,1" )
if [ \${#GPUSID[@]} -gt 0 -a -n "\${SLURM_NTASKS_PER_NODE}" ]; then
   if [ \${#GPUSID[@]} -gt \$SLURM_NTASKS_PER_NODE ]; then
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((\$SLURM_LOCALID))]}
    else
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((SLURM_LOCALID / (\$SLURM_NTASKS_PER_NODE / \${#GPUSID[@]})))]}
    fi
fi
exec \$*
EOF
chmod u+x select_gpu.sh
```

for 2 GPUs per task (with only the first line different).

The CPU mapping option is identical as in the previous case with Slurm doing the GPU 
mapping, but now the executable is called through the wrapper script `select_gpu.sh`
which then sets the `ROCR_VISIBLE_DEVICES` environment variable.

This script only works correctly if all GPUs in a node are visible to all GPUs in the
node (which means that the `GPU_ID` reported by `hello_jobstep` wil vary between 0 
and 7). In particular, `--gpus-per-task` will limit GPU visibility for each process 
and hence change the global numbering which now becomes a separate numbering for 
each process, and Slurm does effectively that mapping of that numbering onto GPUs.

The `srun` command with the script looks like

```
srun -N 1 -n 8 --cpu-bind=map_cpu:1,9,17,25,33,41,49,57 ./select_gpu.sh  ./hello_jobstep
```