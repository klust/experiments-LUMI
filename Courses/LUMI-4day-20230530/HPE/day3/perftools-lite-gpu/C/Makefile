INCLUDES = -I. 

CC = cc

#CCFLAGS = -fopenmp
CCFLAGS = -fopenmp -fsave-loopmark

CCLINKFLAGS = -fopenmp

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

	
