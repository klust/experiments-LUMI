# Small-g, multiple jobs on the node


Job script/: 

``` bash
#! /bin/bash
#SBATCH --job-name=small-multiple-jobs-node-1gpt
#SBATCH --output %x-%j.txt
#SBATCH --partition=spec-small
#SBATCH --ntasks=10
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=1
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

set -x
srun gpu_check -l
set +x
sleep 30

/bin/rm -f select_gpu_$SLURM_JOB_ID echo_dev_$SLURM_JOB_ID
```

Submitted to the `spec-small` test partition with 4 nodes:

``` bash
#!/bin/bash
sbatch small-multiple-jobs-node.slurm
sleep 1
sbatch small-multiple-jobs-node.slurm
sleep 1
sbatch small-multiple-jobs-node.slurm
```

The first job got the first two nodes in the partition and has a nice distribution: Each task gets two cores
on a separate CCD. Only the GPU selected for each task is not optimal:

```
MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 000 - OMP 001 - HWT 002 (CCD0) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 001 - OMP 000 - HWT 009 (CCD1) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 001 - OMP 001 - HWT 010 (CCD1) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 002 - OMP 000 - HWT 017 (CCD2) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 002 - OMP 001 - HWT 018 (CCD2) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 003 - OMP 000 - HWT 025 (CCD3) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 003 - OMP 001 - HWT 026 (CCD3) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 004 - OMP 000 - HWT 033 (CCD4) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 004 - OMP 001 - HWT 034 (CCD4) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 005 - OMP 000 - HWT 041 (CCD5) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 005 - OMP 001 - HWT 042 (CCD5) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 006 - OMP 000 - HWT 049 (CCD6) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 006 - OMP 001 - HWT 050 (CCD6) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 007 - OMP 000 - HWT 057 (CCD7) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 007 - OMP 001 - HWT 058 (CCD7) - Node nid005004 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 008 - OMP 000 - HWT 001 (CCD0) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 008 - OMP 001 - HWT 002 (CCD0) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 009 - OMP 000 - HWT 009 (CCD1) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 009 - OMP 001 - HWT 010 (CCD1) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
```
The second task got the next two nodes in the partition and has the same nice distribution as the first job:

```
MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 000 - OMP 001 - HWT 002 (CCD0) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 001 - OMP 000 - HWT 009 (CCD1) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 001 - OMP 001 - HWT 010 (CCD1) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 002 - OMP 000 - HWT 017 (CCD2) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 002 - OMP 001 - HWT 018 (CCD2) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 003 - OMP 000 - HWT 025 (CCD3) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 003 - OMP 001 - HWT 026 (CCD3) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 004 - OMP 000 - HWT 033 (CCD4) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 004 - OMP 001 - HWT 034 (CCD4) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 005 - OMP 000 - HWT 041 (CCD5) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 005 - OMP 001 - HWT 042 (CCD5) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 006 - OMP 000 - HWT 049 (CCD6) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 006 - OMP 001 - HWT 050 (CCD6) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 007 - OMP 000 - HWT 057 (CCD7) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 007 - OMP 001 - HWT 058 (CCD7) - Node nid005006 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 008 - OMP 000 - HWT 001 (CCD0) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 008 - OMP 001 - HWT 002 (CCD0) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d1(GCD4/CCD0)
MPI 009 - OMP 000 - HWT 009 (CCD1) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
MPI 009 - OMP 001 - HWT 010 (CCD1) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d9(GCD6/CCD4)
```

The third job is less lucky though. There are no free nodes anymore, but there are 6 GPUs left on
the second and fourth node of the partition, so Slurm can start the job:

```
MPI 000 - OMP 000 - HWT 003 (CCD0) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 000 - OMP 001 - HWT 011 (CCD1) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID d6(GCD5/CCD1)
MPI 001 - OMP 000 - HWT 017 (CCD2) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 001 - OMP 001 - HWT 025 (CCD3) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 002 - OMP 000 - HWT 033 (CCD4) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 002 - OMP 001 - HWT 034 (CCD4) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID cc(GCD3/CCD3)
MPI 003 - OMP 000 - HWT 041 (CCD5) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 003 - OMP 001 - HWT 042 (CCD5) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 004 - OMP 000 - HWT 049 (CCD6) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 004 - OMP 001 - HWT 050 (CCD6) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 005 - OMP 000 - HWT 057 (CCD7) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 005 - OMP 001 - HWT 058 (CCD7) - Node nid005005 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 006 - OMP 000 - HWT 033 (CCD4) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 006 - OMP 001 - HWT 034 (CCD4) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c9(GCD2/CCD2)
MPI 007 - OMP 000 - HWT 041 (CCD5) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 007 - OMP 001 - HWT 042 (CCD5) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID dc(GCD7/CCD5)
MPI 008 - OMP 000 - HWT 049 (CCD6) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 008 - OMP 001 - HWT 050 (CCD6) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1(GCD0/CCD6)
MPI 009 - OMP 000 - HWT 057 (CCD7) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
MPI 009 - OMP 001 - HWT 058 (CCD7) - Node nid005007 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c6(GCD1/CCD7)
```

Note that on both nodes used now there are already twho HWTs in use on both CCD0 and CCD1, and GCD4 and GCD6
are also in use.

We'd hope that in line with the other allocations, the job would not only use HWTs on CCD2 till CCD7
and then 4 CCDs in the range CCD2-CCD7 of the second node.

What we see instead is the the first MPI task is scheduled on 2 HWTs of CCD0 and CCD1 and the second
HWT is then spread out over CCD2 and CCD3 after which everything is normal on the first node. On the 
second node it may seem somewhat strange that the 4 last CCDs are used instead of 2 till 5, but at least
each task is scheduled nicely on its own CCD.
