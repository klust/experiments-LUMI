# MPI with GPU

## test_gpu_aware_mpi.f90

```bash
mpif90 -O3 -ffree-form -fopenmp --offload-arch=gfx90a test_gpu_aware_mpi.f90 -o test_gpu_aware_mpi.x \
  -L$MPICH_DIR/lib -lmpi_gtl_hsa
```

Be sure to use

```bash
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU
```

in your job script.

From the command line, you can try

```bash
MPICH_GPU_SUPPORT_ENABLED=1 MPICH_OFI_NIC_POLICY=GPU \
  srun  -n2 -c1 --gpus-per-task=1 -psmall-g -t5:00 ./test_gpu_aware_mpi.x
```

and the output should basically be

```
Hello from rank 0 of 2 on nid005083
Hello from rank 1 of 2 on nid005083
PASS: MPI_Allreduce correct (sum = 1)
PASS: GPU-aware MPI_Allreduce correct
All tests passed.
```

though the order of the lines may differ.
