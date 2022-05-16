module --force purge

unset LMOD_SYSTEM_DEFAULT_MODULES
unset LMOD_RC
unset LMOD_ADMIN_FILE
unset LMOD_PACKAGE_PATH

module unuse $MODULEPATH
module use $PWD/modules/init-modules
module use $PWD/modules/system

echo 'MODULEPATH ='
echo $MODULEPATH | tr ":" "\n" | nl - ;

module list
