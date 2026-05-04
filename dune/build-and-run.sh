#!/bin/sh

set -e

export CELER_LOG=info
export CELER_LOG_LOCAL=info
export CUDA_VISIBLE_DEVICES=6

BUILD=/scratch/s3j/build/celeritas-release-orange

# Rebuild executable with updated cmake/git metadata
set -x
(cd $BUILD \
 && cmake -UCeleritas_CGV_CACHE . \
 && ninja celer-optical)

# Check that the GPU is not in use
nvidia-smi pmon -c 1

# Run and reformat output
$BUILD/bin/celer-optical run.json
jq . out.json > out.formatted.json && mv out.formatted.json out.json

# Summarize
jq '{
  total: .result.time.total,
  version: .system.build.version,
  actions: (.result.time.actions
    | with_entries(select(.key | IN("primary-generate","along-step","optical-boundary-init")))),
  kernels: (.system.kernels
    | map(select(.name | IN("primary-generate","along-step-propagate","optical-boundary-init","optical-boundary-post")))
    | map({key: .name, value: .})
    | from_entries)
}' out.json | tee out.filtered.json

