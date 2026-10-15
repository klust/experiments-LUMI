# Trying to make the AMD exercises

Exercises from [github.com/amd/HPCTrainingExamples](https://github.com/amd/HPCTrainingExamples).


## HIP folder

Unless otherwise specified, the environment is initialised with

``` bash
module purge
module load CrayEnv AMD-flang-experimenta/24.3.0-MPI therock
```


### allocators

Build and run with

``` bash
HSA_XNACK=1 CXX=amdclang++ HIP_PLATFORM=amd make clean test
```

and it runs OK, but there are no results to check correctness.


### basic_examples

#### 01_error_check

OK when running the solution

#### 02_add_d2h_data_transfer

OK when running the solution

#### 03_complete_square_elements

OK when running the solution

#### 04_complete_matrix_multiply

OK when running the solution

#### 05_compare_with_library/

OK

#### 06_hipify_pingpong

```bash
hipify-perl pingpong.cu >pingpong.cpp
```

Then add 

```C
#include <string.h>
```

to the header files in `pingping.cpp`

Then

```bash
make
./pingpong
```

#### 07_matrix_multiply_shared

OK when running the solution


### transpose

``` bash
make clean all
./transpose_kernel_read_contiguous
./transpose_kernel_write_contiguous
./transpose_tiled
./transpose_rocblas
./transpose_timed
```

All tests pass in 24.3.0.


## HIP-OpenMP

Not all examples make sense on LUMI.

Unless otherwise specified, the environment is initialised with

``` bash
module purge
module load CrayEnv AMD-flang-experimenta/24.3.0-MPI therock
```


### CXX/saxpy_openmp_offload

OK after setting

```bash
export CXX=amdclang++
unset HSA_XNACK
make clean test
```

### CXX/saxpy_openmp_hip

Works correctly after setting 

```bash
export CXX=amdclang++
unset HSA_XNACK
make clean test
```


### CXX/saxpy_hip_openmp

Works correctly after setting 

```bash
export CXX=amdclang++
unset HSA_XNACK
make clean test
```


### CXX/saxpy_APU

Works correctly when built with

```bash
CXX=amdclang++ HSA_XNACK=1 make clean test
```


### CXX/interop

There is a problem with the Makefile as with 24.3.0, we need to manually link libm,
so `LDFLAGS` needs to be changed in the Makefile.

``` bash
unset HSA_XNACK
CXX=amdclang HIPCC=hipcc make clean interop
./interop
```

Passes with 24.3.0.


### CXX/daxpy

``` bash
unset HSA_XNACK
CXX=amdclang++ HIP_PLATFORM=amd make clean test
```

Works with 24.3.0 if the environment is clean before loading AMD-flang-experimental.

The code does run correctly with the system ROCm 6.3.4,
with the Sam rocm/7.0.3, rocm/7.1.1, rocm/7.2.4.

With the rocm/10.0.0 module the code fails though.

This could of course be a driver issue.


### F/daxpy

``` bash
FC=amdflang make clean daxpy
./daxpy
```

-   24.3.0: works if the environment is clean when loading the AMD-flang-experimental module.


### F/Calling_DGEMM/explicit

``` bash
FC=amdflang make clean test
```

-   24.3.0: Prints FAILED

-   Sam 7.0.3: Prints FAILED

-   Ran correctly with CCE 19 but needed to modify when building as the Cray compiler
    fails when `--offload-arch=gfx90a` is used and then claims it needs an accelerator
    module to be loaded.

-   Ran correctly with PrgEnv-amd and using rocm/6.3.4.


### F/Calling_DGEMM/explicit

``` bash
HSA_XNACK=1 FC=amdflang make clean test
```

-   24.3.0: Passes the test.


## atomics_openmp folder

Build with:

``` bash
CC=amdclang make clean all
```

-   Testing with 24.3.0.

    -   arraysum1: OK
    
    -   arraysum2 till arraysum4 also OK with HSA_XNACK=1

    -   arraysum5 till arraysum7: wrong result (with HSA_XNACK=1)

    -   arraysum8 OK

    -   arraysum9 fails with wrong result

    -   arraysum10 OK

-   With ROCm 7.0.3:

    -   arraysum1 OK

    -   arraysum2 till arraysum4 also OK with HSA_XNACK=1

    -   arraysum5 and arraysum6: wrong result (with HSA_XNACK=1)

    -   arraysum7 OK

    -   arraysum8 and arraysum9 fail with wrong result

    -   arraysum10 OK

-   With the system ROCm/6.3.4 all tests are OK.

-   With Sam rocm/6.4.4 module, tests 5 and 6 fail while all other tests work.
    With our own rocm/6.4.4 module compiling fails. For some reason, the module 
    fails to find the `.bc` files even though they are installed.


## HIP-Optimizations folder

### daxpy

``` bash
make
for i in $(seq 1 5); do ./daxpy_$i 1000000 ; done
```

-   System rocm/6.3.4: OK. All tests print PASSED.

-   24.3.0: All tests print PASSED.


## rocm-blogs-codes

### matrix-cores

Same results with 24.3.0 and system 6.3.4.

