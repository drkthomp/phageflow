# Benchmarking and QA notes

## Goal

Provide lightweight, repeatable quality checks and comparison outputs that support workflow optimization and SOP updates.

## Core checks

1. `fastp` read retention and Q30 improvement from JSON summary
2. QUAST assembly metrics (`# contigs`, total length, N50, GC)
3. Mash closest-reference distance table (`sample.mash.closest.tsv`)
4. Pharokka predicted protein count (`sample.pharokka.summary.tsv`)

## Suggested acceptance thresholds (MVP)

- `fastp` output files exist and JSON parses correctly
- `contigs.fasta` exists and is non-empty
- QUAST report exists and includes N50
- Mash closest-hit table has at least one row
- Pharokka summary exists when enabled

## Reproducibility evidence

Run with:

```bash
nextflow run main.nf -profile local -with-trace -with-timeline -with-report -with-dag dag.svg
```

Keep the generated trace/timeline/report files with the run output for transparent review.
