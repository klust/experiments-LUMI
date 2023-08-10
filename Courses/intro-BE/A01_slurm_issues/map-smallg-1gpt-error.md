# Wrong allocations on small-g when asking for 1 core per task.

*Observed in Slurm 22.05.8*

Relevant documentation:

-   [sbatch command](https://slurm.schedmd.com/archive/slurm-22.05.8/sbatch.html)

Consider the job script:

```
#! /bin/bash
#SBATCH --job-name=map-smallg-1gpt-error
#SBATCH --output %x-%j.txt
#SBATCH --partition=small-g
#SBATCH --ntasks=12
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

echo "Requested resources as reported through SLURM_ variables:"
echo "- SLURM_NTASKS: $SLURM_NTASKS"
echo "- SLURM_CPUS_PER_TASK: $SLURM_CPUS_PER_TASK"
echo "- SLURM_GPUS_PER_TASK: $SLURM_GPUS_PER_TASK"
echo "Distribution based on SLURM_ variables:"
echo "- SLURM_JOB_NUM_NODES: $SLURM_JOB_NUM_NODES"
echo "- SLURM_JOB_NODELIST: $SLURM_JOB_NODELIST"
echo "- SLURM_TASKS_PER_NODE: $SLURM_TASKS_PER_NODE"
echo "- SLURM_JOB_CPUS_PER_NODE: $SLURM_JOB_CPUS_PER_NODE"
echo
echo "Control: All SLURM_ and SRUN_ variables:"
env | egrep ^SLURM_
env | egrep ^SRUN_
echo

set -x
srun -n 12 -c 1 --cpus-per-gpu=1 gpu_check -l
set +x

/bin/rm -f select_gpu_$SLURM_JOB_ID echo_dev_$SLURM_JOB_ID
```

Obviously by asking for 12 tasks with each one GPU we force the allocation to use more than one node.

When running this job script, `srun` produces an error message:

```
+ srun -n 12 -c 1 --cpus-per-gpu=1 gpu_check -l
srun: error: Unable to create step for job 4359715: More processors requested than permitted
```

To investigate the cause one can inspect a number of `SLURM_*` variables that give more information
about the allocation which is done in the job script:

```
Requested resources as reported through SLURM_ variables:
- SLURM_NTASKS: 12
- SLURM_CPUS_PER_TASK: 1
- SLURM_GPUS_PER_TASK: 1
Distribution based on SLURM_ variables:
- SLURM_JOB_NUM_NODES: 2
- SLURM_JOB_NODELIST: nid[007292-007293]
- SLURM_TASKS_PER_NODE: 8,4
- SLURM_JOB_CPUS_PER_NODE: 5,0
```

Some other environment variables give more information about the first node only of the allocation:

```
SLURM_JOB_GPUS=0,1,2,3,4,5,6,7
SLURM_CPUS_ON_NODE=5
```

Instead of allocating 8 cores on the first and 4 on the second node, Slurm has only allocated 5 cores, all on the 
first node.

As soon as we increase `--cpus-per-task` we get a correct allocation though:

```
Requested resources as reported through SLURM_ variables:
- SLURM_NTASKS: 12
- SLURM_CPUS_PER_TASK: 2
- SLURM_GPUS_PER_TASK: 1
Distribution based on SLURM_ variables:
- SLURM_JOB_NUM_NODES: 2
- SLURM_JOB_NODELIST: nid[007262-007263]
- SLURM_TASKS_PER_NODE: 8,4
- SLURM_JOB_CPUS_PER_NODE: 16,8
```

When I lowered the number of tasks to 8 and was lucky enough to get the allocation on a single node,
the allocation was also OK:

```
Requested resources as reported through SLURM_ variables:
- SLURM_NTASKS: 8
- SLURM_CPUS_PER_TASK: 1
- SLURM_GPUS_PER_TASK: 1
Distribution based on SLURM_ variables:
- SLURM_JOB_NUM_NODES: 1
- SLURM_JOB_NODELIST: nid007263
- SLURM_TASKS_PER_NODE: 8
- SLURM_JOB_CPUS_PER_NODE: 8
```
