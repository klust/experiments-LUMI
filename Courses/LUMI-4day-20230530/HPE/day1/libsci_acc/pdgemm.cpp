#include "mpi.h"
#include <cassert>
#include <iostream>
#include <numeric>
#include <chrono>

#ifdef USE_GPU_DATA
#define LIBSCI_FCN(name) name##_acc_
#else
#define LIBSCI_FCN(name) name##_
#endif

extern "C" {
  /* Cblacs declarations */
  void Cblacs_pinfo(int*, int*);
  void Cblacs_get(int, int, int*);
  void Cblacs_gridinit(int*, const char*, int, int);
  void Cblacs_barrier(int, const char*);

  void descinit_(int *desc, int const& m, int const& n, int const& mb,
		 int const& nb, int const& irsrc, int const& icsrc, int const& ictxt,
		 int const& lld, int *info);
  
  void LIBSCI_FCN(pdgemm)(char const *transa, char const *transb,
	       int const& M, int const& N, int const& K,
	       double const& ALPHA,
	       double * A, int const& IA, int const& JA, int * DESCA,
	       double * B, int const& IB, int const& JB, int * DESCB,
	       double const& BETA,
	       double * C, int const& IC, int const& JC, int * DESCC);
}


int main(int argc, char ** argv)
{
  // MPI init
  MPI_Init(&argc, &argv);
  int mpi_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);

  // BLACS init
  int BLACS_CONTEXT, proc_nrows, proc_ncols;
  int proc_id, num_procs;
  proc_nrows = 2; proc_ncols = 2;
  Cblacs_pinfo(&proc_id, &num_procs);
  assert(num_procs>=proc_nrows*proc_ncols);
  Cblacs_get(-1, 0, &BLACS_CONTEXT);
  Cblacs_gridinit(&BLACS_CONTEXT, "Row", proc_nrows, proc_ncols);
  if (0==proc_id) {
    std::cout << "num_procs = " << num_procs << std::endl;
  }

  // matrix data allocation
  int N = (argc>0 && atoi(argv[1])>0) ? atoi(argv[1]) : 10000;
  if (0==proc_id) {
    std::cout << "matrix size = " << N << std::endl;
  }  
  int nb = N/2, ns=nb*nb; // mat size, blk size.
  double* a = (double*)malloc(sizeof(double)*ns);
  double* b = (double*)malloc(sizeof(double)*ns);
  double* c = (double*)malloc(sizeof(double)*ns);

  // matrix data initialization
  for (int i = 0; i < ns; ++i) {
    a[i] = 1e-8;
    b[i] = 2e-6;
    c[i] = 0;
  }

  // create array descriptor
  int desca[9], descb[9], descc[9], info;
  descinit_(desca, N, N, nb, nb, 0, 0, BLACS_CONTEXT, nb, &info);
  descinit_(descb, N, N, nb, nb, 0, 0, BLACS_CONTEXT, nb, &info);
  descinit_(descc, N, N, nb, nb, 0, 0, BLACS_CONTEXT, nb, &info);

  Cblacs_barrier(BLACS_CONTEXT, "All");
  int ia = 1, ja = 1, ib = 1, jb = 1, ic = 1, jc = 1;
  double alpha = 1, beta = 1;

  int niter = (argc>1 && atoi(argv[2])>0) ? atoi(argv[2]) : 10;
  if (0==proc_id) {
    std::cout << "# multiplications = " << niter << std::endl;
  }
  auto start = std::chrono::steady_clock::now();

#ifdef USE_GPU_DATA
#pragma omp target data map(to: a[0:ns], b[0:ns]) map(tofrom: c[0:ns])
  {
#pragma omp target data use_device_ptr(a, b, c)
    {
#endif
      // Run Multiplication
      for (int i=0; i<niter; ++i) {
	LIBSCI_FCN(pdgemm)("N", "N", N, N, N, alpha, a, ia, ja, desca, b, ib, jb, descb,
		beta, c, ic, jc, descc);
      }
#ifdef USE_GPU_DATA
    }
  }
#endif
  
  auto end = std::chrono::steady_clock::now();
  std::chrono::duration<double> elapsed_seconds = end-start;
  
  double sum = std::reduce(c, c+(nb*nb));
  double checksum = 0;
  MPI_Reduce(&sum, &checksum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
  if (0==proc_id) {
    std::cout << "Checksum = " << checksum << std::endl;
    std::cout << "elapsed time: " << elapsed_seconds.count() << "s\n";
  }
  
  MPI_Finalize();
}
