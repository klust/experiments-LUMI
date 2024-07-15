INCLUDES = -I. 

CC = cc

CCFLAGS =
#CCFLAGS = -fsave-loopmark
#CCFALGS = -fsave-loopmark -O2
#CCFLAGS = -fsave-loopmark -O2 -fcray-program-library-path=./himeno.pl
#CCFLAGS = -fopenmp

CCLINKFLAGS =
#CCLINKFLAGS = -fopenmp

EXE=himeno.exe

OBJS    = himeno.o

all: $(EXE)

$(EXE): $(OBJS)
	$(CC) $(CCLINKFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CCFLAGS) $(INCLUDES) -c $< -o $@	
	
himeno.o: param.h

clean:
	rm -rf $(EXE) $(OBJS)

cleanall: clean
	rm -rf my_output* *.rpt myrep* *.out *.lst *+pat *+apa *.ap2 *.xf expfile.* $(EXE)+orig *.pl

	
