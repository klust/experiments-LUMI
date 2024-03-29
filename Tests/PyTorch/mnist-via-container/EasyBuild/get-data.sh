#! /usr/bin/env bash
mkdir mnist ; pushd mnist
wget https://raw.githubusercontent.com/Lumi-supercomputer/lumi-reframe-tests/main/checks/containers/ML_containers/src/pytorch/mnist/mnist_DDP.py
mkdir -p model ; cd model
wget https://github.com/Lumi-supercomputer/lumi-reframe-tests/raw/main/checks/containers/ML_containers/src/pytorch/mnist/model/model_gpu.dat
popd
