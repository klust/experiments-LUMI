module load LUMI/24.03
module load lumi-container-wrapper

mkdir INSTALL
conda-containerize new --prefix INSTALL env.yml
