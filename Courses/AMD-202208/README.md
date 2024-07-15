# Hands-on

module load LUMI/22.06
module load rocm


* First check the script get_bind.sh and the output after the execution 

* Then the script binding.sh, execute and check output 

* Compile saxpy.cpp file with hipcc (remember the offload-arch)

* Use the submit_saxpy.sh  (load any module if required)

* Download some examples

git clone https://github.com/ROCm-Developer-Tools/HIP-Examples.git

cd HIP-Examples/openmp-helloworld

* Compile (make) gives some errors
* add HIPFLAGS=--offload-arch=gfx90a
* use the script  submit_openmp.sh, adjust if required

* Hipify

cd HIP-Examples/mini-nbody/
cp -r cuda cuda_hipify
cd cuda_hipify
hipify-perl  nbody-block.cu
hipify-perl  -i nbody-block.cu
mv nbody-block.cu nbody-block.cpp

You can compile and run

* Profile saxpy, see slide 56

** Print statistics about saxpy kernel (--stats)
	Two output files:
 	results.csv
 	results.stats.csv

** Use basenames
	--basenames

** Profile hi/hsa trace
	--hip-trace --hsa-trace
	Visualize with Perfetto (copy the files on your laptop)


* Create one folder/file per MPI process, see file  submit_profiling.sh

* Debug saxpy (first break something on the code comment a HIP memory allocation)
