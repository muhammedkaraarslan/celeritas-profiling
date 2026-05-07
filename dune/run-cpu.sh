#!/bin/sh

set -e

SOURCE=$HOME/Code/celeritas-milan
BUILD=/scratch/s3j/build/celeritas-release-orange
OUTFILE=out-cpu

# Check that source is clean, save last commit message
MSG="$(
  cd $SOURCE
  if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: source directory $(pwd) is dirty; commit and try again" >&2
    exit 1
  fi
  git log -1 --format='%s%n%nSource commit %h (%cd)'
  git log -1 --format='Parent commit %h (%cd): %s' HEAD^
)"

# Run and reformat output
export CELER_LOG=info
export CELER_LOG_LOCAL=info
export CELER_DISABLE_DEVICE=1
$BUILD/bin/celer-optical run-cpu.json
jq . $OUTFILE.json > $OUTFILE.formatted.json \
  && mv $OUTFILE.formatted.json $OUTFILE.json

# Summarize
jq '{
  total: .result.time.total,
  version: .system.build.version,
  actions: (.result.time.actions
    | with_entries(select(.key | IN("primary-generate","along-step","optical-boundary-init"))))
}' $OUTFILE.json | tee $OUTFILE.filtered.json

# Commit with saved mesage
git add .
git commit -m "CPU: ${MSG}" -m "Total runtime: $(jq .total $OUTFILE.filtered.json)"
git show HEAD -- $OUTFILE.filtered.json
