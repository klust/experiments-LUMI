module --force purge
export PE_LD_LIBRARY_PATH=system
module load cray-python
module load PrgEnv-cray
module load libfabric
module load craype-network-ofi
module load perftools-base
module load gcc
module load cce/20.0.0
module load craype
module load cray-dsmml
module load cray-libsci
module load cray-mpich/9.0.1
module load craype-x86-trento
module load craype-accel-amd-gfx90a
module load cray-fftw/3.3.10.10
module load rocm/6.3.4
export PE_MPICH_GTL_DIR_amd_gfx90a=${PE_MPICH_GTL_DIR_amd_gfx90a}
export PE_MPICH_GTL_LIBS_amd_gfx90a=${PE_MPICH_GTL_LIBS_amd_gfx90a}
export gcc_already_loaded=1
export CRAY_PRGENVGNU=loaded
export MPICH_GPU_SUPPORT_ENABLED=1
export CRAY_CCE_OPT_ARGS="--passes=default<O1>"
