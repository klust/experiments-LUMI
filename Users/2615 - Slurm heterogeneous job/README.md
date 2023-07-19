# Failure of a heterogeneous job 

-   `reproducer.sh`: Based on the reproducer of the user. It produces an error message:
    
    ```
    "srun: fatal: SLURM_MEM_PER_CPU, SLURM_MEM_PER_GPU, and SLURM_MEM_PER_NODE are mutually exclusive."
    ```
    
-   `reproducer2.sh`: Switched instead to the `standard-g` and `standard` partition 
    and this solves the problem.
    
    
Reaction from Fredrik:

Ticket #2615, small-g has a default per node memory set, and small does not. 
So that then ends up with conflicting flags. 

So the easy solution is to either use standard yes as they anyway take whole nodes, 
or then just specify the memory to both subjobs with the same flags like adding `--mem=xx` to both

```
PartitionName=small-g     MaxNodes=4         MaxTime=72:00:00 Nodes=nid[007240-007519] DefMemPerNode=65536 MaxCPUsPerNode=UNLIMITED
```
vs
```
PartitionName=small       MaxNodes=4         MaxTime=72:00:00 Nodes=nid00[2028-2152,2154-2523]
```

So that then inherits a `--mem` from small-g but a `--mem-per-task` from small

