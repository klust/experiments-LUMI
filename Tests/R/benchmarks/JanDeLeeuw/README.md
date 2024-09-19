# How to run

``` bash
module load LUMI/24.03 partition/L
module load R/4.4.1-cpeGNU-24.03-OpenMP
export OMP_NUM_THREADS=1
Rscript bench.R
```

With `OMP_NUM_THREADS` set to two, we again notice a crash in
`dgemm_nkm_loop_a1b1_naples._omp_fn` in 
`/opt/cray/pe/libsci/24.03.0/GNU/12.3/x86_64/lib/libsci_gnu_mp.so.6`
(which is the library that `/opt/cray/pe/lib64/libsci_gnu_mp.so.6`
links to).

As this script requires no special packages and can run with `cray-R` also,
we tried that too. 

With `cray-R/4.3.2` I could not see from the core dump where the error
occured.

However, with `cray-R/4.2.1.2` the error again happens in
`dgemm_nkm_loop_a1b1_naples._omp_fn`, though now it reports the library
`/opt/cray/pe/libsci/21.08.1.2/GNU/9.1/x86_64/lib/libsci_gnu_82_mp.so.5`
rather than the one from 24.03 which may be wrong or right but does
not correspond with what `ldd` suggests (which would be one that then
links to `/opt/cray/pe/libsci/23.09.1.1/GNU/103/x86_64/lib/libsci_gnu_82.so.5`.
