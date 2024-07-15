Himeno performance test of GPU binding
======================================

In this example we examine the impact of proper and improper binding on
the performance of the himeno benchmark

Contents
--------

* **hello\_jobstep**  This is a affinity checking program developed by 
  T. Papatheodore at ORNL. It is similar to xthi in that the program prints 
  the hardware thread IDs that each MPI rank and OpenMP thread runs on, but 
  it also prints the GPU IDs that each rank/thread has access to.
  Original code at https://code.ornl.gov/olcf/hello_jobstep.

* **himeno** the himeno benchmark.

* **job.slurm** a simple jobscript.

* **select_gpu_naive.sh** a binding script for AMD GPUs

* **select_gpu_opti.sh** a binding script for AMD GPUs with proper NUMA to GPU mapping

Building
--------

Load the modules by running `source gpu_env.sh` command.
Simply run `make clean; make` in both directories.


Running
-------

Load the correct environment `source ../../lumi_g.sh`

**Step 1:**

Go inside the directory `hello_jobstep` and run with `sbatch job.slurm`.
Alter gpu_bind and cpu_bind variables in the jobscript.
You can change the number of threads by modifying the `OMP_NUM_THREADS` environment variable.
Example of output:
```
MPI 000 - OMP 000 - HWT 001 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 0 - Bus_ID c1
MPI 001 - OMP 000 - HWT 009 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 1 - Bus_ID c6
MPI 002 - OMP 000 - HWT 017 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 2 - Bus_ID c9
MPI 003 - OMP 000 - HWT 025 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 3 - Bus_ID ce
MPI 004 - OMP 000 - HWT 033 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 4 - Bus_ID d1
MPI 005 - OMP 000 - HWT 041 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 5 - Bus_ID d6
MPI 006 - OMP 000 - HWT 049 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 6 - Bus_ID d9
MPI 007 - OMP 000 - HWT 057 - Node nid005032 - RT_GPU_ID 0 - GPU_ID 7 - Bus_ID de
```

The different GPU IDs reported by the example program are:

* `GPU_ID` is the node-level (or global) GPU ID read from `ROCR_VISIBLE_DEVICES`. If this environment variable is not set (either by the user or by Slurm), the value of `GPU_ID` will be set to `N/A`.
* `RT_GPU_ID` is the HIP runtime GPU ID (as reported from, say `hipGetDevice`).
* `Bus_ID` is the physical bus ID associated with the GPUs. Comparing the bus IDs is meant to definitively show that different GPUs are being used.


**Step 2:**

Go inside the directory `himeno` and run with `sbatch job.slurm`.
Alter gpu_bind and cpu_bind variables in the jobscript.
Pay attention to the CPU runtime and the MFLOPS in the job output as these are
the two main performance metrics.
Example of output:

```
Sequential version array size
 mimax = 513 mjmax = 513 mkmax = 1025
Parallel version array size
 mimax = 259 mjmax = 259 mkmax = 515
imax = 257 jmax = 257 kmax =513
I-decomp = 2 J-decomp = 2 K-decomp =2
 Start rehearsal measurement process.
 Measure the performance in 10 times.

 MFLOPS: 16116.972106 time(s): 5.607725 3.824764e-04

 Now, start the actual measurement process.
 The loop will be excuted in 50 times
 This will take about one minute.
 Wait for a while

cpu : 21.434728 sec.
Loop executed for 50 times
Gosa : 1.213819e-03 
MFLOPS measured : 21082.503655
Score based on Pentium III 600MHz : 254.496664

real    0m29.856s
user    0m0.011s
sys     0m0.009s
... finished job 2875773 at Wed 15 Feb 2023 12:32:25 PM EET
```