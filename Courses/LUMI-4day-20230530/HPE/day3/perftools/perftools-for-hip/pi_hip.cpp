// Code from Cray Programming Models Examples
//
// C++/HIP

#include <cstdio>
#include <iostream>
#include <chrono>
#include <cmath>
#include "hip/hip_runtime.h"

__global__ void count_kernel(unsigned long long int* count, int nmax) {
    unsigned long long int mycount = 0;
    int i = hipBlockIdx_x*hipBlockDim_x+hipThreadIdx_x;
    int j ;
    double x,y;
    if (i < nmax ){
       x = (i + 0.5)/nmax;
          // computing j values in kernel thread to make sure
          // there is work to balance cost of reduction
           for (j=0;j < nmax;j++){
            y = (j + 0.5)/nmax;
            if (x*x + y*y < 1.0){
                    mycount+=1;
            }
           }
    }
    atomicAdd(count,mycount);
}


int main(int argc, char** argv)
{
    unsigned long long nmax = 140000;
    const double pi=3.14159265358979323846264338327950288;
    double diff;
    unsigned long long int *out;
    // Declare timers

    hipMalloc(&out,sizeof(unsigned long long int));

    hipDeviceSynchronize();
    // Get device properties
    hipDeviceProp_t props;
    hipGetDeviceProperties(&props, 0);

    // Set up threads per dim and blocks per dim
    const int thr_per_blk = 256;
    const int blk_in_grid = ceil( float(nmax) / thr_per_blk );

    dim3 dimBlock(thr_per_blk);
    dim3 dimGrid(blk_in_grid);

    printf("PI approximation by HIP program using %d threads for each of %d blocks\n",thr_per_blk,blk_in_grid);

    hipMemsetAsync(out,0,sizeof(unsigned long long int));
    hipLaunchKernelGGL(count_kernel, dim3(dimGrid), dim3(dimBlock), 0, 0, out,nmax);
    hipDeviceSynchronize();

    unsigned long long int sum;
    hipMemcpy(&sum,out,sizeof(unsigned long long int),hipMemcpyDeviceToHost);

    double mypi;
    double nmaxd = (double) nmax;
    mypi = 4.0*(double)sum/nmaxd/nmaxd;

    printf("   PI = %20.18f\n myPI = %20.18f\n diff = %10.8f%%\n",
         pi,mypi,fabs(mypi-pi)/pi*100);

    hipFree(out);

}
