#!/bin/sh

set -e

SOURCE=$HOME/Code/celeritas-milan
BUILD=/scratch/s3j/build/celeritas-release-orange

# Check that the GPU is not in use
nvidia-smi pmon -c 1

export CELER_ENABLE_PROFILING=1
export CELER_LOG=info
export CELER_LOG_LOCAL=info
export CUDA_VISIBLE_DEVICES=6

which nsys

nsys profile \
  --trace=cuda,nvtx,osrt \
  --osrt-backtrace-stack-size=16384 --backtrace=fp \
  --nvtx-capture="celeritas" \
  -o trace.nsys-rep \
  -f true \
  $BUILD/bin/celer-optical \
  run-short.json
