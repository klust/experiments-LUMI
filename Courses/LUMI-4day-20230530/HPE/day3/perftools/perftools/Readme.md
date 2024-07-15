# Perftools by Example

1. Choose either Fortran (`F/`) or C (`C/`) and copy the start files. For instance

		cp -r C test
		cd test

2. Sampling experiment

  * Load the modules
	
			module load perftools-base
			module load perftools

  * Build and manually instrument the executable

			make cleanall; make
			pat_build -S -f himeno.exe

  * Run the instrumented application.

			sbatch job.sample.slurm

  * Generate a report from the profiling data

			pat_report -T -o myrep.sample.rpt sample_exp.*/

  * Check the file myrep.sample.rpt for the CrayPAT output.

3. Event Tracing

  * Load the `perftools` module if not already loaded

        	module load perftools-base
        	module load perftools

  * Just relink the application if object files and user libraries have been compiled with perftools enabled. 

        	rm himeno.exe; make

   		Otherwise

			make cleanall; make

   		Manually instrument the executable

        	pat_build -u -g mpi -f himeno.exe

  * Run the instrumented application.

			sbatch job.trace.slurm

  * Generate a report from the profiling data

        	pat_report -T -o myrep.trace.rpt trace_exp.*/

  * Check the file myrep.trace.rpt for the CrayPAT output.

4. Loop profiles

  * Load the `perftools` module if not already loaded

			module load perftools-base
   			module load perftools

  * For loop profile (Cray compiler only) with `perftools` one has to use the `-h profile_generate` Fortran or `-finstrument-loops` for C and rebuild object files and user libraries. 

                module load PrgEnv-cray
        	make cleanall; make -f Makefile.loops

  * Manually instrument the executable

           	pat_build -w -g mpi -f  himeno.exe
        
* Run the instrumented application.

			sbatch job.loops.slurm

  * Generate a report from the profiling data

        	pat_report -T -o myrep.loops.rpt loops_exp.*/

  * Check the file myrep.loops.rpt for the CrayPAT output.

# Remarks

  * The program outputs `my_output*` for `perftools` do not contain any profiling information compared to `perftools-lite*`.



