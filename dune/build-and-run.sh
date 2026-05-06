#!/bin/sh

set -e

SOURCE=$HOME/Code/celeritas-milan
BUILD=/scratch/s3j/build/celeritas-release-orange

# Check that this dir is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: profiling directory $(pwd) is dirty; commit and try again" >&2
  exit 1
fi

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

# Rebuild executable with updated cmake/git metadata
set -x
(
  cd $BUILD
  cmake -UCeleritas_CGV_CACHE .
  ninja celer-optical
)

# Check that the GPU is not in use
nvidia-smi pmon -c 1

# Run and reformat output
export CELER_LOG=info
export CELER_LOG_LOCAL=info
export CUDA_VISIBLE_DEVICES=6
$BUILD/bin/celer-optical run.json
jq . out.json > out.formatted.json && mv out.formatted.json out.json

# Summarize
jq '{
  total: .result.time.total,
  version: .system.build.version,
  actions: (.result.time.actions
    | with_entries(select(.key | IN("primary-generate","along-step","boundary-init")))),
  kernels: (.system.kernels
    | map(select(.name | IN("primary-generate","along-step-propagate","boundary-init","boundary-post")))
    | map({key: .name, value: .})
    | from_entries)
}' out.json | tee out.filtered.json

# Commit with saved mesage
echo "MSG: ${MSG}"
git add .
git commit -m "${MSG}" -m "Total runtime: $(jq .total out.filtered.json)"
git show HEAD -- out.filtered.json
