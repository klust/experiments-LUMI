
SRC=pdgemm.cpp
EXE=$(SRC:.cpp=.x)

CXXFLAGS:=-O3 -fopenmp -std=c++17 -Wl,-ypdgemm_

ifeq ($(USE_GPU_DATA),1)
CXXFLAGS:=$(CXXFLAGS) -Wl,-ypdgemm_acc_ -DUSE_GPU_DATA
endif

$(EXE): $(SRC)
	CC $(CXXFLAGS) $< -o $@

clean:
	rm -rf *~ $(EXE)

cleanall: clean
	rm -rf *.out core
