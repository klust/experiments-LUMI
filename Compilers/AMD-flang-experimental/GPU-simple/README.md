# Simple GPU test programs

## saxpy_openmp.F90

Taken from this [AMD HPC Training example](https://github.com/amd/HPCTrainingExamples/tree/main/Pragma_Examples/OpenMP/Fortran/1_saxpy/6_saxpy_targetdata)

```bash
amdflang -g -O3  -ffree-form -fopenmp --offload-arch=gfx90a saxpy_openmp.F90 -o saxpy
```

Run with:

```bash
srun -n1 -c1 -G1 -psmall-g -t5:00 ./saxpy
```

(assuming you have the account to use set through the environment variable `SLURM_ACCOUNT`).
The correct result is all elements should be 4.


## jacobi

Example taken from this [AMD HPC Training example](https://github.com/amd/HPCTrainingExamples/tree/main/Pragma_Examples/OpenMP/Fortran/8_jacobi/2_jacobi_targetdata).

To compile with the Makefile, use

```bash
make -R
```

for the default `amdflang` (without `-R` it will actually take `f77`),
or either set the environment variable `FC` to `amdflang`, or use

```bash
make FC=amdflang
```

where in the latter two examples other compilers may also be used (though no guarantee that the other options
set in the Makefile apply to that compiler also).

Next run with the 
```
./jacobi
```
command or from a login node with
```bash
srun -n1 -c1 -G1 -psmall-g -t5:00 ./jacobi
```
and check if 
the iterations converge. Initial convergence should be very fast, but the convergence
will slow down quickly which is natural for a Jacobi scheme.

Note: [jacobi_usm](https://github.com/amd/HPCTrainingExamples/tree/main/Pragma_Examples/OpenMP/Fortran/8_jacobi/1_jacobi_usm) 
is a slight variant for unified memory. When testing in October 2026, there seemed to be an issue:

Compiling this with the Makefile and then run `./jacobi` with 

```bash
export HSA_XNACK=1
```

doesn't show convergence so something seems wrong in that example. It looks though like we have had
this issue on LUMI since the January 2026 update when experimenting with ROCm 7+.

