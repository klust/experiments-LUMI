
all: address thread
#all: address leak thread

leak: leak.f90
	ftn -G2 -fsanitize=leak $< -o $@

address: address.f90
	ftn -G2 -fsanitize=address $< -o $@

thread: thread.f90
	ftn -G2 -fsanitize=thread -fopenmp $< -o $@

clean cleanall:
	rm -f *~ leak address thread
