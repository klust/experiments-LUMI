# Building a container based on openSUSE 15.5 capable of running the Cray PE

Note: A lot of inspiration can be found in the work that Orian did for ticket 4445
which included an openSUSE 15.4 container built for compatibility with the Cray PE
that was on the system at that time (without the gcc-native modules).


## Packages on LUMI

The list is really too long and not something you want to reproduce in a container.

System packages:

-   libreadline: `libreadline7`, `readline-devel`
-   ncurses: `libncurses5`, `libncurses6`, `ncurses-devel`, `ncurses-utils`, `ncurses5-devel`
-   OpenSSL: `openssl`, `openssl-1_1`, `libopenssl1_0_0`, `libopenssl1_1`, `libopenssl-devel`, `libopenssl-1_1-devel`

For Lmod, we need LUA:

-   `lua53`, `lua53-luafilesystem`, `lua53-luaposix`, `liblua5_3-5`

For the GNU compilers we may need the following packages:

-   `gcc12`, `gcc12-c++`, `gcc12-fortran`, `libstdc++6-devel-gcc12`

-   `gcc13`, `gcc13-c++`, `gcc13-fortran`, `libstdc++6-devel-gcc13`

-   `libgcc_s1`, `libgcc_s1-32bit`?

For debugging:

-   `gdb`, `libgdbm4`

For the system Python:

-   Base packages: `python3`, `libpython3_6m1_0`, `python3-base`

-   There is however a fairly large number of additional packages installed on LUMI.



### Non-SUSE ones that we may not be able to include

-   Package `cray-lustre-client-ofed` for `/usr/lib64/liblustreapi.so.1.0.0` and
    soft links `liblustreapi.so` and `liblustreapi.so.1`.
