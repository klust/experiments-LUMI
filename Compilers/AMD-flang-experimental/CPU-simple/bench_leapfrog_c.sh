#! /bin/bash
#SBATCH --job-name=bench_leapfrog_c
#SBATCH --output=%x_%j.log
#SBATCH --error=%x_%j.log
#SBATCH --nodes=1
#SBATCH --partition=standard
#SBATCH --time=20:00

set -x

module load CrayEnv
module purge

gcc -O3 -march=native leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

gcc-12 -O3 -march=native leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

gcc-13 -O3 -march=native leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

gcc-14 -O3 -march=native leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

module use /appl/local/containers/test-modules

module load rocm/7.0.3

amdclang --version
amdclang -O3 -march=znver3 leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

module load rocm/7.2.4

amdclang --version
amdclang -O3 -march=znver3 leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

module load rocm/10.0.0

amdclang --version
amdclang -O3 -march=znver3 leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done

module purge
module unuse /appl/local/containers/test-modules

init-lumi-h
module load CrayEnv AMD-flang-experimental/24.3.0-cray-mpich-9.1.0 therock

amdclang --version
amdclang -O3 -march=znver3 leapfrog.c -o leapfrog.x
sleep 2
for i in seq 1 3 ; do time ./leapfrog.x ; done
