#!/bin/sh

export CELER_ENABLE_PROFILING=1
export CELER_LOG=info
export CELER_LOG_LOCAL=info

nsys profile \
  --trace=cuda,nvtx,osrt \
  --osrt-backtrace-stack-size=16384 --backtrace=fp \
  --nvtx-capture="celeritas" \
  -o trace.nsys-rep \
  -f true \
  /scratch/s3j/build/celeritas-reldeb-orange/bin/celer-optical \
  run-short.json
