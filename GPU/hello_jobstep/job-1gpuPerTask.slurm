#!/bin/bash
#
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --ntasks-per-node=8
#SBATCH --time=00:05:00
#SBATCH --hint=nomultithread
#SBATCH --gpus-per-node=8
###SBATCH --gres=gpu:8
## Does not work for all cases:
###SBATCH --gpus-per-task=1

echo "Starting job $SLURM_JOB_ID at `date`"

module load LUMI/22.12 partition/G

EXE='./hello_jobstep-cce.x' ; module load cpeCray
#EXE='./hello_jobstep-gcc.x' ; module load cpeGNU
#EXE='./hello_jobstep-rocm.x' ; module load cpeAMD

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

[ -f select_gpu_naive.sh ] && /bin/rm select_gpu_naive.sh
cat - >select_gpu_naive.sh <<EOF
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
exec \$*
EOF
chmod u+x select_gpu_naive.sh

[ -f select_gpu_opti.sh ] && /bin/rm select_gpu_opti.sh
cat - >select_gpu_opti.sh <<EOF
#!/bin/bash
GPUSID="4 5 2 3 6 7 0 1"
GPUSID=(\${GPUSID})
if [ \${#GPUSID[@]} -gt 0 -a -n "\${SLURM_NTASKS_PER_NODE}" ]; then
   if [ \${#GPUSID[@]} -gt \$SLURM_NTASKS_PER_NODE ]; then
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((\$SLURM_LOCALID))]}
    else
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((SLURM_LOCALID / (\$SLURM_NTASKS_PER_NODE / \${#GPUSID[@]})))]}
    fi
fi
exec \$*
EOF
chmod u+x select_gpu_opti.sh

#### TEST THE TWO VERSIONS FOLLOWING ####
cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
#cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"

#### TEST THE THREE VERSION FOLLOWING ####
gpu_bind=./select_gpu_naive.sh
# gpu_bind=./select_gpu_opti.sh
# gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"

export OMP_NUM_THREADS=1
export OMP_PROC_BIND=close
export OMP_PLACES=cores

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
gpu_bind="--gpus-per-task=1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Optimal reordering CPU with map_cpu, no explicit GPU mapping
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Optimal reordering CPU with map_cpu, no explicit GPU mapping.\n"

cpu_bind="--cpu-bind=map_cpu:49,57,17,25,1,9,33,41"
gpu_bind="--gpus-per-task=1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./run_command.sh -l"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Optimal reordering CPU with mask_cpu, no explicit GPU mapping
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Optimal reordering CPU with mask_cpu, no explicit GPU mapping.\n"

cpu_bind="--cpu-bind=mask_cpu:0x00fe000000000000,0xfe00000000000000,0x00fe0000,0xfe000000,0x00fe,0xfe00,0x00fe00000000,0xfe0000000000"
gpu_bind="--gpus-per-task=1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./run_command.sh -l"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=map_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=map_gpu.\n"

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=map_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=map_gpu.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
gpu_bind="--gpu-bind=mask_gpu:0x10,0x20,0x04,0x08,0x40,0x80,0x01,0x02"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=mask_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
gpu_bind="--gpu-bind=mask_gpu:0x10,0x20,0x04,0x08,0x40,0x80,0x01,0x02"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU die x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=mask_gpu.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 7 cores CPU die x to MPI rank x, GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
gpu_bind="--gpu-bind=map_gpu:4,5,2,3,6,7,0,1"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU die x to MPI rank x, select_gpu_naive.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU die x to MPI rank x, select_gpu_naive.\n"

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
gpu_bind="./select_gpu_naive.sh"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 7 cores CPU die x to MPI rank x, select_gpu_naive.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 7 cores CPU die x to MPI rank x, select_gpu_naive.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
gpu_bind=./select_gpu_naive.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU die x to MPI rank x, select_gpu_opti.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU die x to MPI rank x, select_gpu_opti.\n"

cpu_bind="--cpu-bind=map_cpu:1,9,17,25,33,41,49,57"
gpu_bind=./select_gpu_opti.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 7 cores CPU die x to MPI rank x, select_gpu_opti
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 7 cores CPU die x to MPI rank x, select_gpu_opti.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfe,0xfe00,0xfe0000,0xfe000000,0xfe00000000,0xfe0000000000,0xfe000000000000,0xfe00000000000000"
gpu_bind=./select_gpu_opti.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


echo -e "\n... finished job $SLURM_JOB_ID at `date`"
