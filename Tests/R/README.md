# R instructions

## Known problems with R build via EasyBuild or from cray-R.

-   Rmpi:

    -   Not installed with Cray R
    -   `mpi.spawn.Rslaves` is not suppoted as Cray MPI does not support `MPI_Comm_spawn`.
    
-   parallel:

    -   `detectCores` detects the total number of (virtual) cores, not the number of cores
        available to the application. This happens with both Cray R and R built with EasyBuild.


## Examples

-   `Rmpi`:  Examples that are not yet functional as all use the non-supported spawning
    of processes. Needs further work if it is possible to work around that.
    
-   `parallel`:  Example of multi-core computing

-   `snow`:  Example of distributed memory computing with the snow package.

-   `foreach-*`: Examples of shared and distributed memory parallelism with the foreach
    package and various providers.


## Benchmarks to test the installation

-   `benchmarks/R-benchmark`: Benchmark developed by [Philippe Grosjean (UMons)](https://www.sciviews.org/)
    that can currently be found on the 
    ["R benchmarks" page on the R for macOS site](https://mac.r-project.org/benchmarks/).
    
-   `benchmarks/JanDeLeeuw`: Benchmark script from Jan de Leeuw found on the 
    ["R benchmarks" page on the R for macOS site](https://mac.r-project.org/benchmarks/).
    
-    `benchmarks/CrowdSourced`: Scripts based on the 
    ["Crowd sourced benchmarks" page at CRAN](https://cran.r-project.org/web/packages/benchmarkme/vignettes/a_introduction.html).