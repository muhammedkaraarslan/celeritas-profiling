#!/bin/sh

export CELER_ENABLE_PROFILING=1
export CELER_LOG=info
export CELER_LOG_LOCAL=info

ncu \
--set full \
--nvtx --nvtx-include "celeritas@run/*/along-step" \
--launch-skip 10 --launch-count 1 \
-f -o output \
  /scratch/s3j/build/celeritas-reldeb-orange/bin/celer-optical \
  run-short.json

#ncu \
#  --set full
#  nvtx --nvtx-capture="run@celeritas" \
#  -f true -o output \
#  /scratch/s3j/build/celeritas-reldeb-orange/bin/celer-optical \
#  run.json
