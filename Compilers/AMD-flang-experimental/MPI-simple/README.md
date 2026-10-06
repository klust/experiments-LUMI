# Running the tests

## hello-world.c

-   Environment:

    ```bash
    module load CrayEnv
    module purge
    module load AMD-flang-experimental/24.3.0-cray-mpich-9.1.0
    module load therock/24.3.0 mpich/4.3.1
    ```

-   Compile:

    ```bash
    mpicc hello-world.c -o hello-world-c.x
    ```

-   Run

    ```bash
    srun -psmall-g -n2 -c7 -G2 -t2:00 ./hello-world-c.x
    ```


## hello-world.f90

-   Environment:

    ```bash
    module load CrayEnv
    module purge
    module load AMD-flang-experimental/24.3.0-cray-mpich-9.1.0
    module load therock/24.3.0 mpich/4.3.1
    ```

-   Compile:

    ```bash
    mpif90 hello-world.f90 -o hello-world-f.x
    ```

-   Run

    ```bash
    srun -psmall-g -n2 -c7 -G2 -t2:00 ./hello-world-f.x
    ```
