F90=ftn
F90FLAGS=-O2

SHELL=/usr/bin/bash

all : TestMod1.x TestMod2.x symbols

mod_hello1.o hello1.mod : mod_hello1.f90
	$(F90) $(F90FLAGS) -c $<
	
mod_hello2.o hello2.mod : mod_hello2.f90
	$(F90) $(F90FLAGS) -c $<
	
TestMod.o : TestMod.f90 hello1.mod hello2.mod
	$(F90) $(F90FLAGS) -c $<
	
TestMod1.x : mod_hello1.o mod_hello2.o TestMod.o
	$(F90) $? -o $@
	@echo -e "\nRunning TestMod1.x as a test\n"
	./TestMod1.x
	@echo

TestMod2.x : TestMod.o mod_hello1.o mod_hello2.o
	$(F90) $? -o $@
	@echo -e "\nRunning TestMod2.x as a test\n"
	./TestMod2.x
	@echo

clean :
	/bin/rm -f *.mod *.o *.x

symbols : mod_hello1.o mod_hello2.o TestMod.o
	@echo -e "\nRelevant symbols:"
	@echo -e "\nmod_hello1.o:\n"
	-@nm --print-size mod_hello1.o | grep -v "_gfortran"
	@echo -e "\nmod_hello2.o:\n"
	-@nm --print-size mod_hello2.o | grep -v "_gfortran"
	@echo -e "\nTestMod.o:\n"
	-@nm --print-size TestMod.o | grep -v "_gfortran"
	
	
	
