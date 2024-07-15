
# Use valgrind4hpc

Compile the example program

	make

and get an interactive session 

        salloc -N 1 --exclusive -t 1:00:00
        
Run the application in Valgrind for HPC

    module load valgrind4hpc/2.12.11
        
    valgrind4hpc -n2 --launcher-args="-u" --valgrind-args="--track-origins=yes --leak-check=full" ./test.exe
        
Read the man page of `valgrind4hpc`.

Conversely, launch the `job.slurm`.

**NOTE**: To generate the output files with line numbers  you need at least valgrind4hpc >=v2.12.11


