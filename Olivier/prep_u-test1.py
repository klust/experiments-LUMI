#!/usr/bin/env python3

import sys


lower_bound = int(sys.argv[1])
upper_bound = int(sys.argv[2])

for index in range(lower_bound,upper_bound+1):
	s_i = str(index)
	with open('unbound'+ s_i +'.slurm','w') as myfile:
		myfile.write('''#!/usr/bin/env bash

#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00
#SBATCH --hint=nomultithread
#SBATCH --account=project_465000005
#SBATCH --partition=standard

export SCRATCH=/scratch/project_465000005/kulust/test1
mkdir -p $SCRATCH

module load lumi/21.08 partition/L
module load GROMACS/2020.4-cpeGNU-21.08-PLUMED-2.6.4-CPU


#Make LAUCHDIR the path to  directory where process was subbed
export LAUNCHDIR="${PWD}"
#Make the path to the folder in scratch
RUNDIR=$SCRATCH/unbound_sim'''+s_i+'''


# make/empty SCRATCH/RUN
if [[ ! -e $RUNDIR ]]; then
        mkdir -p $RUNDIR
else
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
fi


cd $LAUNCHDIR


srun -n 1 gmx_mpi_d grompp -f unbound.mdp -c unbound.gro -t unbound.cpt -n unbound.ndx -p unbound.top -o $RUNDIR/unbound_sim.tpr


srun gmx_mpi_d mdrun -s $RUNDIR/unbound_sim.tpr -x $RUNDIR/RUN.xtc -cpo $RUNDIR/RUN.cpt -c $RUNDIR/RUN.gro -g $RUNDIR/RUN.log -pin on -dlb auto -maxh 47''')
