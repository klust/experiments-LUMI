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
# module load intel/2015b (Hopper)
# module load foss/2015b (Hopper)
# module load OpenBLAS/0.2.14-GNU-4.9.3-2.25-LAPACK-3.5.0 (Turing for FOSS)  - use make OLDSYS=1 ...
# module load ictce/5.5.0 (Turiong for Intel ) - use make OLDSYS=1 ... 
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
all    : intel foss
intel  : mmdf_intel_s mmdf_intel_p mmdc_intel_s mmdc_intel_p mmb_intel_sc   mmb_intel_mc    
foss   : mmdf_gnu_obl              mmdc_gnu_obl              mmb_gnu_obl_sc mmb_gnu_obl_mc  \
         memalign_gnu
gnumkl : mmdf_gnu_mkl
mac    : mmdf_mac                  mmdc_mac                  mmb_mac_sc     mmb_mac_mc      

clean :
	-rm -f *.exe
	cd blas-interfaces; make clean

foss-int :
ifdef OLDSYS
	cd blas-interfaces; make ODLSYS=1 all-foss
else
	cd blas-interfaces; make all-foss
endif
	
MKL-int :
	cd blas-interfaces; make all-MKL
	
################################################################################
#
# Some variables
#

#
# Settings for macOS
#
MAC_GCC="gcc-8"
MAC_GFORTRAN="gfortran-8"
MAC_GCC_OPT=-march=native -O3
#MAC_GCC_OPT=-march=native -O3 -Wa,-q
# -Wa,-q passes the -q-option to the assenbler, and -q activates the CLANG 
# assenbler which does support AVX on the mac.
MAC_OPENBLAS_LIB=-L/usr/local/opt/openblas/lib -lopenblas
MAC_OPENBLAS_INC=-I/usr/local/opt/openblas/include
#MAC_OPENBLAS=-L/Users/KLust/Software/OpenBLAS/lib -lopenblas_st
#MAC_OPENBLAS=-L/Users/KLust/Software/OpenBLAS/lib -lopenblas_mt

#
# Settings cluster, foss-toolchain
#
FOSS_GCC_OPT=-march=native -O3
FOSS_OPENBLAS_INC=-I$(EBROOTOPENBLAS)/include
FOSS_OPENBLAS_LIB=-L${EBROOTOPENBLAS}/lib -lopenblas

#
# Settings cluster, intel-tolchain
#
INTEL_C_OPT =     -O3 -xHost
# For AMD:
INTEL_C_OPT =     -O3 -march=core-avx2 -mtune=core-avx2
ifeq ($(VSC_ARCH_LOCAL),rome)
  INTEL_C_OPT =   -O3 -march=core-avx2 -mtune=core-avx2
else
  INTEL_C_OPT =   -O3 -xHost
endif
INTEL_F_OPT =     $(INTEL_C_OPT) -integer-size 32 -mcmodel=medium
INTEL_C_MKL_SEQ = -mkl=sequential 
#INTEL_C_MKL_SEQ=-I${MKLROOT}/include \
#                -L${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm -ldl
INTEL_F_MKL_SEQ=-I${MKLROOT}/include -I${MKLROOT}/include/intel64/lp64 \
                -L${MKLROOT}/lib/intel64 -lmkl_blas95_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -lpthread -lm -ldl
