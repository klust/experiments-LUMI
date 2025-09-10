# Chapel remarks

-   The `make install` step seems completely broken
    
    -   Slow make in the `util/buildRelease/install.sh` script
    
    -   That script also tries to copy a directory that does not exist
    
    -   Afterwards, chapel cannot report the configuration for which it was built.
    
-   Needed a fix also for hwloc to find ncurses.
    
-   Lustre support does not work yet on LUMI as the compiler cannot find 
    `lustre/lustreapi.h`.
