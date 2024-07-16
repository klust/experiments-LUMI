Lmod does not completely honour the setting LMOD_TCLSH given at build time.

-   There is a bug in Configuration.lua as it uses the `tclsh` command from the PATH
    when determining the version of `tclsh`. The line that sets the `tcl_version`
    environment variable should probably be
    
    ```lua
    tcl_version = capture("echo 'puts [info patchlevel]' | " .. cosmic:value("LMOD_TCLSH"))
    ```
    
-   When running `tcl2lua` and `RC2lua` with `LMOD_FAST_TCL_INTERP` disabled, it looks
    like the code is OK since it will not call them as shell scripts (which would again
    use the `tclsh` from the PATH) but via the interpreter specified in `LMOD_TCLSH`.
    
-   I have my doubts about `LMOD_FAST_TCL_INTERP` enabled, as the `tcl2lua.so` shared
    libraries seem to take the Tcl libraries from the MODULEPATH.
