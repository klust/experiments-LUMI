
all: leak address thread

leak: leak.c
	cc -g -fsanitize=leak $< -o $@

address: address.c
	cc -g -fsanitize=address $< -o $@

thread: thread.c
	cc -g -fsanitize=thread -fopenmp $< -o $@

clean cleanall:
	rm -f *~ leak address thread
