1) Load modules for GPU (openmp offload) applications

module load PrgEnv-cray
module load craype-x86-trento craype-accel-amd-gfx90a rocm

2) Generate the binary

make clean;make

3) Set CRAY_ACC_DEBUG level (1,2 or 3) and Launch job on a GPU partition
E.g.:
export CRAY_ACC_DEBUG=2
sbatch job.slurm
