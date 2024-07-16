extern  void openblas_set_num_threads(int num_threads) ;

#ifdef OLD_LIB

/* Old versions of OpenBLAS don't have the openblas_get_num_procs function. */

int blas_get_num_procs_(void) {
  return -1;
}

#else

extern int openblas_get_num_procs(void);

int blas_get_num_procs_(void) {
  return openblas_get_num_procs();
}

#endif

void blas_set_num_threads_(int* num_threads){
	openblas_set_num_threads(*num_threads);
}
