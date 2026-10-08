# MPI with GPU

## test_gpu_aware_mpi.f90

```bash
mpif90 -O3 -ffree-form -fopenmp --offload-arch=gfx90a test_gpu_aware_mpi.f90 -o test_gpu_aware_mpi.x \
  -L$MPICH_DIR/lib -lmpi_gtl_hsa
```

```bash
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU
```

