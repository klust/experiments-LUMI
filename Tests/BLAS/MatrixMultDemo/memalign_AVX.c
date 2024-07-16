// gcc avx.c -mavx -std=c99 -O2
// while true; do ./a.out; done > log
// analyze via np.genfromtxt, e.g. min, 10th percentile, median

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <x86intrin.h>
#include <avxintrin.h>

#define N      20000  // Number of doubles in the vector, should be a multiple of 4 to make full sense.
#define WARMUP 1000
#define TEST   10000

int compare( const void *a, const void *b ) {

    return (* (double *) a < * (double *) b) ? -1 : ( (* (double *) a > * (double *)b) ? 1 : 0 );

}

/* Aligned AVX */
void __attribute__((noinline)) add(double * a) {

    int dump;
    int64_t times[TEST];

    for ( int j = -WARMUP; j < TEST; j++ ) {
        int64_t ts1 = __rdtscp(&dump);
        for ( int i = 0; i <  N; i += 4 ) {
            __m256d av = _mm256_load_pd(&a[i]);
            av = _mm256_add_pd(av, av);
            _mm256_store_pd(&a[i], av);
        }
        int64_t ts2 = __rdtscp(&dump);
        if ( j >= 0 ) times[j] = ts2 - ts1;
    }

    qsort( times, (size_t) TEST, sizeof(double), compare );

    printf( "Aligned AVX:              %lld (min %lld, max %lld)\n", times[TEST/2], times[0], times[TEST-1] );
}

/* Unaligned AVX */
void __attribute__((noinline)) add2(double * a, int shift) {

    int dump;
    int64_t times[TEST];

    for ( int j = -WARMUP; j < TEST; j++ ) {
        int64_t ts1 = __rdtscp(&dump);
        for ( int i = 0; i < N; i += 4 ) {
            __m256d av = _mm256_loadu_pd(&a[i]);
            av = _mm256_add_pd(av, av);
            _mm256_storeu_pd(&a[i], av);
        }
        int64_t ts2 = __rdtscp(&dump);
        if ( j >= 0 ) times[j] = ts2 - ts1;
    }

    qsort( times, (size_t) TEST, sizeof(double), compare );

    printf( "Unaligned AVX (shift %d):  %lld (min %lld, max %lld)\n", shift, times[TEST/2], times[0], times[TEST-1] );
}

/* Aligned SSE2 */
void __attribute__((noinline)) add3(double * a) {

    int dump;
    int64_t times[TEST];

    for ( int j = -WARMUP; j < TEST; j++ ) {
        int64_t ts1 = __rdtscp(&dump);
        for ( int i = 0; i < N; i += 2 ) {
            __m128d av = _mm_load_pd(&a[i]);
            av = _mm_add_pd(av, av);
            _mm_store_pd(&a[i], av);
        }
        int64_t ts2 = __rdtscp(&dump);
        if ( j >= 0 ) times[j] = ts2 - ts1;
    }

    qsort( times, (size_t) TEST, sizeof(double), compare );

    printf( "Aligned SSE2:             %lld (min %lld, max %lld)\n", times[TEST/2], times[0], times[TEST-1] );
}

/* Unaligned SSE2 */
void __attribute__((noinline)) add4(double * a, int shift) {

    int dump;
    int64_t times[TEST];

    for ( int j = -WARMUP; j < TEST; j++ ) {
        int64_t ts1 = __rdtscp(&dump);
        for ( int i = 0; i < N; i += 2 ) {
            __m128d av = _mm_loadu_pd(&a[i]);
            av = _mm_add_pd(av, av);
            _mm_storeu_pd(&a[i], av);
        }
        int64_t ts2 = __rdtscp(&dump);
        if ( j >= 0 ) times[j] = ts2 - ts1;
    }

    qsort( times, (size_t) TEST, sizeof(double), compare );

    printf( "Unaligned SSE2 (shift %d): %lld (min %lld, max %lld)\n", shift, times[TEST/2], times[0], times[TEST-1] );

}

/* Scalar */
void __attribute__((noinline)) add9(double * a) {

    int dump;
    int64_t times[TEST];

    for ( int j = -WARMUP; j < TEST; j++ ) {
        int64_t ts1 = __rdtscp(&dump);
        for ( int i = 0; i < N; i += 1 ) {
            a[i] = a[i] + a[i];
        }
        int64_t ts2 = __rdtscp(&dump);
        if ( j >= 0 ) times[j] = ts2 - ts1;
    }

    qsort( times, (size_t) TEST, sizeof(double), compare );

    printf( "Scalar code:              %lld (min %lld, max %lld)\n", times[TEST/2], times[0], times[TEST-1] );
}

int main(int argc, const char *argv[]) {

    int i;
    double * a = _mm_malloc( (N+3) * sizeof(double), 32 );

    memset(a, 0, (N+3) * sizeof(double) );

    printf( "Time measured by CPU, smaller numbers are better.\n" );

    // AVX aligned
    add( a );

    // AVX unaligned shifted two and one element
    add2( a + 0, 0 );
    add2( a + 1, 1 );
    add2( a + 2, 2 );
    add2( a + 3, 3 );

    // SSE2 (aligned)
    add3(a);

    // SSE2 (unaligned)
    add4( a + 0, 0 );
    add4( a + 1, 1 );

    // Scalar code
    add9( a );

    return 0;
}
