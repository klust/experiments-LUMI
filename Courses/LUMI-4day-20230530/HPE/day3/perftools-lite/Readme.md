# Perftools-lite by Example

1. Choose either Fortran (`F/`) or C (`C/`) and copy the start files. For instance

		cp -r C test
		cd test

2. Sampling experiment

  * Load the module
	
			module load perftools-lite

  * Build and launch the application.

			make cleanall; make
			sbatch job.slurm

  * Inspect the program output `my_output.lite-*`. 

  * More information can be retrieved with 

			pat_report expfile.lite-samples.*/

3. Event Tracing

  * Load another `perftools-lite*` module. For instance

			module load perftools-lite-events
		
  * Just relink the application if object files and user libraries have been compiled with perftools-lite enabled. **Please change the partition and account in the batch script.**

			rm himeno.exe*; make
			sbatch job.slurm        

   		Otherwise

			make cleanall; make
			sbatch job.slurm

  * Inspect the program output `my_output.lite-events.*`. .

  * More information can be retrieved with

        	pat_report expfile.lite-events.*/


4. Loop profiles

  * Load the `perftools-lite-loops` module:

    	        module load perftools-base
        	module load perftools-lite-loops

  * For loop profile one has to rebuild object files and user libraries.

			make cleanall; make
			sbatch job.slurm

  * Inspect the program output `my_output.lite-loops.*`.

  * More information can be retrieved with

        	pat_report expfile.lite-loops.*/



