#!/bin/bash
#SBATCH --job-name=srun-expands-arguments
#SBATCH --output %x-%j.txt
#SBATCH --partition=small
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=2:00

#
# Create the script that we will use to test.
#

cat << EOF > count_args_$SLURM_JOB_ID
#!/bin/bash

echo "Number of arguments is \$#"

for num in $(seq 1 \$#)
do
    echo "Argument: \$1"
    shift
done

EOF
chmod u+x count_args_$SLURM_JOB_ID

#
# Include jobscript and generated script in the output
#

echo -e "\nVerification of job script:\n=========================================================================="
cat $0
echo -e "==========================================================================\n"

echo -e "\n Generated count_args script:\n=========================================================================="
cat count_args_$SLURM_JOB_ID
echo -e "==========================================================================\n"

#
# Actual tests demonstrating the bug
#

echo -e"\nRunning, commands are shown:\n"
set -x
./count_args_$SLURM_JOB_ID 1 2 "3 3bis"

srun 

set +x ./count_args_$SLURM_JOB_ID 1 2 "3 3bis"

/bin/rm -f count_args_$SLURM_JOB_ID
