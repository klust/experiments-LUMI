################################################################################
#
# Makefile for multiple executables with multiple main source files.
#
# Main program source files:
# * matrix_mult.f90: 6 orders of loops + F95 matrix multiply + BLAS
# * matrix_mult_opemnblas_sp_CL.f90: Single run, OpenBLAS, with two command line
#   arguments: matrix size and number of processors
# * matrix_mult_opemnblas_mp_CL.f90: Multiple runs, OpenBLAS, with two command 
#   line arguments: size followed by numbers of threads to try. 
# * matrix_mult_C.c: A C-quivalent of matrix_mult.f90 with 6 loop orders and CBLAS
#
#
# Building has been tested loading the following modules:
# module load OpenBLAS/0.2.20-cpeGNU-22.06
#
# Naming executables: TODO: Aanvullen!
# * mmd : Matrix Multiply Demo Fortran version, based on matrix_mult.f90
#   - _s : sequential BLAS library
#   - _p : parallel BLAS library
#   Number of threads for BLAS set through environment variables
# * mmdc : Matrix Multiply Demo C version, based on matrix_mult_C.c
#   - _s : sequential BLAS library
#   - _p : parallel BLAS library
#   Number of threads for BLAS set through environment variables
# + mmb : Matrix Multiply BLAS, benchmarking using MKL or OpenBLAS
#   - _sc : Single Computation, based on matrix_mult_openblas_sc_CL.f90
#   - _mc : Multiple Computations, based on matrix_mult_openblas_mc_CL.f909  
#
all      : cpe-libsci
cpe-obl  : mmdf_cpe_obl  mmdc_cpe_obl  mmb_cpe_obl_sc  mmb_cpe_obl_mc  \
           memalign_cpe 
cpe-blis : mmdf_cpe_blis mmdc_cpe_blis mmb_cpe_blis_sc mmb_cpe_blis_mc \
           memalign_cpe                        
#cpe-blis : mmdf_cpe_blis             mmdc_cpe_blis             mmb_cpe_blis_sc mmb_cpe_blis_mc  \
#           memalign_cpe

clean :
	-rm -f *.exe
	cd blas-interfaces; make clean

cpe-int :
	cd blas-interfaces; make all-cpe
	
	
################################################################################
#
# Some variables
#

#
# Settings LUMI
#
CPE_GCC_OPT= -O3
CPE_OPENBLAS_INC=-I$(EBROOTOPENBLAS)/include
CPE_OPENBLAS_LIB=-L${EBROOTOPENBLAS}/lib -lopenblas
CPE_BLIS_INC=-I$(EBROOTBLIS)/include
CPE_BLIS_LIB=-L${EBROOTBLIS}/lib -lblis-mt


################################################################################
#
# Build instructions for matrix_mult.f90, the matrix multiplication demo (mmd)
#
# Configurations:
# * CPE GNU compiler + OpenBLAS
#

# OpenBLAS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdf_cpe_obl : mmdf_cpe_obl.exe
mmdf_cpe_obl.exe : matrix_mult.f90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(CPE_OPENBLAS_LIB) \
	   -lm

# DOES NOT YET WORK:
# BLIS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdf_cpe_blis : mmdf_cpe_blis.exe
mmdf_cpe_blis.exe : matrix_mult.f90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lBLISinterface \
	   $(CPE_BLIS_LIB) \
	   -lm


################################################################################
#
# Build instructions for matrix_mult_C.c, the matrix multiplication demo (mmd)
#
# Configurations:
# * CPE GNU compiler + OpenBLAS
#

# OpenBLAS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdc_cpe_obl : mmdc_cpe_obl.exe
mmdc_cpe_obl.exe : matrix_mult_C.c makefile
	module unload cray-libsci && \
	cc $< -o $@ \
	   -std=c11 -DOPENBLAS -DALIGN -DINITZERO \
	   $(CPE_GCC_OPT) \
	   $(CPE_OPENBLAS_INC) \
	   $(CPE_OPENBLAS_LIB) \
	   -lm

# BLIS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdc_cpe_blis : mmdc_cpe_blis.exe
mmdc_cpe_blis.exe : matrix_mult_C.c makefile
	module unload cray-libsci && \
	cc $< -o $@ \
	   -DBLIS -DALIGN -DINITZERO \
	   $(CPE_GCC_OPT) \
	   $(CPE_BLIS_INC) \
	   $(CPE_BLIS_LIB) \
	   -lm


################################################################################
#
# Main source file: matrix_mult_openblas_sc_CL.f90
#
# OpenBLAS single dgemm call benchmark run with two command line arguments:
# * Matrix size
# * Number of threads
#

mmb_cpe_obl_sc : mmb_cpe_obl_sc.exe
mmb_cpe_obl_sc.exe : matrix_mult_openblas_sc_CL.F90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(CPE_OPENBLAS_LIB) \
	   -lm -lrt

mmb_cpe_blis_sc : mmb_cpe_blis_sc.exe
mmb_cpe_blis_sc.exe : matrix_mult_openblas_sc_CL.F90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"BLIS\" \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lBLISinterface \
	   $(CPE_BLIS_LIB) \
	   -lm -lrt


################################################################################
#
# Main source file: matrix_mult_openblas_mc_CL.f90
#
# OpenBLAS multiple dgemm calls benchmark run, command line arguments:
# * Matrix size
# * [optional] one or more thread number to be used. 1 thread will always be
#   tried simply to be able to compute speedups and efficiency.
#

mmb_cpe_obl_mc : mmb_cpe_obl_mc.exe
mmb_cpe_obl_mc.exe : matrix_mult_openblas_mc_CL.F90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(CPE_OPENBLAS_LIB) \
	   -lm -lrt

mmb_cpe_blis_mc : mmb_cpe_blis_mc.exe
mmb_cpe_blis_mc.exe : matrix_mult_openblas_mc_CL.F90 cpe-int makefile
	module unload cray-libsci && \
	ftn $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"BLIS\" \
	   $(CPE_GCC_OPT) \
	   -L blas-interfaces -lBLISinterface \
	   $(CPE_BLIS_LIB) \
	   -lm -lrt


################################################################################
#
# Build instructions for memalignment_AVX.c, checking the performance impact 
# of vector alignment
#
# Configurations:
# * FOSS GNU compiler
#

memalign_cpe : memalign_cpe.exe
memalign_cpe.exe : memalign_AVX.c
	cc $< -o $@ -mavx -std=c99 -O2

#
