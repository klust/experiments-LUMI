# Data Distributed Example with PyTorch

In this hands-on a data parallelization schema has to be implemented using data distributed package of PyTorch (aka `torch.distributed`).


## Load the environment

The CINECA-AI module must be loaded in order to use the required software stack.
```
# load CINECA-AI module for AI software stack
module load profile/candidate
module load cineca-ai/4.3.0
```

Moreover, the imagenet dataset is also used.
```
# load IMAGENET module for imagenet dataset
module load profile/deeplrn
module load imagenet
```


## Reference Benchmark

Run the serial example as reference:
```
python torch_single_gpu.py
```

Then parallelize the example with the methods presented in the lesson.
 

## How to submit to SLURM scheduler


Prepare the SLURM submission script as shown in the following example.
```
#!/bin/bash
#SBATCH --nodes=1               # number of nodes
#SBATCH --ntasks-per-node=4     # number of tasks per node
#SBATCH --cpus-per-task=8       # number of threads per task
#SBATCH --gres=gpu:4            # number of gpus per node
#SBATCH --time 0:10:00          # format: HH:MM:SS
#SBATCH --exclusive

#SBATCH -p boost_usr_prod
#SBATCH -A EUHPC_T_Boot-AI
#SBATCH --reservation s_tra_bootAI

module load profile/candidate
module load cineca-ai/4.3.0

module load profile/deeplrn
module load imagenet

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# export MASTER_ADDR and MASTER_PORT
...

# run the script
...
```

To submit the job to the queue system execute the `sbatch` command:
```
sbatch submit.sh
```


## Scaling

Run the script with different number of GPUs and compute the speed-up of your runs.
Annotate the elapsed time with the number of GPUs used in the training in the file `results.txt`.
Then use the `plot.py` script to plot the results in the `speed-up.png` figure.
