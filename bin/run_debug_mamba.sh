#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_env="${repo_root}/.mamba/envs/phageflow-nextflow-runtime"
timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "${repo_root}/logs"

export NXF_DEBUG=3
export NXF_ANSI_LOG=false
export MAMBA_NO_BANNER=1

echo "[phageflow] Writing Nextflow log to logs/nextflow-debug-${timestamp}.log"
echo "[phageflow] Writing trace file to trace-${timestamp}.txt"

exec mamba run -p "${runtime_env}" \
  nextflow -trace nextflow,io.seqera \
  -log "${repo_root}/logs/nextflow-debug-${timestamp}.log" \
  run "${repo_root}/main.nf" \
  -profile local,mamba,debug \
  -with-trace "${repo_root}/trace-${timestamp}.txt" \
  -with-timeline "${repo_root}/timeline-${timestamp}.html" \
  -with-report "${repo_root}/report-${timestamp}.html" \
  "$@"
