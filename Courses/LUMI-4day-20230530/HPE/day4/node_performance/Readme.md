# Try compiler flags for Node optimizations with CCE compiler.

1. Choose either Fortran (`F/`) or C (`C/`) and copy the start files. For instance

		cp -r C test
		cd test

2. By default the compiler optimization is O3, which enables vectorization and loop optimizations.
   
  * Load the module
  
	                module load perftools-base
			module load perftools-lite-loops

  * Build and launch the application.

			make cleanall; make
			sbatch job.slurm

  * Inspect the program output `my_output.lite-loops.*`.

  * More information can be retrieved with

        	pat_report expfile.lite-loops.*/

  * Check the listing file `himeno.lst.*` and see which compiler optimizations are done.
    Note that the suffix number is the SLURM JOBID.

3. Repeat the procedure with a different compiler options, e.g. `-O1`:

                        make clean; make OPT="-O1"
			sbatch job.slurm

   * compare the outputs of the lising files and craypat-lite-loops.