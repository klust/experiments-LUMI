
all: hello.exe

hello.exe: hello.c
	cc -g hello.c -o hello.exe

clean:
	rm -f hello.exe

cleanall: clean
	rm -rf core *.dot my_output* slurm-*

