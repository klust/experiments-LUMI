# Some simple CPU compiler tests

## leapfrog.f90

Source: [GitHub marblestation/benchmark-leapfrog](https://github.com/marblestation/benchmark-leapfrog)

```bash
amdflang -O3 -march=znver3 -fdefault-real-8 leapfrog.f90 -o leapfrog.x
```

Note that `-mcpu` does not work on x86!

Suggested compile with gfortran and 8-byte real:

```bash
gfortran -O3 -march=native -finit-real=nan -fdefault-real-8 leapfrog.f90 -o leapfrog.x
```
