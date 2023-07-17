# Tests based on the lumi-CPEtools modules

For all tests, load the appropriate version of the LUMI software stack and one instance 
of the desired version of the `lumi-CPEtools` module. The scripts use that information 
to select which modules they should load for each partition and toolchain.

-   Tests for the login node: Simply go into the `LUMI-L` subdirectory and run the `run_tests.sh` 
    script.
    
-   Tests for LUMI-C in the `LUMI-C` subirectory: 

    -   Note that `start_hybrid_lumiC2.slurm` just users other OpenMP options as 
        `start_hybrid_lumi\C.slurm`.
        
    -   Try
    
        ```
        for f in $(/bin/ls -1 *s.lurm); do sbatch $f ; done
        ```
        
-   Tests for LUMI-G:

    -   The scripts with `gpu_check` in their name run both `huybrid_check` and
        `gpu_check` as they provide different information.
        
    -   Scripts with `_het_` in the name test heterogeneous hybrid jobs.
    
    -   Submit all jobs:
    
        ```
        for f in $(/bin/ls -1 *s.lurm); do sbatch $f ; done
        ```
    