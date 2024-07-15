#
# Affinity check program MPI/OpenMPI
# 
# Makefile for Cray PrgEnv (with Clang CCE C)

ACHECK_FILES=Makefile Makefile.classic acheck.c man/

CRAY=cray
PGI=pgi
INTEL=intel
GNU=gnu
AOCC=aocc
CLANG=clang
COMPILER:=$($(PE_ENV))

OMP_PGI=-mp
OMP_GNU=-fopenmp
OMP_CRAY=$(OMP_GNU)
OMP_AOCC=$(OMP_GNU)
OMP_INTEL=-openmp
DEBUG=
# set this for SLES11 systems
OPTS=-DNEW_VERSION -DNEW_VERSION_PGIFIX -DHAVE_GETCPU $(DEBUG)

LD_FLAGS_AOCC=-lm

CFLAGS=${OMP_$(PE_ENV)} $(OPTS)
LDFLAGS=${LD_FLAGS_$(PE_ENV)} 
ACC_FLAGS=-DACCEL_SUPPORT_ROCR=1 -D__HIP_PLATFORM_AMD__
all: acheck-${COMPILER}
acc: acheck_acc-${COMPILER}

tar: $(ACHECK_FILES)
	-tar cf acheck2.tar $(ACHECK_FILES)

acheck: acheck.c
	cc $(CFLAGS) -o $@ acheck.c

acheck_acc: acheck.c
	cc $(CFLAGS) $(ACC_FLAGS) -o $@ acheck.c

acheck-${COMPILER}: acheck.c
	cc $(CFLAGS) $(LDFLAGS) -o $@ acheck.c

acheck_acc-${COMPILER}: acheck.c
	cc $(CFLAGS) $(ACC_FLAGS) -o $@ acheck.c

clean:
	$(RM) acheck*.o core acheck acheck-cray acheck-intel acheck-gnu acheck-pgi acheck-clang acheck-aocc acheck_acc-cray acheck_acc-gnu acheck_acc-clang acheck_acc-amd acheck_acc-aocc
