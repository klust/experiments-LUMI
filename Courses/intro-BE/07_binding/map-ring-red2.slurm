#!/bin/bash
#SBATCH --job-name=map-ring-red2
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
# Define the order of the GPUs and the core mask for CCD0
#
# Do use a space-separated string as bash cannot export arrays.
# We'll convert to an array when needed in the scripts and functions.
#
export GCD_ORDER="0 1 5 4 6 7 3 2"
coremask='2#00000010'  # Can use the binary representation, hexadecimal with 0x, or decimal

#
# gpu_select script, requires GPU_ORDER to be exported from the mother shell
#
cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
GPU_ORDER=(\$GCD_ORDER )
export ROCR_VISIBLE_DEVICES=\${GPU_ORDER[\$SLURM_LOCALID]}
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

#
# Build the CPU binding
# Argument one is mask, all other arguments are treated as an array of GCD numbers.
#

function generate_mask {

    # First argument is the mask for CCD0
    mask=$1
    
    # Other arguments are either a string with the GCDs (space-speparated) or individual numbers of GCDs.
    shift
    GCDs=( "$@" )
    # Fully expand (doesn't matter as the loop can deal with it, but good if we want to check the number)
    GCDs=( ${GCDs[@]} )
    
    # For each GCD, the corresponding CCD number in the optimal mapping.
    MAP_to_CCD=( 6 7 2 3 0 1 4 5 )

    CPU_BIND=""
    
    # Loop over the GCDs in the order of the list to compute the corresponding
    # CPU mask.
    for GCD in ${GCDs[@]}
    do
        # Get the matching CCD for this GCD
        CCD=${MAP_to_CCD[$GCD]}
        
        # Shift the mask for CCD0 to the position for CCD $CCD
        printf -v tmpvar "0x%016x" $((mask << $((CCD*8))))
        
        # Add to CPU_BIND. We'll remove the leading , this creates later.
        CPU_BIND="$CPU_BIND,$tmpvar"
    done

    # Strip the leading ,
    CPU_BIND="${CPU_BIND#,}"
    
    # Return the result by printing to stdout
    printf "$CPU_BIND"

}

#
# Running the check programs
#

export MPICH_GPU_SUPPORT_ENABLED=0

echo -e "\nTest runs:\n"
srun --ntasks=$((SLURM_NNODES*8)) --cpu-bind=mask_cpu:$(generate_mask $coremask $GCD_ORDER) ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
