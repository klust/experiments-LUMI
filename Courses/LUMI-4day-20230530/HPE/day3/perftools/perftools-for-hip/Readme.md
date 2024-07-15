1) Load modules for GPU (hip) applications

module load PrgEnv-cray
module load craype-x86-trento craype-accel-amd-gfx90a rocm
module load perftools

2) Generate the binary

make cleanall; make

3) Build the instrumented binary

pat_build -u -g hip -f pi_hip

4) Launch job on a GPU partition of the culster

sbatch job.slurm

5) Generate the report

pat_report -T -o myrep pi_hip+pat+*
