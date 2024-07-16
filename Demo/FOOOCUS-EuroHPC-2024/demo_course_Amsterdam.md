###################################################################################
#
# PART 1: Install FOOOCUS
#

installdir=/project/project_462000008/kurtlust/DEMO
mkdir -p "$installdir" ; cd "$installdir"

# Get FOOOCUS
wget https://github.com/lllyasviel/Fooocus/archive/refs/tags/2.3.1.zip
unzip 2.32.1.zip
rm -f 2.3.1.zip

# Check what's in there...
ls Fooocus-2.3.1

# Update the data files. We need to modify the existing script for that as it also
# launches the application itself. This may not be needed right after a download?
#sed -e "s|from launch.*||" entry_with_update.py >update.py
#singularity exec $SIF python update.py



###################################################################################
#
# PART 2: Prepare the container + module + extra packages
#

#
# Install the PyTorch container
#
mkdir -p "$installdir/tmp" ; cd "$installdir/tmp"
module purge
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
# We also want to get rid of EasyBuild so we'll simply clean completely and restart.
module purge
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
export CONTAINERFILE="$SIF"
module unload PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315


#
# Now we will modify the container to add additional packages using zypper.
#
# First we need the proot command to be available.
module load systools

# First create the container definition file. The easiest is by pasting these lines
# as the shell will expand the variable expression which produces the name of the SIF
# file.
cat > lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.def <<EOF

Bootstrap: localimage

From: /appl/local/containers/easybuild-sif-images/${CONTAINERFILE##*/}

%post

zypper -n install -y Mesa libglvnd libgthread-2_0-0 hostname

EOF

# Now set some environment variables to give singularity faster working space.
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
# FOOOCUS needs additional Python packages and has a requirements file specifying which 
# ones so we will install those with pip. And it also wants to download data files.
# This needs to be done in the container.

# Re-load the module to initialize the container
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

# Return to the Fooocus subdirectory
cd ../Fooocus-2.3.1/
# Or alternatively
cd "$installdir/Fooocus-2.3.1"

# Enter the container
singularity shell $SIF

# Now install the extra packages 
pip install -r requirements_versions.txt

#
# Now we can finish the container and SquashFS overlay.
# Unfortunately we cannot add FOOOCUS itself to the container.
#
# Exit the container
exit
# Create the SquashFS file
make-squashfs
# Clean up the user-software directory
rm -rf $CONTAINERROOT/user-software
# Reload the module to let the changes take effect.
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

###################################################################################
#
# PART 3: Running the container.
#

#
# Option 1: Interactively
#

export SLURM_ACCOUNT=project_462XXXXXX
srun -psmall-g -n1 -c7 --time=30:00 --gpus=1 --mem=60G --pty bash
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
# Go into the singularity container
singularity shell $SIF
# Run fooocus launcher
cd "$installdir/Fooocus-2.3.1"
python launch.py --listen --disable-xformers

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# Change to compute node host name
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/

#
# Option 2: Start from the srun command.
#
export SLURM_ACCOUNT=project_462XXXXXX
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

cd "$installdir/Fooocus-2.3.1"

srun -psmall-g -n1 -c7 --time=30:00 --gpus=1 --mem=60G --pty bash -c 'echo -e "Running on $(hostname)\n" ; singularity exec $SIF python launch.py --listen --disable-xformers'

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# You can find the compute node name at the start of the output and the actual port 
# nunmber at the end once the model is set up to run.
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/





