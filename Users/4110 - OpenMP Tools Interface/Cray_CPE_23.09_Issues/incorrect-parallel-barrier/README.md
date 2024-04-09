# Description

The OpenMP tools interface offers a callback called `ompt_callback_sync_region`. The callback is invoked for several different constructs. Here, we focus on the invokation for parallel regions.
The OpenMP 5.0 specification mentions the following restiction for a parallel region:

> The binding of the *parallel_data* argument is the current parallel region. For the *barrier-end* event at the end of a parallel region this argument is **NULL**

This is still the case in OpenMP 5.2 and TR12:

> The binding of the *parallel_data* argument is the current parallel region. For the *implicit-barrier-end* event at the end of a parallel region this argument is **NULL**. For the *implicit-barrier-wait-begin* and *implicit-barrier-wait-end* event at the end of a parallel region, whether this argument is **NULL** or points to the parallel data of the current parallel region is implementation defined.

Both CPE 23.09 and CPE 23.12 do not adhere to this specification. For both versions, the callback is invoked with `parallel_data != NULL`. This prevents distinction from other barriers and causes issues in performance tools. 

# Reproducer

You can compile and run the code attached to reproduce the issue. The program will exit with an assertion error because the `sync_region` callback was incorrectly invoked. 

```console
$ cc --version
Cray clang version 16.0.1  (6d4824324d375100ba18ca639dfc956fe6546d06)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /opt/cray/pe/cce/16.0.1/cce-clang/x86_64/share/../bin
$ cc -fopenmp reproducer.c
$ OMP_NUM_THREADS=1 ./a.out 
foo()
a.out: reproducer.c:17: void callback_sync_region(ompt_sync_region_t, ompt_scope_endpoint_t, ompt_data_t *, ompt_data_t *, const void *): Assertion `kind != ompt_sync_region_barrier && "sync_region callback used ompt_sync_region_barrier"' failed.
Aborted
```

This issue does not occur when `-fno-cray -fopenmp=libomp` is used.