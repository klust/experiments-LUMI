Installations:

-   24.3.0 Samuel with MPI 8.1.32: 

    -   `/pfs/lustrep3/scratch/project_462000394/amd-sw/rocm-afar/therock-afar-24.3.0-multiarch-10.1.0-592954c`

    -   MPI: `/pfs/lustrep3/scratch/project_462000394/amd-sw/rocm-afar/sw/mpich-3.4a2-rocm-afar-24.3.0-install`

-   Installation Kurt with scripts based on those of Johanna:
    `/scratch/project_462000008/kurtlust/TheRock/24.3.0/install`.


# Issues found so far with the various installations

1.  Samuel module `/appl/local/containers/test-modules/rocm-afar/24.3.0-cray-mpich.lua`
    does not include the directory with `mpicc`, etc., in the `PATH`.
    `/pfs/lustrep3/scratch/project_462000394/amd-sw/rocm-afar/sw/mpich-3.4a2-rocm-afar-24.3.0-install/bin`
    should be added to the `PATH` after loading `cray-mpich/8.1.32` to get the correct MPI\
    wrappers at the head of the `PATH`.
