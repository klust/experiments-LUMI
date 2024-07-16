# Makefile for the Tutorial examples.
# The Makefile should be compatible with EasyBuild when compiled without 
# MPI and OpenMP enabled, tough you will need to define OMPFLAG as the option
# that should be passed to the compiler to compile with OpenMP.
#
# IMPORTANT: Run with make -R (or make --no-builtin-variables) if CC etc are 
# not defined in the environment or the make command line as otherwise the 
# built-in values will be used rather than the defaults given below.
#
# Note: Preprocessor macros that can be defined:
#  * DEBUG: Prints some debug information in hybrid_hello.
#  * HAVE_NUMALIB: Define this if the system has libnuma (relevant for
#    hybrid_hello)
#

CC      ?= cc
MPICC   ?= cc
CFLAGS  ?= -O2
OMPFLAG ?= -fopenmp

.SUFFIXES:

examples : bindir \
		   ../bin/omp_hello ../bin/mpi_hello ../bin/mpi_omp_hello ../bin/hybrid_hello \
		   ../bin/eat_mem   ../bin/eat_cpu   ../bin/eat_disk
all : examples

clean : 
	-/bin/rm ../bin/*
	
bindir :
	-mkdir -p ../bin

omp_hello : ../bin/omp_hello
../bin/omp_hello : omp_hello.c
	$(CC) $(CFLAGS) $(OMPFLAG) $< -o $@

mpi_hello : ../bin/mpi_hello
../bin/mpi_hello : mpi_hello.c
	$(MPICC) $(CFLAGS) $< -o $@

mpi_omp_hello : ../bin/mpi_omp_hello
../bin/mpi_omp_hello : mpi_omp_hello.c
	$(MPICC) $(CFLAGS) $(OMPFLAG) $< -o $@

hybrid_hello : ../bin/hybrid_hello
../bin/hybrid_hello : hybrid_hello.c
	$(MPICC) $(CFLAGS) $(OMPFLAG) -DWITH_MPI -DWITH_OMP $< -o $@
#	$(MPICC) $(CFLAGS) $(OMPFLAG) -I/usr/src/ofa_kernel/cray_shasta_c/include/linux -DHAVE_NUMALIB $< -lnuma -o $@
#	$(MPICC) $(CFLAGS) $(OMPFLAG) -I/usr/src/linux-4.12.14-197.78_9.1.65/include/linux -DHAVE_NUMALIB $< -lnuma -o $@
#	$(MPICC) $(CFLAGS) $(OMPFLAG) -DHAVE_NUMALIB $< -lnuma -o $@
#	$(MPICC) $(CFLAGS) $(OMPFLAG) -DDEBUG $< -o $@

eat_mem : ../bin/eat_mem
../bin/eat_mem : eat_mem.c
	$(CC) $(CFLAGS) $< -o $@

eat_cpu : ../bin/eat_cpu
../bin/eat_cpu : eat_cpu.c
	$(CC) $(CFLAGS) $< -o $@

eat_disk : ../bin/eat_disk
../bin/eat_disk : eat_disk.c
	$(CC) $(CFLAGS) $< -o $@
