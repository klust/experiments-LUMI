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
