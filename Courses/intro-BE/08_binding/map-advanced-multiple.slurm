#!/bin/bash
#SBATCH --job-name=map-advanced-multiple
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --time=5:00

module load LUMI/24.03 partition/G lumi-CPEtools/1.2-cpeCray-24.03

#
# Define the order of the GPUs and the core mask for CCD0
# It is important that the order of the GPUs is a string with the numbers separated by spaces.
#
GCD_ORDER="0 1 5 4 6 7 3 2"
coremask='2#00000010'  # Can use the binary representation, hexadecimal with 0x, or decimal

#
# run_gpu script, takes the string with GCDs as the first argument.
#
cat << EOF > run_gpu_$SLURM_JOB_ID
#!/bin/bash
GCD_ORDER=( \$1 )
shift
export ROCR_VISIBLE_DEVICES=\${GCD_ORDER[\$SLURM_LOCALID]}
exec "\$@"
EOF
chmod +x run_gpu_$SLURM_JOB_ID

#
# Build the CPU binding
# Argument one is mask, all other arguments are treated as an array of GCD numbers.
#

function generate_mask {

    # First argument is the mask for CCD0
    mask=$1

    # Other arguments are either a string already with the GCDs, or just one GCD per argument.
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

export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU

# Some mappings:
linear_CCD="4 5 2 3 6 7 0 1"
linear_GCD="0 1 2 3 4 5 6 7" 
ring_green="0 1 3 2 4 5 7 6"
ring_red="0 1 5 4 6 7 3 2"

echo -e "\nTest runs:\n"
# Use either "hpcat --disable-nic" or "gpu_check -l"
exe="gpu_check -l"

echo -e "\nConsecutive CCDs:\n"
srun --ntasks=$((SLURM_NNODES*8)) \
     --cpu-bind=mask_cpu:$(generate_mask $coremask $linear_CCD) \
     ./run_gpu_$SLURM_JOB_ID "$linear_CCD" $exe

echo -e "\nConsecutive GCDs:\n"
sleep 5
srun --ntasks=$((SLURM_NNODES*8)) \
     --cpu-bind=mask_cpu:$(generate_mask $coremask $linear_GCD) \
     ./run_gpu_$SLURM_JOB_ID "$linear_GCD" $exe

echo -e "\nGreen ring:\n"
sleep 5
srun --ntasks=$((SLURM_NNODES*8)) \
     --cpu-bind=mask_cpu:$(generate_mask $coremask $ring_green) \
     ./run_gpu_$SLURM_JOB_ID "$ring_green" $exe

echo -e "\nRed ring:\n"
sleep 5
srun --ntasks=$((SLURM_NNODES*8)) \
     --cpu-bind=mask_cpu:$(generate_mask $coremask $ring_red) \
     ./run_gpu_$SLURM_JOB_ID "$ring_red" $exe

echo -e "\nFirst two CPU NUMA domains (assuming one node in the allocation):\n"
half="4 5 2 3"
sleep 5
srun --ntasks=4 \
     --cpu-bind=mask_cpu:$(generate_mask $coremask $half) \
     ./run_gpu_$SLURM_JOB_ID "$half" $exe

/bin/rm -f run_gpu_$SLURM_JOB_ID
