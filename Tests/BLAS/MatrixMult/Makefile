#
# Settings LUMI
#
CPE_GCC_OPT= -O3
CPE_OPENBLAS_INC=-I$(EBROOTOPENBLAS)/include
CPE_OPENBLAS_LIB=-L${EBROOTOPENBLAS}/lib -lopenblas
CPE_BLIS_INC=-I$(EBROOTBLIS)/include
CPE_BLIS_LIB=-L${EBROOTBLIS}/lib -lblis-mt

f90_dgemm_libsci : f90_dgemm_libsci.exe
f90_dgemm_libsci.exe : f90_dgemm.F90
	module load cray-mpich cray-libsci && \
	ftn blas.f90 blas_interfaces.f90 dgemm.f90 $< -o $@ \
	   -std=f2003 \
	   -DBLIS \
	   $(CPE_GCC_OPT) \
	   -lm -lrt

f90_dgemm_blis : f90_dgemm_blis.exe
f90_dgemm_blis.exe : f90_dgemm.F90
	module unload cray-libsci && \
	ftn blas.f90 blas_interfaces.f90 dgemm.f90 $< -o $@ \
	   -std=f2003 \
	   -DBLIS \
	   $(CPE_GCC_OPT) \
	   $(CPE_BLIS_LIB) \
	   -lm -lrt

f90_dgemm_obl : f90_dgemm_obl.exe
f90_dgemm_obl.exe : f90_dgemm.F90
	module unload cray-libsci && \
	ftn blas.f90 blas_interfaces.f90 dgemm.f90 $< -o $@ \
	   -std=f2003 \
	   -DOpenBLAS \
	   $(CPE_GCC_OPT) \
	   $(CPE_OPENBLIS_LIB) \
	   -lm -lrt

