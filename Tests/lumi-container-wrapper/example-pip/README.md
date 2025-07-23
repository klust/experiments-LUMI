# How to test?

-   Create the containerized installation:

    ```bash
    module load LUMI/24.03
    module load lumi-container-wrapper
  	
    mkdir INSTALL
  	pip-containerize new --prefix INSTALL requirements.txt
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
        which mkdocs
        mkdocs --version
        _debug_exec cat /.singularity.d/labels.json
        _debug_exec cat /etc/os-release
        exit
        ```

-   And clean-up:

    ```bash
    rm -rf INSTALL
    ```
