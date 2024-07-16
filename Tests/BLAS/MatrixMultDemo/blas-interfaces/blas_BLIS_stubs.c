extern void bli_thread_set_num_threads(int num_threads) ;
extern int  bli_thread_get_num_threads(void);

void blas_set_num_threads_(int* num_threads){
	bli_thread_set_num_threads(*num_threads);
}

int blas_get_num_procs_(void) {
  return bli_thread_get_num_threads();
}

