#! /bin/bash
#SBATCH --job-name=14tpn_64t
#SBATCH --output %x-%j.txt
#SBATCH --partition=standard-g
#SBATCH --nodes=5
#SBATCH --hint=nomultithread
#SBATCH --time=5:00
#SBATCH --gpus-per-node=8

NTASKS=64
MAX_PER_NODE=14

echo "Submitted from $SLURM_SUBMIT_HOST"
echo "Running on $SLURM_JOB_NODELIST"
echo
echo -e "Job script:\n$(cat $0)\n"
echo "SLURM_* and SRUN_* environment variables:"
env | egrep ^SLURM
env | egrep ^SRUN

module load LUMI/23.09 partition/G lumi-CPEtools/1.1-cpeGNU-23.09

cat << EOF > select_gpu_$SLURM_JOB_ID
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$((\${SLURM_LOCALID}/2))
exec \$*
EOF
chmod +x select_gpu_$SLURM_JOB_ID

CPU_BIND1="map_cpu:49,55,57,63,17,23,25,31,1,7,9,15,33,39,41,47"

#
# Without ntasks-per-node: Slurm will by default spread the tasks evenly over
# the nodes available for the job.
#
echo -e "\n\n1. Withour --ntasks-per-node: Slurm tries to distribute tasks equally across the nodes."
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l

#
# With ntasks-per-node: Slurm will even warn and just neglect the parameter.
#
echo -e "\n\n2. With --ntasks-per-node: Warning, and same distribution as 1."
srun --nodes=$SLURM_NNODES --ntasks-per-node=$MAX_PER_NODE --ntasks=$NTASKS --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --nodes=$SLURM_NNODES --ntasks-per-node=$MAX_PER_NODE --ntasks=$NTASKS --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l

#
# With ntasks-per-node and packed distribution
#
echo -e "\n\n3. With --distribution=block,pack and 4 CPUs per task (but bad mapping of GPUs onto CPUs!)."
export OMP_NUM_THREADS=1
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --cpus-per-task=4 --distribution=block,pack ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --cpus-per-task=4 --distribution=block,pack ./select_gpu_$SLURM_JOB_ID gpu_check -l

#
# With ntasks-per-node and packed distribution
#
echo -e "\n\n4. Trying a plane distribution"
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --distribution=plane=$MAX_PER_NODE --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID mpi_check -r
srun --nodes=$SLURM_NNODES --ntasks=$NTASKS --distribution=plane=$MAX_PER_NODE --cpu-bind=$CPU_BIND1 ./select_gpu_$SLURM_JOB_ID gpu_check -l

/bin/rm -f select_gpu_$SLURM_JOB_ID
