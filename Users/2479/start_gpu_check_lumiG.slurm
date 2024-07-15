#!/bin/bash
#SBATCH --job-name=gpu_check-test
#SBATCH --partition=standard-g
#SBATCH --nodes=1
#SBATCH --gpus-per-node=8
#SBATCH --ntasks-per-node=16
#SBATCH --hint=nomultithread
#SBATCH --time=2:00
#SBATCH --output %x-%j.txt

#init-lumi-h
module load LUMI/22.12 partition/G
module load lumi-CPEtools/1.1-cpeGNU-22.12

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"

env | egrep ^SLURM

module list

export MPICH_GPU_SUPPORT_ENABLED=0
export DEVICE_STACK_MEM_SIZE=2.0
export HSA_XNACK=1

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export OMP_NUM_THREADS=3

echo -e "\nOMP variables:"
env | egrep ^OMP

#
# select_gpu script from the user
# 
cat - >select_gpu_${SLURM_JOBID}.sh <<EOF
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
#echo "Binding process \${SLURM_LOCALID} to \${ROCR_VISIBLE_DEVICES}"
exec \$*
EOF
chmod u+x select_gpu_${SLURM_JOBID}.sh
echo -e "\nselect_gpu.sh script:"
cat select_gpu_${SLURM_JOBID}.sh

#
# select_gpu with linear assignement
# 
cat - >select_gpu_lin_${SLURM_JOBID}.sh <<EOF
#!/bin/bash
if [ -n "\${SLURM_NTASKS_PER_NODE}" ]; then
   if [ \$SLURM_NTASKS_PER_NODE -le 8 ]; then
        export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID
    else
        export ROCR_VISIBLE_DEVICES=\$((SLURM_LOCALID / (\$SLURM_NTASKS_PER_NODE / 8) ))
    fi
fi
#echo "Binding process \${SLURM_LOCALID} to \${ROCR_VISIBLE_DEVICES}"
exec \$*
EOF
chmod u+x select_gpu_lin_${SLURM_JOBID}.sh
echo -e "\nselect_gpu_lin.sh script:"
cat select_gpu_${SLURM_JOBID}.sh

#
# CPU bindings from the user
#
CPU_BIND="--cpu-bind=mask_cpu:E000000000000,E0000000000000,E00000000000000,E000000000000000"
CPU_BIND="${CPU_BIND},E0000,E00000,E000000,E0000000"
CPU_BIND="${CPU_BIND},E,E0,E00,E000"
CPU_BIND="${CPU_BIND},E00000000,E000000000,E0000000000,E00000000000"

#
# Alternative CPU binding.
#
CPU_BIND_ALT="--cpu-bind=mask_cpu"
CPU_BIND_ALT="${CPU_BIND_ALT}:000000000000000E,00000000000000E0,0000000000000E00,000000000000E000"
CPU_BIND_ALT="${CPU_BIND_ALT},00000000000E0000,0000000000E00000,000000000E000000,00000000E0000000"
CPU_BIND_ALT="${CPU_BIND_ALT},0000000E00000000,000000E000000000,00000E0000000000,0000E00000000000"
CPU_BIND_ALT="${CPU_BIND_ALT},000E000000000000,00E0000000000000,0E00000000000000,E000000000000000"

#
# Option 1: No CPU binding done, GPU binding via select_gpu
# This seems to be what the user is doing.
#
echo -e "\nOption 1: Seems to be what the user job script is doing, CPU_BIND not used and select_gpu for the GPUs."
echo -e "This does not work as expected as the three threads all run on the same core and moreover"
echo -e "the cores are assigned consecutively.\n"
srun ./select_gpu_${SLURM_JOBID}.sh gpu_check -l

#
# Option 2: CPU binding and GPU binding from the user.
#
echo -e "\nOption 2: CPU binding from user job script, GPU binding with select_gpu."
echo -e "As this reorders both the CPUs and the GPUs one should not expect a good mapping."
echo -e "One should either assign the CPUs linearly with the necessary gaps and reorder the GPUs or"
echo -e "reorder the CPUs and assign the GPUs linearly (using each GPU twice before moving to the next"
echo -e "one in this example).\n"
srun ${CPU_BIND} ./select_gpu_${SLURM_JOBID}.sh gpu_check -l

#
# Option 3: Alternative CPU binding and select_gpu.sh.
#
echo -e "\nOption 3: CPU binding with CPU_BIND_ALT and GPU binding with select_gpu_alt.sh"
echo -e "The only function of the CPU binding is now to leave one core unused after every 3 CPUs."
echo -e "The GPU binding with reordering then takes care of linking the correct GPU die to the task.\n"
srun ${CPU_BIND_ALT} ./select_gpu_${SLURM_JOBID}.sh gpu_check -l

#
# Option 4: Binding from the user with reordering but select_Gpu_lin.sh
#
echo -e "\nOption 4: CPU binding with user CPU_BIND, linear GPU binding with select_gpu_lin\n"
srun ${CPU_BIND} ./select_gpu_lin_${SLURM_JOBID}.sh gpu_check -l

#
# Clean-up
#
/bin/rm -f select_gpu_${SLURM_JOBID}.sh
/bin/rm -f select_gpu_lin_${SLURM_JOBID}.sh

