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
#SBATCH --time=2:00:00
#SBATCH --hint=nomultithread
#SBATCH --no-requeue
#SBATCH --open-mode=append
#SBATCH --account=project_465000005
#SBATCH --partition=standard

module purge
module load LUMI/21.08 partition/L
module load GROMACS/2020.4-cpeGNU-21.08-PLUMED-2.6.4-CPU

export SCRATCH=/scratch/project_465000005/kulust/test2
mkdir -p $SCRATCH

#Make LAUCHDIR the path to  directory where process was subbed
export LAUNCHDIR="${PWD}"
#Make the path to the folder in scratch
RUNDIR=$SCRATCH/unbound_sim'''+s_i+'''

export GMX_MAXBACKUP='-1'

# make/empty SCRATCH/RUN
if [[ ! -e $RUNDIR ]]; then
        mkdir -p $RUNDIR
else
        rm -rf $RUNDIR
        mkdir -p $RUNDIR
fi

cd $LAUNCHDIR

echo -e '\n\n####################\n##\n## Initialisation\n##\n'

srun -N 1 -n 1 -c 1 gmx_mpi_d grompp -f unbound.mdp -c unbound.gro -t unbound.cpt -n unbound.ndx -p unbound.top -o $RUNDIR/unbound_sim.tpr
/usr/bin/cp -f $RUNDIR/bound_sim.tpr $RUNDIR/bound_sim.tpr.bak

echo -e '\n\n####################\n##\n## Model run\n##\n'

srun gmx_mpi_d mdrun -s $RUNDIR/unbound_sim.tpr -x $RUNDIR/RUN.xtc -cpo $RUNDIR/RUN.cpt -c $RUNDIR/RUN.gro -g $RUNDIR/RUN.log -e $RUNDIR/ener.edr -pin on -dlb auto -maxh 1''')
