#!/bin/sh

set -e

export CELER_LOG=debug
export CELER_LOG_LOCAL=debug
export CUDA_VISIBLE_DEVICES=6

set -x
/scratch/s3j/build/celeritas-release-orange/bin/celer-optical \
  run.json

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

