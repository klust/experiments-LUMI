#!/bin/bash -e

# Start conda environment inside the container
$WITH_CONDA

# Run application
python -c 'import torch; print("I have this many devices:", torch.cuda.device_count())'

