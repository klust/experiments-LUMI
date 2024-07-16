#!/usr/bin/env python3

import sys

lower_bound = int(sys.argv[1])
upper_bound = int(sys.argv[2])

for index in range(lower_bound,upper_bound+1):
	s_i = '{:05d}'.format(index)
	with open('unhealthy'+ s_i +'.slurm','w') as myfile:
		myfile.write( '''#!/usr/bin/env bash

#SBATCH --job-name=unhealthy_sim''' + s_i  + '''
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=2:00:00
#SBATCH --hint=nomultithread
#SBATCH --no-requeue
#SBATCH --open-mode=append
#SBATCH --output=%x-%j.out
#SBATCH --account=project_462000008
#SBATCH --partition=standard
#SBATCH --reservation=nid001996-gromacs-unhealthy

project=462000008

module purge --force
module load init-lumi
export EBU_USER_PREFIX=/users/kurtlust/LUMI-user-appl

module load LUMI/21.12 partition/C
#module load GROMACS/2020.4-cpeGNU-21.12-PLUMED-2.6.4-CPU
module load GROMACS/2021.4-cpeGNU-21.12-PLUMED-2.7.4-CPU

export SCRATCH=/scratch/project_${project}/kurtlust/Olivier/CRASH
mkdir -p $SCRATCH

#Make LAUCHDIR the path to  directory where process was submitted
export LAUNCHDIR="${PWD}"
#Make the path to the folder in scratch
RUNDIR=$SCRATCH/unhealthy_sim'''+s_i+'''

export GMX_MAXBACKUP='-1'

# make/empty SCRATCH/RUN
if [[ -e $RUNDIR ]]; then
    rm -rf $RUNDIR
fi
mkdir -p $RUNDIR

cd $LAUNCHDIR

echo -e '\n\n####################\n##\n## Information\n##\n'

echo "Job nodelist: $SLURM_JOB_NODELIST"

echo -e '\n\n####################\n##\n## Initialisation\n##\n'

srun -N 1 -n 1 -c 1 gmx_mpi_d grompp -f unbound.mdp -c unbound.gro -t unbound.cpt -n unbound.ndx -p unbound.top -o $RUNDIR/unbound_sim.tpr
/usr/bin/cp -f $RUNDIR/unbound_sim.tpr $RUNDIR/unbound_sim.tpr.bak

echo -e '\n\n####################\n##\n## Model run\n##\n'

srun gmx_mpi_d mdrun -s $RUNDIR/unbound_sim.tpr -x $RUNDIR/RUN.xtc -cpo $RUNDIR/RUN.cpt -c $RUNDIR/RUN.gro -g $RUNDIR/RUN.log -e $RUNDIR/ener.edr -pin on -dlb auto -maxh 1

''' )

