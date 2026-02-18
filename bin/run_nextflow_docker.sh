#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="${PHAGEFLOW_RUNTIME_IMAGE:-phageflow/nextflow-runtime:0.1.0}"

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${repo_root}":/workspace \
  -w /workspace \
  "${image}" \
  run main.nf -profile local,docker "$@"
