#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker build \
  -f "${repo_root}/docker/nextflow-runtime.Dockerfile" \
  -t "phageflow/nextflow-runtime:0.1.0" \
  "${repo_root}"

echo "Built phageflow/nextflow-runtime:0.1.0"
