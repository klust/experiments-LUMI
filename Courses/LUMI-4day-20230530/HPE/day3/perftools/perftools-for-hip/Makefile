INCLUDES = -I.

CC = CC -x hip

LD = CC

CCFLAGS =  -Ihip -std=c++11 -DHIP

CCLINKFLAGS = $(CCFLAGS)

EXE = pi_hip

OBJS    = pi_hip.o

all: $(EXE)

$(EXE): $(OBJS)
	$(LD) $(CCLINKFLAGS) $< -o $@

%.o: %.cpp
	$(CC) $(CCFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(EXE) $(OBJS)

cleanall: clean
	rm -rf my_output* *.rpt myrep* *.out *.lst *+pat* *+apa* *.ap2 *.xf
