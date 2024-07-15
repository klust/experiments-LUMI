# Sanitizers

1. Choose either Fortran (`fortran/`) or C (`c/`) and copy the start files. For instance

		cp -r c test
		cd test

2. Build the applications

   	        module load PrgEnv-cray
		make clean ; make

3. Get an interactive session 

                salloc -N 1 --exclusive -t 1:00:00
        
4. Run the application in sanitizers for HPC

                 module load sanitizers4hpc

	         export OMP_NUM_THREADS=2
	         sanitizers4hpc -l "-n 1" -- <exe>

    where <exe> is one of the executable: address, leak (only C), thread.

Read the man page of `sanitizers4hpc`.

**NOTE**: Crayftn doesn't provide a leak sanitizer.