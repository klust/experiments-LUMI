# Perftools-lite by Example

1. Copy the start files

		cp -r C test
		cd test

2. GPU experiment

  * Make sure you have the SLURM configuration to run on GPU and the GPU modules loaded.

  * Load the module
	
			module load perftools-lite-gpu

  * Build and launch the application.

			make cleanall; make
			sbatch job.slurm

  * Inspect the program output `my_output.lite-gpu.*`. 

  * More information can be retrieved with 

			pat_report expfile.lite-gpu.*/


