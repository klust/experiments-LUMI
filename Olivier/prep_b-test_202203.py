#!/usr/bin/env python3

import sys

lower_bound = int(sys.argv[1])
upper_bound = int(sys.argv[2])

for index in range(lower_bound,upper_bound+1):
	s_i = str(index)
	with open('bound'+ s_i +'.slurm','w') as myfile:
		myfile.write( '''#!/usr/bin/env bash

#SBATCH --job-name=bound_sim''' + s_i  + '''
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=2:00:00
#SBATCH --hint=nomultithread
#SBATCH --no-requeue
#SBATCH --open-mode=append
#SBATCH --output=%x-%j.out
#SBATCH --account=project_462000008
#SBATCH --partition=small

project=462000008

module purge --force
module load init-lumi
export EBU_USER_PREFIX=/users/kurtlust/LUMI-user-appl

module load LUMI/21.12 partition/C
#module load GROMACS/2020.4-cpeGNU-21.12-PLUMED-2.6.4-CPU
module load GROMACS/2021.4-cpeGNU-21.12-PLUMED-2.7.4-CPU

export SCRATCH=/scratch/project_${project}/kurtlust/Olivier
mkdir -p $SCRATCH

#Make LAUCHDIR the path to  directory where process was submitted
export LAUNCHDIR="${PWD}"
#Make the path to the folder in scratch
RUNDIR=$SCRATCH/bound_sim'''+s_i+'''

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

srun -N 1 -n 1 -c 1 gmx_mpi_d grompp -f bound.mdp -c bound.gro -t bound.cpt -n bound.ndx -p bound.top -o $RUNDIR/bound_sim.tpr
/usr/bin/cp -f $RUNDIR/bound_sim.tpr $RUNDIR/bound_sim.tpr.bak

echo -e '\n\n####################\n##\n## Model run\n##\n'

srun gmx_mpi_d mdrun -s $RUNDIR/bound_sim.tpr -x $RUNDIR/RUN.xtc -cpo $RUNDIR/RUN.cpt -c $RUNDIR/RUN.gro -g $RUNDIR/RUN.log -e $RUNDIR/ener.edr -pin on -dlb auto -maxh 1
''' )


