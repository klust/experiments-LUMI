# Using the Perftools Application Programming Interface

1. Choose either Fortran (`F/`) or C (`C/`) and copy the start files. For instance

		cp -r C test
		cd test

2. Tracing experiment

  * Load the modules
	
			module load perftools-base
			module load perftools

  * Build and manually instrument the executable

			make cleanall; make
			pat_build -w -f himeno.exe

    Collection enabled via `PAT_RT_PERFCTR` (not set by default). Check the `job.trace.slurm` and change this variable if desired.

  * Run the instrumented application.

			sbatch job.trace.slurm

  * Generate a report from the profiling data

			pat_report -T -o myrep.trace.rpt trace_exp.*/ 
  
  * Inspect the outfile myrep.trace.rpt for the CrayPAT results.			

# Remarks

  * Can be used with sampling, tracing, or loop profiling but routine level information for HWPC are only provided for the latter two.

  * Can also be used for `perftools-lite*` experiments.

  * We have already observed collection of hardware performance counters during sampling with `perftools-lite` and APA with `perftools`.

  * The program outputs `my_output*` for `perftools` do not contain any profiling information compared to `perftools-lite*`

