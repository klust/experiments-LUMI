#!/bin/bash
#
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --ntasks-per-node=4
#SBATCH --time=00:05:00
#SBATCH --hint=nomultithread
#SBATCH --gpus-per-node=8

echo "Starting job $SLURM_JOB_ID at `date`"

module load LUMI/22.12 partition/G

EXE='./hello_jobstep-cce.x' ; module load cpeCray
#EXE='./hello_jobstep-gcc.x' ; module load cpeGNU
#EXE='./hello_jobstep-rocm.x' ; module load cpeAMD

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

export OMP_PROC_BIND=close
export OMP_PLACES=cores

cat - >start-$SLURM_JOBID.sh <<EOF
#!/bin/bash
if (( \$SLURM_LOCALID < 2 ));
then
    export OMP_NUM_THREADS=2
else
    export OMP_NUM_THREADS=4
fi
exec \$*
EOF
chmod u+x start-$SLURM_JOBID.sh


#
# Print some info
#

2>&1 $EXE -h

testnr=0

#
# Test: No binding whatsoever
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: No binding.\n"

cpu_bind=
gpu_bind="--gpus-per-task=2"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} -c 4 ${cpu_bind} ${gpu_bind}  $EXE"
echo -e "\nFlags: -u:"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} -c 4 ${cpu_bind} ${gpu_bind} ./start-$SLURM_JOBID.sh $EXE -u | sort
echo -e "\nFlags: -u -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} -c 4 ${cpu_bind} ${gpu_bind} ./start-$SLURM_JOBID.sh $EXE -l -u | sort
echo -e "\nFlags: No flags."
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} -c 4 ${cpu_bind} ${gpu_bind} ./start-$SLURM_JOBID.sh $EXE
echo -e "\nFlags: -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} -c 4 ${cpu_bind} ${gpu_bind} ./start-$SLURM_JOBID.sh $EXE -l

/bin/rm -rf start-$SLURM_JOBID.sh
echo -e "\n... finished job $SLURM_JOB_ID at `date`"
