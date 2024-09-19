# How to test?

-   Create the containerized installation:

    ```bash
  	module load LUMI/24.03
  	module load lumi-container-wrapper
  	
  	mkdir INSTALL
  	conda-containerize new --prefix INSTALL env.yml
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
        which python
        python --version
        python -c 'import scipy; print( scipy.__version__ )'
        exit
        ```

-   And clean-up:

    ```bash
    rm -rf INSTALL
    ```
    