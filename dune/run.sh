#!/bin/sh

set -e

export CELER_LOG=debug
export CELER_LOG_LOCAL=debug
export CUDA_VISIBLE_DEVICES=6

set -x
/scratch/s3j/build/celeritas-release-orange/bin/celer-optical \
  run.json

jq '
.result.time.total,
.system.build.version,
(.result.time.actions | {"along-step", "optical-boundary-init"}),
(.system.kernels[] | objects | select(.name == "along-step-propagate"))
' out.json | tee out.filtered.jsonl

