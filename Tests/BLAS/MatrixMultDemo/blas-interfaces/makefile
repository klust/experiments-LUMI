all-cpe  : modules OBL-int BLIS-int
modules  : f95_precision.mod blas95.mod f77_blas.mod
OBL-int  : libOpenBLASinterface.a
BLIS-int : libBLISinterface.a

CPE_OPT=-O3 -Wa,-q

libOpenBLASinterface.a : dgemm.o blas_OpenBLAS_stubs.o f77_blas.mod
	ar -r $@ $?

libBLISinterface.a : dgemm.o blas_BLIS_stubs.o f77_blas.mod
	ar -r $@ $?

f95_precision.mod blas95.mod : blas.f90
	module unload cray-libsci && \
	ftn $< -c
	-rm -f blas.o
	
f77_blas.mod : blas_interfaces.f90
	module unload cray-libsci && \
	ftn $< -c
	-rm -f blas_interfaces.o

dgemm.o : dgemm.f90 f77_blas.mod
	module unload cray-libsci && \
	ftn -c $< -o $@ $(CPE_OPT)

blas_OpenBLAS_stubs.o : blas_OpenBLAS_stubs.c
	module unload cray-libsci && \
	cc -c $< -o $@ $(CPE_OPT)

blas_BLIS_stubs.o : blas_BLIS_stubs.c
	module unload cray-libsci && \
	cc -c $< -o $@ $(CPE_OPT)

clean :
	-rm -f *.mod *.o *.a

#