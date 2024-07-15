#!/bin/bash -l
#SBATCH --job-name=SEffects   # Job name
#SBATCH --output=SEffects.o%j # Name of stdout output file
#SBATCH --error=Seffects.e%j  # Name of stderr error file
#SBATCH --partition=largemem    # Partition (queue) name
#SBATCH --nodes=1               # Total number of nodes 
#SBATCH --ntasks=4            # Total number of mpi tasks
#SBATCH --mem=0                 # Allocate all the memory on each node
#SBATCH --time=0-20:00:00       # Run time (d-hh:mm:ss)
#SBATCH --account=project_465000996  # Project for billing

# All commands must follow the #SBATCH directives

# Launch MPI code 
srun ./a.out # Use srun instead of mpirun or mpiexec

