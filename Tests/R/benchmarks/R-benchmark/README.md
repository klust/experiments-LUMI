# R-benchmark 2.5

Run with:

``` bash
module load LUMI/24.03 partition/L
module load R/4.4.1-cpeGNU-24.03-OpenMP
export OMP_NUM_THREADS=1
Rscript R-benchmark-25.R
```

Here again we notice core dumps when the number of OpenMP threads is 
not 1... With 
the crash again happening in `dgemm_nkm_loop_a1b1_naples._omp_fn`.
