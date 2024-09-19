# Benchmarks from Cran

See ["Crowd sourced benchmarks" on CRAN](https://cran.r-project.org/web/packages/benchmarkme/vignettes/a_introduction.html)


```bash
module load LUMI/24.03 partition/L
module load R/4.4.1-cpeGNU-24.03-OpenMP
R
```

```
library("benchmarkme")
## Increase runs if you have a higher spec machine
res = benchmark_std(runs = 3)
res = benchmark_std(runs = 3, cores = 4)
```

Note: In the 4.4.1 version of our R module we notice a segmentation fault 
in the FFT test in the benchmark if `OMP_NUM_THREADS` is not set or set to
a value larger than 1.

The crash happens in `dgemm_nkm_loop_a1b1_naples._omp_fn`.
