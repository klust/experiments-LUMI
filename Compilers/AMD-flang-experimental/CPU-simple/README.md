# Some simple CPU compiler tests

## leapfrog code

Source: [GitHub marblestation/benchmark-leapfrog](https://github.com/marblestation/benchmark-leapfrog)


### leapfrog.f90

```bash
amdflang -O3 -march=znver3 -fdefault-real-8 leapfrog.f90 -o leapfrog.x
```

Note that `-mcpu` does not work on x86!

Suggested compile with gfortran and 8-byte real:

```bash
gfortran-14 -O3 -march=native -finit-real=nan -fdefault-real-8 leapfrog.f90 -o leapfrog.x
```

To run:

```bash
./leapfrog.x
```

and it should print 6 values spread over two lines (two coordinates of particles) with AMD or on one line
with the GNU compiler:

```
 1.1259644058906835E-05 1.1235312724417274E-05 9.829624659974493E-07
 -.2840577139902556 1458840.4078894083 127631.99775726981
```

(These values are approximate as different compilers and different optimisation options may produce 
different roundoff errors.)

In tests, the AMD flang 24.3.0 version ran in 82% of the time of the GNU gfortran 14 version.

| Compiler                   | time   |
|:---------------------------|-------:|
| therock 24.3.0             | 12.33s |
| rocm/10.0.0 (23.0.0git)    | 11.90s |
| rocm/7.2.3 (22.0.0git)     | 10.63s |
| rocm/7.0.3 new (20.0.0git) | 10.46s |
| gfortran-14 (14.3.0)       | 15.11s |
| gfortran-13 (13.3.1)       | 16.36s |
| gfortran-12 (12.3.0)       | 14.33s |
| gfortran 7.5.0             | 10.80s |

Notes:

-   Better results actually when using `-march=znver1` (yes 1!) than `-march=native` with some recent gfortran versions...
    The values in the table are with compiling with `-march=native`.


### leapfrog.c

Source: [GitHub marblestation/benchmark-leapfrog](https://github.com/marblestation/benchmark-leapfrog)

```bash
amdclang -march=znver3 -O3 -std=c99 leapfrog.c -o leapfrog.x
```

Suggested compile with gcc:

```bash
gcc-14 -std=c99 -O3 -march=znver3 -Wall leapfrog.c -o leapfrog.x
```

To run:

```bash
./leapfrog.x
```

and it should print something very close to

```
Position 1: 0.000011 0.000011 0.000001 | Position 2: -0.284058 1458840.407889 127631.997757
```

In tests, the AMD clang 24.3.0 version ran in 72% of the time of the GCC 14 version.

| Compiler                | time   |
|:------------------------|-------:|
| therock 24.3.0          | 10.73s |
| rocm/10.0.0 (23.0.0git) | 10.55s |
| rocm/7.2.3 (22.0.0git)  | 10.63s |
| rocm/7.0.3 (20.0.0git)  | 10.64s |
| gcc-14 (14.3.0)         | 14.98s |
| gcc-13 (13.3.1)         | 17.77s |
| gcc-12 (12.3.0)         | 15.99s |
| gcc 7.5.0               | 11.93s |


## Traveling Salesman code

Source: [GitHub harveytriana/TspApproach](https://github.com/harveytriana/TspApproach/tree/master),
but some corrections made in the C and C++ code.


### tsp_approach.f90

```bash
amdflang -O3 -march=znver3 tsp_approach.f90 -o tsp_approach.x
```

Suggested compile with gfortran:

```bash
gfortran-14 -O3 -march=znver3 tsp_approach.f90 -o tsp_approach.x
```

Running is done with

```bash
./tsp_approach.x
```

and it will print a lot of output with at the end the distance (7293) and the time it
took to compute that solution.

In tests, the AMD flang 24.3.0 version ran in 82% of the time of the gfortran 14 version.

| Compiler                   | time |
|:---------------------------|-----:|
| therock 24.3.0             | 6.7s |
| rocm/10.0.0 (23.0.0git)    | 6.8s |
| rocm/7.2.3 (22.0.0git)     | 6.0s |
| rocm/7.0.3 new (20.0.0git) | 5.7s |
| gfortran-14 (14.3.0)       | 8.1s |
| gfortran-13 (13.3.1)       | 7.8s |
| gfortran-12 (12.3.0)       | 8.0s |
| gfortran 7.5.0             | 4.9s |


### tsp_approach.c

```bash
amdclang -O3 -march=znver3 tsp_approach.c -o tsp_approach.x
```

Suggested compile with gcc:

```bash
gcc-14 -O3 -march=znver3 tsp_approach.c -o tsp_approach.x
```

Running is done with

```bash
./tsp_approach.x
```

and it will print a lot of output with at the end the distance (7293) and the time it
took to compute that solution.

In tests, the GCC 14 version ran in 66% of the time of the AMD clang 24.3.0 version.

| Compiler                | time  |
|:------------------------|------:|
| therock 24.3.0          | 6.18s |
| rocm/10.0.0 (23.0.0git) | 6.02s |
| rocm/7.2.3 (22.0.0git)  | 5.51s |
| rocm/7.0.3 (20.0.0git)  | 5.54s |
| gcc-14 (14.3.0)         | 4.08s |
| gcc-13 (13.3.1)         | 4.14s |
| gcc-12 (12.3.0)         | 3.99s |
| gcc 7.5.0               | 4.53s |


### tsp_approach.cpp

```bash
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
```

Suggested compile with g++:

```bash
g++-14 -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
```

Running is done with

```bash
./tsp_approach.x
```

and it will print a lot of output with at the end the distance (7293) and the time it
took to compute that solution.

In tests, the GCC 14 version ran in 71% of the time of the AMD clang 24.3.0 version.

| Compiler                | time  |
|:------------------------|------:|
| therock 24.3.0          | 6.04s |
| rocm/10.0.0 (23.0.0git) | 6.04s |
| rocm/7.2.3 (22.0.0git)  | 5.63s |
| rocm/7.0.3 (20.0.0git)  | 5.51s |
| g++-14 (14.3.0)         | 4.28s |
| g++-13 (13.3.1)         | 4.28s |
| g++-12 (12.3.0)         | 4.32s |
| g++ 7.5.0               | 3.99s |


## bisection.f90

Program 2.6 from [An Introduction to Computational Physics by Tao Pang](https://www.physics.unlv.edu/~pang/cp_f90.html)

This program uses some nonlinear functions and hence needs to link with the math library to work.

```bash
amdflang -O3 -march=znver3 bisection.f90 -o bisection.x
```

or

```bash
gfortran-14 -O3 -march=znver3 bisection.f90 -o bisection.x
```

Run with

```bash
./bisection.x
```

and it should output 3 numbers:

```
  20      1.69460011      0.00000095
```

or something very close to this (at least for the last two number).

This program ran too fast to use as a benchmark.
