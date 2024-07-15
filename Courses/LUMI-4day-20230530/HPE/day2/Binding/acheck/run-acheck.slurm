#!/bin/bash

# /!\ TODO /!\ 
# source the ../../lumi_c.sh script to get the correct environment automatically
# Or manually add the following options (deleting the space after the '#')
# SBATCH -A <acct>
# SBATCH -p <partition>
# SBATCH -q <qos>
# SBATCH --reservation=

# Slurm Setup :
#SBATCH --exclusive
#SBATCH -J acheck
#SBATCH -o %x-j%j.out
#SBATCH --time=4:00
#SBATCH --hint=multithread #leave multithreading enabled here. You can disable it with the srun command

# Slurm Option you can play with
#SBATCH --nodes=3
# SBATCH --ntasks-per-node=4
# SBATCH --cpus-per-task=1

# Select version to run (ideally you should build with the compiler your real application would use)
EXE="acheck-cray -v"

echo "Starting job $SLURM_JOB_ID at `date`"

# Run acheck and try the followning options :
# --hint=nomultithread
# --cpus-per-task=32
# --ntasks-per-socket=16
# --distribution=block:cyclic
# export OMP_PLACES      = threads | cores  | sockets
# export OMP_PROC_BIND   = close   | spread | master | false
# export OMP_NUM_THREADS = 1 | 64 | ${SLURM_CPUS_PER_TASK}


export OMP_PROC_BIND=false
export OMP_PLACES=threads
export OMP_NUM_THREADS=4

srun -N 1 --ntasks 8 -c 32 --distribution=block:cyclic --hint=multithread ./${EXE}

echo "... finished job $SLURM_JOB_ID at `date`"



# EXAMPLES #

# -- LEVEL 1 = DISTRIBUTE TASKS BETWEEN NODES --
# srun --nodes 3 --ntasks 10 --distribution=block  ./${EXE}
# srun --nodes 3 --ntasks 10 --distribution=cyclic ./${EXE}
# srun --nodes 3 --ntasks 11 --distribution=plane=2  ./${EXE}
#
# -- LEVEL 2 = DISTRIBUTION WITHIN A NODE --
# srun --hint=multithread   --nodes 1 -n 256 --distribution=block:block ./${EXE}
# srun --hint=nomultithread --nodes 1 -n 128 --distribution=block:cyclic ./${EXE}
#
# -- LEVEL 3 = THREADS PINNING --
# export OMP_PROC_BIND=close
# export OMP_PLACES=threads
# export OMP_NUM_THREADS=4
# srun --nodes 1 -n 8 -c 32 --distribution=block:cyclic: --hint=multithread  ./${EXE}

# -- Custom Binding with a Map --
# export OMP_NUM_THREADS=1
# export bind="0,2,16,18,32,34,48,50"
# srun --nodes 1 -n 8 --cpu-bind=map_cpu:${bind} ./${EXE}

# -- Specifying a Number of Tasks per Socket --
# export OMP_NUM_THREADS=1
# srun --nodes 1 -n 32 --ntasks-per-socket=16 --hint=nomultithread ./${EXE}

# -- Hybrid Binding with cpus-per-task --
# export OMP_NUM_THREADS=4
# export OMP_PLACES=sockets
# srun --nodes 1 -n 8 --cpus-per-task 4 --hint=nomultithread --distribution=block:block ./${EXE}
