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


### leapfrog.c

Source: [GitHub marblestation/benchmark-leapfrog](https://github.com/marblestation/benchmark-leapfrog)

```bash
amdclang -march=znver3 -O3 -std=c99 leapfrog.c -o leapfrog.x
```

Suggested compile with gcc:

```bash
gcc-14 -std=c99 -O3 -march=znver3 -Wall leapfrog.c -o leapfrog.x
```


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


### tsp_approach.c

```bash
amdclang -O3 -march=znver3 tsp_approach.c -o tsp_approach.x
```

Suggested compile with gfortran:

```bash
gcc-14 -O3 -march=znver3 tsp_approach.c -o tsp_approach.x
```


### tsp_approach.cpp

```bash
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
```

Suggested compile with gfortran:

```bash
g++-14 -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
```
