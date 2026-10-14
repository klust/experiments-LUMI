#! /bin/bash
#SBATCH --job-name=bench_tsp_approach_cpp
#SBATCH --output=%x_%j.log
#SBATCH --error=%x_%j.log
#SBATCH --nodes=1
#SBATCH --partition=standard
#SBATCH --time=20:00

set -x

module load CrayEnv
module purge

g++ -O3 -march=native tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

g++-12 -O3 -march=native tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

g++-13 -O3 -march=native tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

g++-14 -O3 -march=native tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

module use /appl/local/containers/test-modules

module load rocm/7.0.3

amdclang++ --version
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

module load rocm/7.2.4

amdclang++ --version
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

module load rocm/10.0.0

amdclang++ --version
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done

module purge
module unuse /appl/local/containers/test-modules

init-lumi-h
module load CrayEnv AMD-flang-experimental/24.3.0-cray-mpich-9.1.0 therock

amdclang++ --version
amdclang++ -O3 -march=znver3 tsp_approach.cpp -o tsp_approach.x
sleep 2
for i in seq 1 3 ; do time ./tsp_approach.x >/dev/null ; done
