#!/bin/sh

set -e

SOURCE=$HOME/Code/celeritas-milan
BUILD=/scratch/s3j/build/celeritas-release-orange
GPU_OUT=out
CPU_OUT=out-cpu

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

# Run GPU and reformat output
export CELER_LOG=info
export CELER_LOG_LOCAL=info
export CUDA_VISIBLE_DEVICES=6
$BUILD/bin/celer-optical run.json
jq . ${GPU_OUT}.json > ${GPU_OUT}.formatted.json && mv ${GPU_OUT}.formatted.json ${GPU_OUT}.json

jq '{
  total: .result.time.total,
  version: .system.build.version,
  actions: (.result.time.actions
    | with_entries(select(.key | IN("primary-generate","along-step","boundary-init")))),
  kernels: (.system.kernels
    | map(select(.name | IN("primary-generate","along-step-propagate","boundary-init","boundary-post")))
    | map({key: .name, value: .})
    | from_entries)
}' ${GPU_OUT}.json | tee ${GPU_OUT}.filtered.json
GPU_TOTAL="$(jq .total ${GPU_OUT}.filtered.json)"

# Commit with saved mesage
git add .
git commit \
  -m "${MSG}" -m "Total GPU runtime: ${GPU_TOTAL}"

# Run CPU
$BUILD/bin/celer-optical run-cpu.json
jq . ${CPU_OUT}.json > ${CPU_OUT}.formatted.json \
  && mv ${CPU_OUT}.formatted.json ${CPU_OUT}.json
jq '{
  total: .result.time.total,
  version: .system.build.version,
  actions: (.result.time.actions
    | with_entries(select(.key | IN("primary-generate","along-step","optical-boundary-init"))))
}' ${CPU_OUT}.json | tee ${CPU_OUT}.filtered.json
CPU_TOTAL="$(jq .total ${CPU_OUT}.filtered.json)"

# Commit with saved mesage
git add .
git commit \
  -m "${MSG}" \
  -m "Total GPU runtime: ${GPU_TOTAL}"
  -m "Total CPU runtime: ${CPU_TOTAL}"

git show HEAD -- *.filtered.json
