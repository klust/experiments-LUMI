1) Load modules for GPU (openmp offload) applications

module load PrgEnv-cray
module load craype-x86-trento craype-accel-amd-gfx90a rocm
module load perftools

2) Generate the binary

make cleanall; make

3) Build the instrumented binary

pat_build -u -g mpi,omp -f ./himeno.exe

4) Launch job on a GPU partition of the culster

sbatch job.slurm

5) Generate the report

pat_report -T -o myrep himeno.exe+pat+*
