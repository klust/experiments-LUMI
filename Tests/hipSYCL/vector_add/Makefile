exe : vector_add.x

vector_add.x : vector_add.cpp
	syclcc --hipsycl-targets="hip:gfx90a" -O2 $< -o $@

clean :
	/bin/rm -f *.o *.x
