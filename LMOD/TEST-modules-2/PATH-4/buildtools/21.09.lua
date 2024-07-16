help([==[

Description
===========
A bundle of often used build tools, GNU and others: autoconf, autoconf_archive,
automake, libtool, M4, make, git, sed, Bison, flex, Berkeley Yacc (byacc), CMake,
Ninja, Meson, SCons, NASM, Yasm, patchelf, pkg-config, gperf, re2c, help2man
and Doxygen.


Usage
=====
This bundle collects a number of standard tools that are often needed when
building software. Many of them are GNU tools.
+ GNU Autoconf 2.71               - https://www.gnu.org/software/autoconf/
+ GNU Autoconf Archive 2021.02.19 - https://www.gnu.org/software/autoconf/
+ GNU Automake 1.16.4             - https://www.gnu.org/software/automake/
+ GNU libtool 2.4.6               - https://www.gnu.org/software/libtool/
+ GNU M4 1.4.19                   - https://www.gnu.org/software/m4/
+ GNU make 4.3                    - https://www.gnu.org/software/make/
+ GNU sed 4.8                     - https://www.gnu.org/software/sed/
+ GNU Bison 3.8.1                 - https://www.gnu.org/software/bison
+ GNU flex 2.6.4                  - https://www.gnu.org/software/flex/
+ byacc 20210808                  - http://invisible-island.net/byacc/byacc.html
+ CMake 3.21.2                    - http://www.cmake.org/
+ Ninja 1.10.2                    - https://ninja-build.org/
+ Meson 0.59.1                    - https://mesonbuild.com/Manual.html
+ SCons 4.2.0                     - https://www.scons.org/
+ NASM 2.15.05                    - http://www.nasm.us/
+ Yasm 1.3.0                      - http://yasm.tortall.net/
+ patchelf 0.13                   - Modify the dynamic linker and RPATH of ELF executables,
                                    http://nixos.org/patchelf.html
+ re2c 2.2                        - http://re2c.org/
+ GNU gperf 3.1                   - https://www.gnu.org/software/gperf/
+ GNU help2man 1.48.5            - https://www.gnu.org/software/help2man/
+ Doxygen 1.9.2                  - http://www.doxygen.org/
These tools are all build against the system libraries and have been used to
build several of the 21.08 packages.


More information
================
 - Homepage: http://www.gnu.org
]==])

whatis([==[Description: A bundle of often used build tools, GNU and othersContains: autoconf, autoconf_archive, automake, libtool, M4, make, sed, Bison, flex, Berkeley Yacc (byacc), CMake, Ninja, Meson, SCons, NASM, Yasm, patchelf, gperf, re2c, help2man and Doxygen]==])

local root = "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08"

conflict("buildtools")

prepend_path("ACLOCAL_PATH", pathJoin(root, "share/aclocal"))
prepend_path("CMAKE_PREFIX_PATH", root)
prepend_path("CPATH", pathJoin(root, "include"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH", pathJoin(root, "share/man"))
prepend_path("PATH", pathJoin(root, "bin"))
prepend_path("XDG_DATA_DIRS", pathJoin(root, "share"))
setenv("EBROOTBUILDTOOLS", root)
setenv("EBVERSIONBUILDTOOLS", "21.08")
setenv("EBDEVELBUILDTOOLS", pathJoin(root, "easybuild/buildtools-21.08-easybuild-devel"))

setenv("EBROOTBYACC", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONBYACC", "20210808")
setenv("EBROOTFLEX", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONFLEX", "2.6.4")
setenv("EBROOTAUTOCONF", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONAUTOCONF", "2.71")
setenv("EBROOTAUTOCONFMINARCHIVE", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONAUTOCONFMINARCHIVE", "2021.02.19")
setenv("EBROOTAUTOMAKE", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONAUTOMAKE", "1.16.4")
setenv("EBROOTBISON", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONBISON", "3.8.1")
setenv("EBROOTLIBTOOL", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONLIBTOOL", "2.4.6")
setenv("EBROOTM4", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONM4", "1.4.19")
setenv("EBROOTMAKE", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONMAKE", "4.3")
setenv("EBROOTSED", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONSED", "4.8")
setenv("EBROOTCMAKE", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONCMAKE", "3.21.2")
setenv("EBROOTNINJA", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONNINJA", "1.10.2")
setenv("EBROOTMESON", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONMESON", "0.59.1")
setenv("EBROOTSCONS", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONSCONS", "4.2.0")
setenv("EBROOTNASM", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONNASM", "2.15.05")
setenv("EBROOTYASM", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONYASM", "1.3.0")
setenv("EBROOTPATCHELF", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONPATCHELF", "0.13")
setenv("EBROOTGPERF", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONGPERF", "3.1")
setenv("EBROOTRE2C", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONRE2C", "2.2")
setenv("EBROOTHELP2MAN", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONHELP2MAN", "1.48.5")
setenv("EBROOTDOXYGEN", "/appl/lumi/SW/CrayEnv/EB/buildtools/21.08")
setenv("EBVERSIONDOXYGEN", "1.9.2")
prepend_path("PYTHONPATH", pathJoin(root, "lib/python3.6/site-packages"))
-- Built with EasyBuild version 4.4.2

extensions( "TAutoconf/2.71, TAutoconf-archive/2021.02.19, TAutomake/1.16.4, " ..
            "Tlibtool/2.4.6, TM4/1.4.19, Tmake/4.3, Tsec/4.8, TBison/3.8.1, Tflex/2.6.4, " ..
            "Tbyacc/20210808, TCMake/3.22.0, TNinja/1.10.2, TMeson/0.59.1, " ..
            "TSCons/4.2.0, TNASM/2.15.05, TYasm/1.3.0, Tpatchelf/0.13, " ..
            "Tre2c/2.2, Tgperf/3.1, Thelp2man/1.48.5, TDoxygen/1.9.2"
          )

