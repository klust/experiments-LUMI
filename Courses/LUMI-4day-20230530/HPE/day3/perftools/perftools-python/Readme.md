
1) Load the module

    module load cray-python

2) We require the python package `matplotlib`:

	pip install matplotlib

3) The Python example is taken from https://github.com/csc-training/hpc-python,
   specifically https://github.com/csc-training/hpc-python/blob/master/mpi/heat-equation/solution/heat-p2p.py.

4) Launch the job via

	sbatch job.slurm

5) Generate the report

	pat_report -O ct+src -o myrep.ct python+*/

6) Inspect the file `myrep.ct`.
