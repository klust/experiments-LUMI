# First change to project folder (add your own project number)
cd /project/project_46XXXXX

# Install the PyTorch container
module load LUMI partition/container EasyBuild-user
eb PyTorch-2.2.0-rocm-5.6.1-python-3.10-singularity-20240209.eb

# Download Fooocus
git clone https://github.com/lllyasviel/Fooocus.git
cd Fooocus

# Create modified container
cat > lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.def <<EOF

Bootstrap: localimage

From: /appl/local/containers/easybuild-sif-images/lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-dockerhash-f72ddd8ef883.sif


%post

zypper -n install -y Mesa libglvnd libgthread-2_0-0 hostname

EOF

curl -LO https://proot.gitlab.io/proot/bin/proot
chmod +x ./proot

export PATH=$PWD:$PATH
export SINGULARITY_CACHEDIR=$XDG_RUNTIME_DIR/singularity/cache
export SINGULARITY_TMPDIR=$XDG_RUNTIME_DIR/singularity/tmp

mkdir -p $SINGULARITY_CACHEDIR
mkdir -p $SINGULARITY_TMPDIR

unset SINGULARITY_BIND

singularity build lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.sif lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.def

# Load Easybuild installed container but modify SIF variable to point to modified container
module load PyTorch/2.2.0-rocm-5.6.1-python-3.10-singularity-20240209
export SIF=$(pwd)/lumi-pytorch-rocm-5.6.1-python-3.10-pytorch-v2.2.0-Fooocus.sif

# Allocate a LUMI-G node for e.g. 4 hours, replace the project number
srun --account=project_462XXXX -n 1 --partition=small-g --time=4:00:00 --nodes=1 --gpus=1 --cpus-per-task=7 --mem=60G --pty bash

# Create virtual environment but first we have to start the container
singularity shell $SIF
$WITH_CONDA # has to be run every time you restart the container shell
python -m venv venv --system-site-packages # necessary to access container Pytorch installation
source venv/bin/activate
pip install -r requirements_versions.txt

# Run fooocus installer
python launch.py --listen --disable-xformers

# On your local machine create a SSH tunnel to LUMI (assuming you have a `lumi` rule in your ssh config)
# Change to compute node host name
ssh -N -L 7865:nid00XXXX:7865 lumi

#Navigate to

http://localhost:7865/
