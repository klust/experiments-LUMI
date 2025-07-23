# How to test?

Example from [hpc-container-wrapper github](https://github.com/CSCfi/hpc-container-wrapper/blob/master/examples/fftw.md).

-   Create the containerized installation:

    ```bash
  	module load LUMI/24.03
  	module load lumi-container-wrapper
  	
  	mkdir INSTALL
  	conda-containerize new --prefix INSTALL --post install_prog.sh -w fftw_prog def.yml
  	```
	
-   Some testing:

    -   Start a new bash shell:
    
        ```bash
        bash
        ```
        
    -   In that shell:
    
        ```bash
        cd INSTALL
        PATH=$PWD/bin:$PATH
        which fftw_prog
        fftw_prog
        _debug_exec cat /.singularity.d/labels.json
        _debug_exec cat /etc/os-release
        exit
        ```

-   And clean-up:

    ```bash
    rm -rf INSTALL
    ```
    