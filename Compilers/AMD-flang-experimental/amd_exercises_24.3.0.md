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


### HIP-OpenMP

Not all examples make sense on LUMI.

#### CXX/saxpy_openmp_offload

OK after setting

```bash
export CXX=amdclang++
```

#### CXX/saxpy_openmp_hip

This example DOES NOT WORK.


#### CXX/saxpy_hip_openmp

Works correctly after setting 

```bash
export CXX=amdclang++
```


#### CXX/daxpy

FAIL: Case runs but produces the wrong result.
The code does run correctly with the system ROCm 6.3.4,
with the Sam rocm/7.0.3, rocm/7.1.1, rocm/7.2.4.

With the rocm/10.0.0 module the code also fails.

This could of course be a driver issue.


TO FX examples.


#### F/daxpy

``` bash
export FC=amdflang
make
./daxpy
```

-   24.3.0: Crashes with a memory fault.

-   Sam 7.0.3 module: Also core-dumps.


#### F/Calling_DGEMM/explicit

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
