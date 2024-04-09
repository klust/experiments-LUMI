# Description

The OpenMP tools interface offers a callback called `ompt_callback_sync_region`. The callback is invoked for several different constructs.
The OpenMP 5.0 the callback could be invoked with these enumeration kinds:

```c
typedef enum ompt_sync_region_t {
    ompt_sync_region_barrier = 1,
    ompt_sync_region_barrier_implicit = 2,
    ompt_sync_region_barrier_explicit = 3,
    ompt_sync_region_barrier_implementation = 4,
    ompt_sync_region_taskwait = 5,
    ompt_sync_region_taskgroup = 6,
    ompt_sync_region_reduction = 7
} ompt_sync_region_t;
```

This was extended with the following revisions, now containing the following in 5.2:

```c
typedef enum ompt_sync_region_t {
    ompt_sync_region_barrier = 1,          // deprecated
    ompt_sync_region_barrier_implicit = 2, // deprecated
    ompt_sync_region_barrier_explicit = 3,
    ompt_sync_region_barrier_implementation = 4,
    ompt_sync_region_taskwait = 5,
    ompt_sync_region_taskgroup = 6,
    ompt_sync_region_reduction = 7,
    ompt_sync_region_barrier_implicit_workshare = 8,
    ompt_sync_region_barrier_implicit_parallel = 9,
    ompt_sync_region_barrier_teams = 10
} ompt_sync_region_t;
```

Note the two deprecations in OpenMP 5.2. `ompt_sync_region_barrier_implicit` is still widely used, for example in LLVM, ROCm & oneAPI. Performance tools can work with this and distinguish parallel regions from other implicit barriers by checking for `parallel_data == NULL`, since it is required by the specifications (see the issue `incorrect-parallel-barrier`). In the case of CPE 23.09 & 23.12 however, the runtime dispatches the callback for many different barriers, since the runtime seems to still use OpenMP 5.0 for the OMPT interface. For performance tools, this is extremely bad, as we need to distinguish the kind of barrier (implicit or explicit) at the very least. `ompt_sync_region_barrier` leaves too much to guess, which is why performance tools like Score-P will simply abort when encountering this value. 

Therefore, we would request to, at the very least, switch to the newer `ompt_sync_region_t` enum values. Having `ompt_sync_region_barrier_implicit` would be fine for us as a starting step. 

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
a.out: reproducer.c:21: void callback_sync_region(ompt_sync_region_t, ompt_scope_endpoint_t, ompt_data_t *, ompt_data_t *, const void *): Assertion `parallel_data == NULL && "Parallel data should be NULL for end of parallel, but was not"' failed.
Aborted
```

This issue does not occur when `-fno-cray -fopenmp=libomp` is used.