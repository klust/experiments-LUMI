exe : Stream.x

Stream.x : main.cpp SYCLStream.cpp Stream.h SYCLStream.h
	syclcc -O2 --hipsycl-targets="omp;hip:gfx90a" -DSYCL SYCLStream.cpp main.cpp -o $@

clean :
	/bin/rm -rf *.o *.x
	