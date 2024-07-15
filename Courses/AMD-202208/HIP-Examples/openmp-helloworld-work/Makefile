HIP_PATH?= $(wildcard /opt/rocm/hip)
ifeq (,$(HIP_PATH))
	HIP_PATH=/opt/rocm
endif

HIPCC=$(HIP_PATH)/bin/hipcc
CXX=$(HIPCC)
CXXFLAGS =-fopenmp --offload-arch=gfx90a

SOURCES = openmp_helloworld.cpp

EXECUTABLE=./openmp_helloworld.exe

.PHONY: test


all: exe test

exe : $(EXECUTABLE)

$(EXECUTABLE):
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $@


test: $(EXECUTABLE)
	$(EXECUTABLE)


clean:
	rm -f $(EXECUTABLE) *.o

