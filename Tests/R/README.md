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

