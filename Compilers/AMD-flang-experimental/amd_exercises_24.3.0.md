# Trying to make the AMD exercises

Exercises from [github.com/amd/HPCTrainingExamples](https://github.com/amd/HPCTrainingExamples).


## HIP folder

### allocators

Unified memory example; does not work.

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


## HIP-OpenMP

Not all examples make sense on LUMI.

### CXX/saxpy_openmp_offload

OK after setting

```bash
export CXX=amdclang++
```

### CXX/saxpy_openmp_hip

This example DOES NOT WORK.


### CXX/saxpy_hip_openmp

Works correctly after setting 

```bash
export CXX=amdclang++
```


### CXX/daxpy

FAIL: Case runs but produces the wrong result.
The code does run correctly with the system ROCm 6.3.4,
with the Sam rocm/7.0.3, rocm/7.1.1, rocm/7.2.4.

With the rocm/10.0.0 module the code also fails.

This could of course be a driver issue.


### F/daxpy

``` bash
export FC=amdflang
make
./daxpy
```

-   24.3.0: Crashes with a memory fault.

-   Sam 7.0.3 module: Also core-dumps.


### F/Calling_DGEMM/explicit

``` bash
export FC=amdflang
make
```

-   24.3.0: Prints FAILED

-   Sam 7.0.3: Prints FAILED

-   Ran correctly with CCE 19 but needed to modify when building as the Cray compiler
    fails when `--offload-arch=gfx90a` is used and then claims it needs an accelerator
    module to be loaded.

-   Ran correctly with PrgEnv-amd and using rocm/6.3.4.


## atomics_openmp folder

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

-   System rocm/6.3.4: OK. All tests print PASSED.

-   24.3.0: All tests print PASSED.


## rocm-blogs-codes

### matrix-cores

Same results with 24.3.0 and system 6.3.4.

