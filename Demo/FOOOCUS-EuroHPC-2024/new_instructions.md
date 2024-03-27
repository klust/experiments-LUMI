###################################################################################
#
# PART 1: Prepare the container + module + extra packages
#

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
$ First we need the proot command to be available.
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
# FOOOCUS needs additional Python packages and has a requirements file specifying which 
# ones so we will install those with pip. And it also wants to download data files.
# This needs to be done in the container.

# Load the module to initialize the container
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

# Enter the container
singularity shell $SIF

# Now run in the container
cd /user-software/venv

cat >FOOOCUS-requirements.txt <<EOF
torchsde==0.2.5
einops==0.4.1
transformers==4.30.2
safetensors==0.3.1
accelerate==0.21.0
pyyaml==6.0
Pillow==9.2.0
scipy==1.9.3
tqdm==4.64.1
psutil==5.9.5
pytorch_lightning==1.9.4
omegaconf==2.2.3
gradio==3.41.2
pygit2==1.12.2
opencv-contrib-python==4.8.0.74
httpx==0.24.1
onnxruntime==1.16.3
timm==0.9.2
EOF

pip install -r FOOOCUS-requirements.txt

#
# Now we can finish the contaner and SquashFS overlay.
# Unfortunately we cannot add FOOOCUS itself to the container.
#
# Exit the container
exit
# Create the SquashFS file
make-squashfs
# Reload the module to let the changes take effect.
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

###################################################################################
#
# PART 2: Install FOOOCUS
#

cd /project/project_462XXXXXX


# Get FOOOCUS
git clone https://github.com/lllyasviel/Fooocus.git
cd Fooocus

# Update the data files. We need to modify the existing script for that as it also
# launches the application itself. This may not be needed right after a download?
sed -e "s|from launch.*||" entry_with_update.py >update.py
singularity exec $SIF python update.py

###################################################################################
#
# PART 3: Running the container.
#

#
# Option 1: Interactively
#

export SLURM_ACCOUNT=project_462XXXXXX
srun -n1 -c7 --partition=small-g --time=4:00:00 --gpus=1 --mem=60G --pty bash
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
# Go into the singularity container
singularity shell $SIF
# Run fooocus launcher
cd /project/project_462XXXXXX/Fooocus
python launch.py --listen --disable-xformers

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# Change to compute node host name
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/

#
# Option 2: Interactive job but no interactive access to singularity
#

export SLURM_ACCOUNT=project_462XXXXXX
srun -n1 -c7 --partition=small-g --time=4:00:00 --gpus=1 --mem=60G --pty bash
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315
# Run fooocus launcher
cd /project/project_462XXXXXX/Fooocus
singularity exec $SIF python launch.py --listen --disable-xformers

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# Change to compute node host name
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/

#
# Option 3: Start from the srun command.
#
export SLURM_ACCOUNT=project_462XXXXXX
module load LUMI/23.09
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-FOOOCUS-singularity-20240315

srun -n1 -c7 --partition=small-g --time=4:00:00 --gpus=1 --mem=60G --pty bash -c 'echo -e "Running on $(hostname)...\n" ; singularity exec $SIF python launch.py --listen --disable-xformers'

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# You can find the compute node name at the start of the output and the actual port 
# nunmber at the end once the model is set up to run.
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to
http://localhost:7865/





