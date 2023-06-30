#!/bin/bash
#
#SBATCH --exclusive
#SBATCH --partition=standard-g
#SBATCH -J hello_jobstep_gpu
##SBATCH -o %x-j%j.out
#SBATCH --time=00:05:00
#SBATCH --hint=nomultithread
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=8
###SBATCH --gres=gpu:8
## Does not work for all cases:
##SBATCH --gpus-per-task=2

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
export ROCR_VISIBLE_DEVICES="\$((\$SLURM_LOCALID*2)),\$((\$SLURM_LOCALID*2+1))"
#echo "select_gpu_naive: LocalID \$SLURM_LOCALID: ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"
exec \$*
EOF
chmod u+x select_gpu_naive.sh

[ -f select_gpu_opti.sh ] && /bin/rm select_gpu_opti.sh
cat - >select_gpu_opti.sh <<EOF
#!/bin/bash
GPUSID=( "4,5" "2,3" "6,7" "0,1" )
if [ \${#GPUSID[@]} -gt 0 -a -n "\${SLURM_NTASKS_PER_NODE}" ]; then
   if [ \${#GPUSID[@]} -gt \$SLURM_NTASKS_PER_NODE ]; then
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((\$SLURM_LOCALID))]}
    else
        export ROCR_VISIBLE_DEVICES=\${GPUSID[\$((SLURM_LOCALID / (\$SLURM_NTASKS_PER_NODE / \${#GPUSID[@]})))]}
    fi
fi
#echo "select_gpu_opt: LocalID \$SLURM_LOCALID: ROCR_VISIBLE_DEVICES=\$ROCR_VISIBLE_DEVICES"
exec \$*
EOF
chmod u+x select_gpu_opti.sh

#### TEST THE TWO VERSIONS FOLLOWING ####
# cpu_bind="--cpu-bind=map_cpu:1,17,33,49"
# cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"

#### TEST THE THREE VERSION FOLLOWING ####
# gpu_bind=./select_gpu_naive.sh
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
# Test: No binding at all.
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: No binding.\n"

cpu_bind=
gpu_bind="--gpus-per-task=2"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Optimal reordering CPU with map_cpu, no explicit GPU mapping
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Optimal eordering CPU with map_cpu, no explicit GPU mapping.\n"

cpu_bind="--cpu-bind=map_cpu:49,17,1,33"
gpu_bind="--gpus-per-task=2"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Optimal reordering CPU with mask_cpu, no explicit GPU mapping
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Optimal reordering CPU with mask_cpu, no explicit GPU mapping.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfffe000000000000,0xfffe0000,0xfffe,0xfffe00000000"
gpu_bind="--gpus-per-task=2"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: single core NUMA domain x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: single core NUMA domain x to MPI rank x, GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=map_cpu:1,17,33,49"
gpu_bind="--gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 15 cores NUMA domain x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 15 cores NUMA domain x to MPI rank x, optimal GPU binding with --gpu-bind=mask_gpu.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
gpu_bind="--gpu-bind=mask_gpu:0x30,0x0c,0xc0,0x03"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: Single core CPU NUMA domain x to MPI rank x, select_gpu_naive
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: Single core CPU NUMA domain x to MPI rank x, select_gpu_naive.\n"

cpu_bind="--cpu-bind=map_cpu:1,17,33,49"
gpu_bind="./select_gpu_naive.sh"

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 5 cores NUMA domain x to MPI rank x, select_gpu_naive
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 15 cores NUMA domain x to MPI rank x, select_gpu_naive.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
gpu_bind=./select_gpu_naive.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: single core NUMA domain x to MPI rank x, select_gpu_opti
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: single core NUMA domain x to MPI rank x, select_gpu_opti.\n"

cpu_bind="--cpu-bind=map_cpu:1,17,33,49"
gpu_bind=./select_gpu_opti.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l


#
# Test: 15 cores NUMA domain x to MPI rank x, select_gpu_opti
#
testnr=$(($testnr+1))
echo -e "\nTEST $testnr: 15 cores NUMA domain x to MPI rank x, select_gpu_opti.\n"

cpu_bind="--cpu-bind=mask_cpu:0xfffe,0xfffe0000,0xfffe00000000,0xfffe000000000000"
gpu_bind=./select_gpu_opti.sh

echo "OMP variables:"
env | grep -e ^OMP_
echo "CPU bind argument: $cpu_bind"
echo "GPU binding: $gpu_bind"
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  $EXE -l

echo -e "\n... finished job $SLURM_JOB_ID at `date`"
