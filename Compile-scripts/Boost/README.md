# Boost compile scripts

Reason: Compile problems with CCE 16 with the build looking for the compiler's 
libunwind in the wrong directory.

## Trying version 1.82.0 with the CCE compilers in 23.09

-   [Installation manual](https://www.boost.org/doc/libs/1_82_0/more/getting_started/unix-variants.html)

    -   Of particular interest are the [options of the `b2` command](https://www.boost.org/doc/libs/1_82_0/tools/build/doc/html/index.html#bbv2.overview.invocation)
    
Solution to the linking problem turned out to be to set

``` bash
export CCC_OVERRIDE_OPTIONS="x--target=x86_64-pc-linux"
```

before building.

