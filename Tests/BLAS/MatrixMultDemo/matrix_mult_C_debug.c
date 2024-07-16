/* C-implementation of matrix-matrix multiplication.
** Based on C++-code used by Intel in demo sessions.
*/

#define ALIGNMENT 64

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
#ifdef MKL
#include <mkl.h>
#endif
#ifdef OPENBLAS
#include <cblas.h>
#endif

double flops( int size, double time ) {

    return ( 2. * (double) size * (double) size * (double) size) / time;

}

double readTime() {

    struct timeval tp;

    gettimeofday( &tp, NULL );
    return (double) tp.tv_sec + (double) tp.tv_usec * 1.e-6;

}

int main(int argc, char** argv) {

    double *A;
    double *B;
    double *C;
    int size;
    double start, end;
    double walltime;
    double dummy = 0.;

    /* Read the size of the matrix (first argument) */

    if ( argc != 2 ) {
        printf( "The program requires one command line arguments: the matrix size.\n" );
        return -1;
    }

    size      = atoi( argv[1] );

    /* Allocate memory. We do an aligned allocation for optimal BLAS-performance. */
    /* Note that we overallocate to add some NANs to detect memory accesses past
     * the limits of the arrayy. */
#if defined( ALIGN )
    A = (double *) aligned_alloc( ALIGNMENT, size*(size+1)*sizeof(double) );
    B = (double *) aligned_alloc( ALIGNMENT, size*(size+1)*sizeof(double) );
    C = (double *) aligned_alloc( ALIGNMENT, size*(size+1)*sizeof(double) );
#else
    A = (double *) malloc( size*(size+1)*sizeof(double) );
    B = (double *) malloc( size*(size+1)*sizeof(double) );
    C = (double *) malloc( size*(size+1)*sizeof(double) );
#endif

    /* Initialize the matrices A and B. */
    for ( int i = 0; i < size; i++ )
        for ( int j = 0; j < size; j++ ) {
            A[i*size+j] = sin( (double) (i+j) / (double) size * 3.1415 );
            B[i*size+j] = cos( (double) (i+j) / (double) size * 3.1415 );
        }
    /* Initialise the border. */
    for ( int j = 0; j < size; j++ ) {
        A[size*size+j] = NAN;
        B[size*size+j] = NAN;
        C[size*size+j] = NAN;
    }

    /* Do the actual computations.
     * After each algorithm, partial results are printed.
     */
    printf( "Matrix size: %dx%d, %.3f MB per array.\n", size, size, (double) (8*size*size) / (1024.0*1024.0) );
    printf( "Variant       time (s)    Gflops  control sum\n" );
    printf( "---------------------------------------------\n" );

    /* ijk-loop */
    start = readTime();
    for ( int i = 0; i < size; i++ )
        for ( int j = 0; j < size; j++ ) {
            C[i*size+j] = 0.;
            for ( int k = 0; k < size; k++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
        }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "ijk-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* jik-loop */
    start = readTime();
    for ( int j = 0; j < size; j++ )
        for ( int i = 0; i < size; i++ ) {
            C[i*size+j] = 0.;
            for ( int k = 0; k < size; k++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
        }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "jik-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* ikj-loop */
    start = readTime();
    for ( int i = 0; i < size; i++ ) {
        for ( int j = 0; j < size; j++ ) C[i*size+j] = 0.;
        for ( int k = 0; k < size; k++ )
            for ( int j = 0; j < size; j++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
    }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "ikj-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* kij-loop */
    start = readTime();
    for ( int i = 0; i < size; i++ )
        for ( int j = 0; j < size;j++ ) C[i*size+j] = 0.;
    for ( int k = 0; k < size; k++ ) {
        for ( int i = 0; i < size; i++ )
            for ( int j = 0; j < size; j++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
    }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "kij-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* kji-loop */
    start = readTime();
    for ( int i = 0; i < size; i++ )
        for ( int j = 0; j < size; j++ ) C[i*size+j] = 0.;
    for ( int k = 0; k < size; k++ ) {
        for ( int j = 0; j < size; j++ )
            for ( int i = 0; i < size; i++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
    }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "kji-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* jki-loop */
    start = readTime();
    for ( int j = 0; j < size; j++ ) {
        for ( int i = 0; i < size; i++ ) C[i*size+j] = 0.;
        for ( int k = 0; k < size; k++ )
            for ( int i = 0; i < size; i++ )
                C[i*size+j] += A[i*size+k] * B[k*size+j];
    }
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "jki-variant:  %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );

    /* CBLAS */
#if defined(MKL) || defined(OPENBLAS)
#ifdef INITZERO
    for ( int i = 0; i < size; i++ )
        for ( int j = 0; j < size; j++ )
            C[i*size+j] = 0.;
#endif
    start = readTime();
    double alpha = 1.0;
    double beta  = 0.0;
    /* void cblas_dgemm (const CBLAS_LAYOUT layout, const CBLAS_TRANSPOSE TransA, const CBLAS_TRANSPOSE TransB,
     *                   const int M, const int N, const int K,
     *                   const double alpha, const double *A, const int lda,
     *                   const double *B, const int ldb,
     *                   const double beta, double *C, const int ldc) */
    cblas_dgemm( CblasRowMajor, CblasNoTrans, CblasNoTrans, size, size, size, alpha, A, size,
                 B, size, beta, C, size );
    end = readTime();
    walltime = end - start;
    dummy = 0.; for ( int i = 0; i < size; i++ ) for ( int j = 0; j < size; j++ ) dummy += C[i*size+j];
    printf( "BLAS:         %8.2f  %8.2f  %11.3e\n", walltime, flops( size, walltime ) / 1.e9, dummy );
#endif

    return 0;

}
