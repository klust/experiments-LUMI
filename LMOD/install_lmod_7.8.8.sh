#! /bin/bash

#
# Latest versions
# - LUA: http://www.lua.org/download.html
# - LuaRocks: https://github.com/luarocks/luarocks/wiki/Download
# - TCL: https://www.tcl.tk/software/tcltk/
# - LMOD: https://github.com/TACC/Lmod/releases
#
lua_version=5.4.4
luarocks_version=3.9.2
tcl_version=8.6.13
lmod_version=7.8.8

parallel=16

# Set the installation root
# Note that the require function works with patterns and a hyphen in a directory name
# therefore does not work.
installroot=$HOME/appl_lmod
[ -d $installroot ]  && /bin/rm -rf $installroot
mkdir -p $installroot

# Just to be sure, add the binary directory to the PATH.
PATH=$installroot:$PATH

cd $HOME
mkdir -p work
cd work

#
# Lua installation
#
# - Lua itself
#
cd $HOME/work
# https://www.lua.org/ftp/lua-5.4.3.tar.gz
[[ -f lua-$lua_version.tar.gz ]] || wget https://www.lua.org/ftp/lua-$lua_version.tar.gz
tar -xf lua-$lua_version.tar.gz
cd $HOME/work/lua-$lua_version
# Patch src/luaconf.h to use the correct value for LUA_ROOT
# as otherwise packages will not be found
sed -i -e "s/\/usr\/local\//${HOME//\//\\\/}\/appl_lmod\//" src/luaconf.h
# Build
make -j $parallel linux install INSTALL_TOP=$installroot
#
# - LuaRocks
#
cd $HOME/work
[[ -f luarocks-$luarocks_version.tar.gz ]] || wget https://luarocks.org/releases/luarocks-$luarocks_version.tar.gz
tar -xf luarocks-$luarocks_version.tar.gz
cd $HOME/work/luarocks-$luarocks_version
./configure --with-lua=$installroot --prefix=$installroot
make -j $parallel ; make install
#
# - posix and filesystem packages
#
cd $HOME/work
$installroot/bin/luarocks --lua-dir $installroot install luaposix
$installroot/bin/luarocks --lua-dir $installroot install luafilesystem

#
# Install Tcl
#
cd $HOME/work
# https://prdownloads.sourceforge.net/tcl/tcl8.6.11-src.tar.gz
[[ -f tcl$tcl_version-src.tar.gz ]] || wget https://prdownloads.sourceforge.net/tcl/tcl$tcl_version-src.tar.gz
tar -xf tcl$tcl_version-src.tar.gz
cd $HOME/work/tcl$tcl_version/unix
./configure --prefix=$installroot
make -j $parallel ; make install
cd $installroot/bin
ln -s tclsh8.6 tclsh

#
# Install Lmod
#
cd $HOME/work
[[ -f lmod-$lmod_version.tar.gz ]] || eval "wget https://github.com/TACC/Lmod/archive/refs/tags/$lmod_version.tar.gz ; mv $lmod_version.tar.gz lmod-$lmod_version.tar.gz"
tar -xf lmod-$lmod_version.tar.gz
cd $HOME/work/Lmod-$lmod_version
# Make a correction to Makefile.in
sed -i -e 's|$(TCL_LIBS)|"$(TCL_LIBS)"|' Makefile.in
# Configure
TCL_LIBS="-Wl,-rpath $installroot/lib" \
TCL_INCLUDE=-I$installroot/include \
PATH_TO_TCLSH=$installroot/bin/tclsh8.6 \
./configure --prefix=$installroot/share \
            --with-lua_include=$installroot/include \
            --with-lua=$installroot/bin/lua \
            --with-luac=$installroot/bin/luac
make -j $parallel install
cd $installroot/share/lmod/lmod/libexec
sed -i -e 's| tclsh"| " .. cosmic:value("LMOD_TCLSH")|' Configuration.lua
# The next sed commands are not really necessary since Lmod calls these script 
# with the LMOD_TCLSH command if it uses them.
sed -i -e "s|#\!/usr/bin/env tclsh|#\!$installroot/bin/tclsh8.6|" RC2lua.tcl
sed -i -e "s|#\!/usr/bin/env tclsh|#\!$installroot/bin/tclsh8.6|" tcl2lua.tcl

#
# Clean up
#
cd $HOME/work
rm -rf lua-$lua_version
rm -rf luarocks-$luarocks_version
rm -rf tcl$tcl_version
rm -rf Lmod-$lmod_version

# Initialise:
# module purge
# source $HOME/appl_lmod/share/lmod/lmod/init/bash
