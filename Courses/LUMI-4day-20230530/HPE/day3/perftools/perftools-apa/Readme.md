# Automatic Profiling Analysis with Perftools 

1. Choose either Fortran (`F/`) or C (`C/`) and copy the start files. For instance

		cp -r C test
		cd test

2. Sampling Phase

  * Load the modules
	
			module load perftools-base
			module load perftools

  * Build and manually instrument the executable

			make cleanall; make
			pat_build himeno.exe

    	The APA (`-O apa`) is the default experiment. No option needed.

  * Run the instrumented application `himeno.exe+pat`.

			sbatch job.apa.sample.slurm

  * Generate a report from the profiling data

			pat_report -o myrep.apa_sample apa_sample_exp.*/ 

   * Inspect the newly generated `myrep.apa_sample` file and modify if desired. 

3. Event Tracing Phase based on Sampling Phase

   * Instrument the executable

        	pat_build -O apa_sample_exp.*/*.apa

     This will produce `himeno.exe+apa`

  * Run the instrumented application `himeno.exe+apa`.

			sbatch job.apa.trace.slurm

  * Generate a report from the profiling data

        	pat_report -o myrep.apa_trace apa_trace_exp.*/

  * The report `myrep.apa_trace` contains timining information for the user routines and groups identified during the sampling phase. 


# Remarks

  * The program outputs `my_output*` for `perftools` do not contain any profiling information compared to `perftools-lite*`






