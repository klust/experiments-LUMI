# BabelStream in SYCL.

Source: [BablStream GitHub repository](https://github.com/UoB-HPC/BabelStream)


To run:

-   First check the devices that are available. Device 0 is the CPU!
    
    ```
    srun -n 1 -c 1 --gpus-per-task=1 ./a.out --list
    ````
    
-   Then run:

    ```
    srun -n 1 -c 1 --gpus-per-task=1 ./a.out --device 1 --arraysize 819200000
    ```
