#!/bin/sh

set -e

export CELER_LOG=debug
export CELER_LOG_LOCAL=debug
export CELER_DISABLE_DEVICE=1

set -x
gdb --args /scratch/s3j/build/celeritas-debug-orange/bin/celer-optical \
  run-debug.json

jq '
.result.time.total,
.system.build.version,
(.result.time.actions | {"along-step", "optical-boundary-init"}),
(.system.kernels[] | objects | select(.name == "along-step-propagate"))
' out-debug.json

