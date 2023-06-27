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

EXE='hello_jobstep-cce.x' ; module load cpeCray

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
cat - <<EOF

Proper mapping:

CPU die 0 providing HWT 000-007 and 064-071 to GPU die 4 with Bus_ID d1
CPU die 1 providing HWT 008-015 and 072-079 to GPU die 5 with Bus_ID d6
CPU die 2 providing HWT 016-023 and 080-087 to GPU die 2 with Bus_ID c9
CPU die 3 providing HWT 024-031 and 088-095 to GPU die 3 with Bus_ID ce
CPU die 4 providing HWT 032-039 and 096-103 to GPU die 6 with Bus_ID d9
CPU die 5 providing HWT 040-047 and 104-111 to GPU die 7 with Bus_ID de
CPU die 6 providing HWT 048-055 and 112-119 to GPU die 0 with Bus_ID c1
CPU die 7 providing HWT 056-063 and 120-127 to GPU die 1 with Bus_ID c6

GPU die 0 with Bus_ID c1 to CPU die 6 providing HWT 048-055 and 112-119
GPU die 1 with Bus_ID c6 to CPU die 7 providing HWT 056-063 and 120-127
GPU die 2 with Bus_ID c9 to CPU die 2 providing HWT 016-023 and 080-087
GPU die 3 with Bus_ID ce to CPU die 3 providing HWT 024-031 and 088-095
GPU die 4 with Bus_ID d1 to CPU die 0 providing HWT 000-007 and 064-071
GPU die 5 with Bus_ID d6 to CPU die 1 providing HWT 008-015 and 072-079
GPU die 6 with Bus_ID d9 to CPU die 4 providing HWT 032-039 and 096-103
GPU die 7 with Bus_ID de to CPU die 5 providing HWT 040-047 and 104-111

RT_GPU_ID: HIP runtime GPU ID, a local ID, a series starting from 0 for each process.
GPU_ID:    Global GPU ID, but can become local to the process depending on how 
           Slurm is used.
Bus_ID:    PCIe bus ID and the only truly reliable way to identify a physical GPU.

EOF

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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 40s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort


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
echo -e "\nsrun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort"
timeout -k 10s 20s srun -N ${SLURM_NNODES} -n ${SLURM_NTASKS} ${cpu_bind} ${gpu_bind}  ./$EXE | sort

echo -e "\n... finished job $SLURM_JOB_ID at `date`"
