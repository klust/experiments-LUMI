#!/bin/bash
#SBATCH --job-name=map-ring-red1
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --time=5:00

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeCray-23.09

#
# Define the order of the GPUs
#
GPU_ORDER=( 0 1 5 4 6 7 3 2 )

#
# gpu_select script, requires GPU_ORDER to be exported from the mother shell
#
# Note that bash cannot export arrays so we use a trick to re-generate the array
# in the select_gpu script
#
cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
GPU_ORDER=( ${GPU_ORDER[@]} )
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

#
# Build the CPU binding
# Argument one is the GPU number, argument 2 is the mask. When hexedecimal, use the 0x notation.
#

function GtC {

    GCD=$1
    mask=$2
    
    # For each GCD, the corresponding CCD number.
    MAP_to_CCD=( 6 7 2 3 0 1 4 5 )

    CCD=${MAP_to_CCD[$GCD]}
    
    printf "0x%016x" $((mask << $((CCD*8))))

}

mask='0x02' # Use only core number 1 of each chiplet (so binary 00000010 which is 0x02)
CPU_BIND="mask_cpu"
CPU_BIND="$CPU_BIND:$(GtC ${GPU_ORDER[0]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[1]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[2]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[3]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[4]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[5]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[6]} $mask)"
CPU_BIND="$CPU_BIND,$(GtC ${GPU_ORDER[7]} $mask)"

export MPICH_GPU_SUPPORT_ENABLED=0

echo -e "\nTest runs:\n"
#srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND ./select_gpu_$SLURM_JOB_ID hybrid_check -r
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=$CPU_BIND ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
