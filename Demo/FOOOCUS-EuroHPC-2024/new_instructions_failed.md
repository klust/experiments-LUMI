# Instructions with container and SquashFS file with Fooocus

This approach does not work as unfortunately Fooocus writes in its own directories 
by default.

#
# Install the PyTorch container
#
mkdir -p ~/Work/FOOOCUS ; cd ~/Work/FOOOCUS
module load LUMI/23.09 partition/container EasyBuild-user
eb --copy-ec PyTorch-2.2.0-rocm-5.6.1-python-3.10-singularity-20240315.eb PyTorch-2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315.eb
sed -e "s|^\(versionsuffix.*\)-singularity-20240315|\1-FOOOCUS-singularity-20240315|" -i PyTorch-2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315.eb
eb PyTorch-2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315.eb
# DO NOT REMOVE THE SIF FILE CREATED IN THIS PROCESS IN YOUR OWN DIRECTORIES AS THAT 
# WOULD CAUSE A LATER STEP TO FAIL!

#
# Get the name of the container file from the module and unload the module again to 
# make sure that there are not SINGULARITY_* # or SINGULARITYENV_* environment 
# variables that may influence the singularity build process later on.
#
module purge
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
export CONTAINERFILE="$SIF"
module unload PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315


#
# Now we will modify the container to add additional packages using zypper.
#
module load PRoot # This tool will soon be included in the systools module of 23.09
# First create the container definition file. The easiest is by pasting these lines
# as the shell will expand the variable expression which produces the name of the SIF
# file.
cat > lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.def <<EOF

Bootstrap: localimage

From: /appl/local/containers/easybuild-sif-images/${CONTAINERFILE##*/}

%post

zypper -n install -y Mesa libglvnd libgthread-2_0-0 hostname

EOF

# Now set some environment variables to give singularity faster working spce.
# These settings only work for the login nodes of LUMI, not for the compute nodes.
export SINGULARITY_CACHEDIR=$XDG_RUNTIME_DIR/singularity/cache
export SINGULARITY_TMPDIR=$XDG_RUNTIME_DIR/singularity/tmp

mkdir -p $SINGULARITY_CACHEDIR
mkdir -p $SINGULARITY_TMPDIR

# And now do the actual magic...
# This will replace the SIF file used by the module with a different one.
singularity build $CONTAINERFILE lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.def

rm -rf $SINGULARITY_CACHEDIR $SINGULARITY_TMPDIR

#
# Now put the FOOOCUS code in a place where we can later embed it in the SquashFS file 
# that will be created with extensions for the container.
#
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
# Go into the container
singularity shell $SIF
# Go to the user software installation directory.
cd /user-software
# Get the FOOOCUS code
git clone https://github.com/lllyasviel/Fooocus.git
# So now the FOOOCUS code will be available in /user-software/FOOOCUS inside the container 
# and $CONTAINERROOT/user-software/FOOOCUS outside the container.

#
# FOOOCUS needs additional Python packages and has a requirements file specifying which 
# ones so we will install those with pip. And it also wants to download data files.
#
# This is still in the container!
#
cd /user-software/Fooocus
pip install -r requirements_versions.txt
# Update the data files. We need to modify the existing script for that as it also
# launches the application itself.
sed -e "s|from launch.*||" entry_with_update.py >update.py
python update.py

#
# Finishing touches
#
# Exit the container
exit
# Create the SquashFS file
make-squashfs
# Reload the module to let the changes take effect.
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

#
# Running the container.
#
export SLURM_ACCOUNT=project_462XXXXXX
srun -n1 -c7 --partition=small-g --time=30:00 --gpus=1 --mem=60G --pty bash
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
# Go into the singularity container
singularity shell $SIF
# Run fooocus launcher
python /user-software/Fooocus/launch.py --listen --disable-xformers

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# Change to compute node host name
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/




