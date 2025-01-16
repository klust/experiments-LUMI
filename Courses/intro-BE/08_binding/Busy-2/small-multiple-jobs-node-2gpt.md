# Small-g, multiple jobs on the node, 2 GPUS per task


Job script: 

``` bash
#! /bin/bash
#SBATCH --job-name=small-multiple-jobs-node-2gpt
#SBATCH --output %x-%j.txt
#SBATCH --partition=spec-small
#SBATCH --ntasks=5
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-task=2
#SBATCH --hint=nomultithread
#SBATCH --time=5:00

module load LUMI/22.12 partition/G lumi-CPEtools/1.1-cpeCray-22.12

set -x
srun gpu_check -l
set +x

sleep 30
```

Submitted to the `spec-small` test partition with 4 nodes:

``` bash
#!/bin/bash
sbatch small-multiple-jobs-node-2gpt.slurm
sleep 1
sbatch small-multiple-jobs-node-2gpt.slurm
sleep 1
sbatch small-multiple-jobs-node-2gpt.slurm
```

The first job got the first two nodes in the partition and has a nice distribution: Each task gets two cores
spread over 2 CCDs. **Not sure what's happening here with the GPUs as they are in the optimal order
on the first node (we did not use the `slect_gpu` script).**

```
MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1)
MPI 000 - OMP 001 - HWT 009 (CCD1) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1)
MPI 001 - OMP 000 - HWT 017 (CCD2) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),cc(GCD3/CCD3)
MPI 001 - OMP 001 - HWT 025 (CCD3) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),cc(GCD3/CCD3)
MPI 002 - OMP 000 - HWT 033 (CCD4) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d9(GCD6/CCD4),dc(GCD7/CCD5)
MPI 002 - OMP 001 - HWT 041 (CCD5) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d9(GCD6/CCD4),dc(GCD7/CCD5)
MPI 003 - OMP 000 - HWT 049 (CCD6) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 003 - OMP 001 - HWT 057 (CCD7) - Node nid005004 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 004 - OMP 000 - HWT 001 (CCD0) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d9(GCD6/CCD4)
MPI 004 - OMP 001 - HWT 009 (CCD1) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d9(GCD6/CCD4)
```
The second task got the next two nodes in the partition and has the same nice distribution as the first job:

```
MPI 000 - OMP 000 - HWT 001 (CCD0) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1)
MPI 000 - OMP 001 - HWT 009 (CCD1) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d6(GCD5/CCD1)
MPI 001 - OMP 000 - HWT 017 (CCD2) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),cc(GCD3/CCD3)
MPI 001 - OMP 001 - HWT 025 (CCD3) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),cc(GCD3/CCD3)
MPI 002 - OMP 000 - HWT 033 (CCD4) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d9(GCD6/CCD4),dc(GCD7/CCD5)
MPI 002 - OMP 001 - HWT 041 (CCD5) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d9(GCD6/CCD4),dc(GCD7/CCD5)
MPI 003 - OMP 000 - HWT 049 (CCD6) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 003 - OMP 001 - HWT 057 (CCD7) - Node nid005006 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 004 - OMP 000 - HWT 001 (CCD0) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d9(GCD6/CCD4)
MPI 004 - OMP 001 - HWT 009 (CCD1) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d1(GCD4/CCD0),d9(GCD6/CCD4)
```

The third job is less lucky though. There are no free nodes anymore, but there are 6 GPUs left on
the second and fourth node of the partition, so Slurm can start the job:

```
MPI 000 - OMP 000 - HWT 017 (CCD2) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),d6(GCD5/CCD1)
MPI 000 - OMP 001 - HWT 025 (CCD3) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c9(GCD2/CCD2),d6(GCD5/CCD1)
MPI 001 - OMP 000 - HWT 033 (CCD4) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID cc(GCD3/CCD3),dc(GCD7/CCD5)
MPI 001 - OMP 001 - HWT 041 (CCD5) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID cc(GCD3/CCD3),dc(GCD7/CCD5)
MPI 002 - OMP 000 - HWT 049 (CCD6) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 002 - OMP 001 - HWT 057 (CCD7) - Node nid005005 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 003 - OMP 000 - HWT 017 (CCD2) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d6(GCD5/CCD1),dc(GCD7/CCD5)
MPI 003 - OMP 001 - HWT 025 (CCD3) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID d6(GCD5/CCD1),dc(GCD7/CCD5)
MPI 004 - OMP 000 - HWT 033 (CCD4) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
MPI 004 - OMP 001 - HWT 041 (CCD5) - Node nid005007 - RT_GPU_ID 0,1 - GPU_ID 0,1 - Bus_ID c1(GCD0/CCD6),c6(GCD1/CCD7)
```

The CPU mapping is OK, but the GPU mapping is not because it was alreasdy suboptimal on the second node of the first 
two jobs.
