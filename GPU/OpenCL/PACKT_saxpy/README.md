# Instructions

[Source of the example: <packt> "An example of OpenCL program"](https://subscription.packtpub.com/book/programming/9781849692342/1/ch01lvl1sec12/an-example-of-opencl-program

TODO: Why do we get wrong results so often?


## Compile with gcc

```
ml cpe/23.09
ml cpe/23.09
ml PrgEnv-gnu
ml rocm/5.2.3

export OPENCLROOT=/opt/rocm-5.2.3/opencl
CC -I$OPENCLROOT/include -L$OPENCLROOT/lib -lOpenCL -craype-verbose saxpy.cpp -o saxpy
```

To run:

```
srun -psmall-g -t 10:00 -n1 -c7 -G1 --pty bash
ml PrgEnv-gnu
ml rocm/5.2.3
./saxpy
```

though simply

```
srun -n1 -c7 -psmall-g -t15:00 -G1 --pty ./saxpy
```

also works.

