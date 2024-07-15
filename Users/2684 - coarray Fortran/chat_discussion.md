Orian Louant @orian.louant@uliege.be
09:18
It looks like, on 2 PE, it fails in the pgas implementation. Not sure we can help without putting HPE in the loop

```
a{1}: Program received signal SIGSEGV.
a{1}: In libpgas::cpu_amo at :0
dbg all> bt
a{0}: *** The application is running
a{1}: #8  main_
a{1}: #7  __pgas_sync_all
a{1}: #6  libpgas::Interface_Impl<false>::__pgas_sync_all
a{1}: #5  libpgas::Generic_Team<false, 8, 4>::barrier
a{1}: #4  libpgas::SMP_Team<false, 8, 4>::barrier_wait
a{1}: #3  libpgas::Generic_Team<false, 8, 4>::wait_parent
a{1}: #2  libpgas::SHMEM_Message<false>::poll
a{1}: #1  libpgas::SHMEM_Message<false>::process_msg
a{1}: #0  libpgas::cpu_amo
```

On 1 PE, no useful message is printed and I have no stack trace to work with

Orian Louant @orian.louant@uliege.be
09:39
Ok, setting XT_SYMMETRIC_HEAP_SIZE to a larger value than the default seems to do the trick

```
 $ export XT_SYMMETRIC_HEAP_SIZE=256M 
 $ export SHMEM_MEMINFO_DISPLAY=1
 $ srun -n 2 -pdebug -u ./bug1M
srun: job 4302835 queued and waiting for resources
srun: job 4302835 has been allocated resources

 LIBSMA INFO:
  min PEs per node           =  0           on nid 0
  max PEs per node           = 2528           on nid 2528
  min nominal node size      =     0M =  0G on nid 2528
  max nominal node size      =     0M =  0G on nid 0
  min boot_freemem           =     0M =  0G on nid 2528
  max boot_freemem           =     0M =  0G on nid 0
  min initial_freemem        =     0M =  0G on nid 2528
  max initial_freemem        =     0M =  0G on nid 0
  min current_freemem        =     0M =  0G on nid 2528
  max current_freemem        =     0M =  0G on nid 0
  huge page size             =  2048K
  huge pages reserved =    0 =     0M =  0G
  min huge_page_freemem      =     0M =  0G on nid 2528
  max huge_page_freemem      =     0M =  0G on nid 0
  min huge pages alloc=    0 =     0M =  0G on nid 2528
  max huge pages alloc=    0 =     0M =  0G on nid 2528
  -----------------------------------------------------------
  memory                                   size (decimal MiB)
  region   virtual address range           per proc  per node
  -------  ------------------------------  --------  --------
  text     0x000000401000..0x0000004027dd        0M        0M
  data     0x000000405000..0x0000004077e0        0M        0M
  bss      0x0000004077e0..0x0000004078f0        0M        0M
  privheap 0x0000004078f0..0x000000601000        1M        3M
  symheap  0x030000000000..0x030010000000      256M      512M
  alltoall 0x0300115f5dc0..0x0300119f5dc0        4M        8M
  team     0x0300115f5d40..0x030011794d60        1M        3M
  stack    0x7ffdf2b3c000..0x7ffdf2b5b000        0M        0M
  --total                                      262M      524M
  OS                                                       0M
  --total                                                524M = 0G

Parallel Research Kernels
Fortran coarray STREAM triad: A = B + scalar * C
Number of images     =            2
Number of iterations =           10
Vector length        =     10000000
Offset               =            0
Solution validate
Rate (MB/s):        412.830 Avg time (s)   0.155028E+01
```

but... not with optimization enabled... damn...

Thomas Röblitz @thomas.roblitz@uib.no
10:00
Thanks Orian Louant Shall I ask HPE to have a look then?