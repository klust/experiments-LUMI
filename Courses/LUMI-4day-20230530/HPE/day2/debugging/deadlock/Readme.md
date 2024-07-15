# Using GDB for HPC

Compile the example program

	make
	
and get an interactive session 

	salloc -N 1 --exclusive -t 1:00:00
	
Launch the GDB for HPC and lauch the application

        module load gdb4hpc

	gdb4hpc
	dbg all> launch $p{2} deadlock
	
show the initial breakpoint and then proceed to the deadlock

	dbg all> bt
	dbg all> c
	dbg all> halt
	dbg all> bt
	
Type `help` to get instant help on the commands or read the man page of `gdb4hpc`.

Conversely, launch the `job.slurm`. Get the `<slurm_stepid>` from the `<slurm_jobid>` with 

	sstat <slurm_jobid>
	
Now attach to the running job

	gdb4hpc
	dgb all> attach $p <slurm_jobid>.<slurm_stepid>
	dbg all> bt
	
	

