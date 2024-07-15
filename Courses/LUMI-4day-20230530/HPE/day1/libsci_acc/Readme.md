# LibSci_ACC Usage

This is an example on how to run LibSci_ACC library.

The example executes the PDGEMM function on 4 ranks on a single node, using a single GPU.
By default it considers matrices of size 10,000x10,000 elements and it runs 10 multiplications.

* Source the file to set the environment for running with SLURM on LUMI-G
* Understand the code `pdgemm.cpp` and the SLURM submission script `job.slurm`
* Submit the job with `sbatch job.slurm`
* The job will compile the example and execute on CPU and GPU via LibSci_ACC. Multiple versions are executed (check the `job.slurm` for more details)
* Check the execution timings in the SLURM log
* Could you explain the results?
* Other suggested tests:
  * Change the number of threads (variable `OMP_NUM_THREADS` in the `job.slurm`)
  * Try other PrgEnv's (change in `job.slurm`)
  * Try different number of nodes
  * Try different matrix size (variable `N` in the `job.slurm`) and number of multiplations (variable `Niter` in the `job.slurm`)
  * Try different functions
  * Try with your application