ifdef OLDSYS
INTEL_C_MKL_PAR = -fopenmp -I${MKLROOT}/include \
                  -L${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -ldl
INTEL_F_MKL_PAR = -fopenmp -I${MKLROOT}/include -I${MKLROOT}/include/intel64/lp64 \
                  -L${MKLROOT}/lib/intel64 -lmkl_blas95_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -ldl
else
INTEL_C_MKL_PAR = -qopenmp -mkl=parallel
#INTEL_C_MKL_PAR=-qopenmp  -I${MKLROOT}/include \
#                -L${MKLROOT}/lib/intel64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -ldl
INTEL_F_MKL_PAR=-qopenmp  -I${MKLROOT}/include -I${MKLROOT}/include/intel64/lp64 \
                -L${MKLROOT}/lib/intel64 -lmkl_blas95_lp64 -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread -lm -ldl
endif


################################################################################
#
# Build instructions for matrix_mult.f90, the matrix multiplication demo (mmd)
#
# Configurations:
# * Intel compiler + MKL sequential version of the libary
# * Intel compiler + MKL multithreaded version of the library
# * GNU compiler + OpenBLAS
# * Non-working effort to use the GNU compiler with the MKL library
# * Mac: OpenBLAS + gfortran
#

mmdf_intel_s : mmdf_intel_s.exe
mmdf_intel_s.exe : matrix_mult.f90 makefile
	ifort $< -o $@ \
	    -stand f03 \
	    $(INTEL_F_OPT) \
	    $(INTEL_F_MKL_SEQ)

mmdf_intel_p : mmdf_intel_p.exe
mmdf_intel_p.exe : matrix_mult.f90 makefile
	ifort $< -o $@ \
	    -stand f03 \
	    $(INTEL_F_OPT) \
	    $(INTEL_F_MKL_PAR)

# OpenBLAS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdf_gnu_obl : mmdf_gnu_obl.exe
mmdf_gnu_obl.exe : matrix_mult.f90 foss-int makefile
	gfortran $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   $(FOSS_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(FOSS_OPENBLAS_LIB) \
	   -lm

# The mext one has the MKL libraries linked in dynamically.
mmdf_gnu_mkl : mmdf_gnu_mkl.exe
mmdf_gnu_mkl.exe : matrix_mult.f90 makefile
	gfortran $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   $(FOSS_GCC_OPT)  \
	   ${MKLROOT}/lib/intel64/libmkl_blas95_lp64.a \
	   -Wl,--no-as-needed -L${MKLROOT}/lib/intel64 -lmkl_gf_lp64 -lmkl_core -lmkl_sequential -lpthread -lm
#	   -Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_gf_lp64.a ${MKLROOT}/lib/intel64/libmkl_core.a \
#	   ${MKLROOT}/lib/intel64/libmkl_sequential.a -Wl,--end-group \
#	   -lpthread -lm
# Nog niet OK, dit was een poging met de static library maar blijkbaar worden er toch dl*-functies aangeroepen.

# OpenBLAS on the Mac using MacPorts
mmdf_mac : mmdf_mac.exe
mmdf_mac.exe : matrix_mult.f90 foss-int makefile
	$(MAC_GFORTRAN) $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   $(MAC_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(MAC_OPENBLAS_LIB) \
	   -lm


################################################################################
#
# Build instructions for matrix_mult_C.c, the matrix multiplication demo (mmd)
#
# Configurations:
# * Intel compiler + MKL sequential version of the libary
# * Intel compiler + MKL multithreaded version of the library
# * FOSS GNU compiler + OpenBLAS
# * Mac: OpenBLAS + gcc
#

mmdc_intel_s : mmdc_intel_s.exe
mmdc_intel_s.exe : matrix_mult_C.c makefile
	icc $< -o $@ \
	    -std=c11 -DALIGN -DMKL \
	    $(INTEL_C_OPT) \
	    $(INTEL_C_MKL_SEQ)

mmdc_intel_p : mmdc_intel_p.exe
mmdc_intel_p.exe : matrix_mult_C.c makefile
	icc $< -o $@ \
	    -std=c11 -DALIGN -DMKL \
	    $(INTEL_C_OPT) \
	    $(INTEL_C_MKL_PAR)

# OpenBLAS using some source files taken from Intel MKL for the Fortran 95 interface
# as I didn't want to install the standard ones from NetLib.
# Set the number of threads through OPENBLAS_NUM_THREADS !
mmdc_gnu_obl : mmdc_gnu_obl.exe
mmdc_gnu_obl.exe : matrix_mult_C.c makefile
	gcc $< -o $@ \
	   -std=c11 -DOPENBLAS -DALIGN -DINITZERO \
	   $(FOSS_GCC_OPT) \
	   $(FOSS_OPENBLAS_INC) \
	   $(FOSS_OPENBLAS_LIB) \
	   -lm

# OpenBLAS on the Mac using MacPorts
mmdc_mac : mmdc_mac.exe
mmdc_mac.exe : matrix_mult_C.c makefile
	$(MAC_GCC) $< -o $@ \
	   -std=c11 -DOPENBLAS \
	   $(MAC_GCC_OPT) \
	   $(MAC_OPENBLAS_INC) \
	   $(MAC_OPENBLAS_LIB) \
	   -lm

################################################################################
#
# Main source file: matrix_mult_openblas_sc_CL.f90
#
# OpenBLAS single dgemm call benchmark run with two command line arguments:
# * Matrix size
# * Number of threads
#

mmb_gnu_obl_sc : mmb_gnu_obl_sc.exe
mmb_gnu_obl_sc.exe : matrix_mult_openblas_sc_CL.F90 foss-int makefile
	gfortran $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(FOSS_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(FOSS_OPENBLAS_LIB) \
	   -lm -lrt

mmb_intel_sc : mmb_intel_sc.exe
mmb_intel_sc.exe : matrix_mult_openblas_sc_CL.F90 MKL-int makefile
	ifort $< -o $@ \
	    -stand f03 \
	    -D METHOD=\"IntelMKL\" \
	    $(INTEL_F_OPT) \
	   -L blas-interfaces -lMKLinterface \
	    $(INTEL_F_MKL_PAR)

mmb_mac_sc : mmb_mac_sc.exe
mmb_mac_sc.exe : matrix_mult_openblas_sc_CL.F90 foss-int makefile
	$(MAC_GFORTRAN) $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(MAC_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(MAC_OPENBLAS_LIB) \
	   -lm



################################################################################
#
# Main source file: matrix_mult_openblas_mc_CL.f90
#
# OpenBLAS multiple dgemm calls benchmark run, command line arguments:
# * Matrix size
# * [optional] one or more thread number to be used. 1 thread will always be
#   tried simply to be able to compute speedups and efficiency.
#

mmb_gnu_obl_mc : mmb_gnu_obl_mc.exe
mmb_gnu_obl_mc.exe : matrix_mult_openblas_mc_CL.F90 foss-int makefile
	gfortran $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(FOSS_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(FOSS_OPENBLAS_LIB) \
	   -lm -lrt

mmb_intel_mc : mmb_intel_mc.exe
mmb_intel_mc.exe : matrix_mult_openblas_mc_CL.F90 MKL-int makefile
	ifort $< -o $@ \
	    -stand f03 \
	    -D METHOD=\"IntelMKL\" \
	    $(INTEL_F_OPT) \
	   -L blas-interfaces -lMKLinterface \
	    $(INTEL_F_MKL_PAR)

mmb_mac_mc : mmb_mac_mc.exe
mmb_mac_mc.exe : matrix_mult_openblas_mc_CL.F90 foss-int makefile
	$(MAC_GFORTRAN) $< -o $@ \
	   -std=f2003 -I blas-interfaces \
	   -D METHOD=\"OpenBLAS\" \
	   $(MAC_GCC_OPT) \
	   -L blas-interfaces -lOpenBLASinterface \
	   $(MAC_OPENBLAS_LIB) \
	   -lm

################################################################################
#
# Build instructions for memalignment_AVX.c, checking the performance impact 
# of vector alignment
#
# Configurations:
# * FOSS GNU compiler
#

memalign_gnu : memalign_gnu.exe
memalign_gnu.exe : memalign_AVX.c
	gcc $< -o $@ -mavx -std=c99 -O2

#
