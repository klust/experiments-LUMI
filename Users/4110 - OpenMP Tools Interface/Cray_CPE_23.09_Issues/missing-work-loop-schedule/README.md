# Description

The OpenMP tools interface offers a callback called `ompt_callback_work`. Here, the parameter `work_type` can be used to determine the type of work a thread is doing. There are several different values for loops, which can be used to get the schedule for the OpenMP loops.

Right now, Cray CPE 23.09 & 23.12 do not report any schedule type. Instead, the value `ompt_work_loop` is used for every schedule type. 

# Reproducer

You can compile and run the code attached to reproduce the issue. The program will exit with an assertion error because no schedule type was reported. 

```console
$ cc --version
Cray clang version 16.0.1  (6d4824324d375100ba18ca639dfc956fe6546d06)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /opt/cray/pe/cce/16.0.1/cce-clang/x86_64/share/../bin
$ cc -fopenmp reproducer.c
$ OMP_NUM_THREADS=1 ./a.out
a.out: reproducer.c:57: void ompt_finalize(ompt_data_t *): Assertion `has_schedule && "Tool got initialized and finalized but no loop schedule was provided."' failed.
Aborted (core dumped)
```