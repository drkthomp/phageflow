# SOP: Running phageflow

## Purpose

Run a reproducible bacteriophage WGS workflow from FASTQ retrieval to an HTML report for wet lab interpretation.

## Preconditions

- Nextflow installed
- Docker or Singularity/Apptainer available for containerized execution
- Internet access for FASTQ retrieval (and optional Mash accession fetching)

## Inputs

`samplesheet.csv` with columns:

- `sample`
- `fastq_1`
- `fastq_2`

## Standard run

```bash
nextflow run main.nf -profile local,docker
```

## Standard run with SLURM

```bash
nextflow run main.nf -profile slurm,singularity
```

## Common parameters

- `--input` path to samplesheet
- `--outdir` output root directory
- `--max_reads` optional fastp read cap for quick tests
- `--run_pharokka` set to `false` to skip annotation

## Expected per-sample outputs

- `raw/` downloaded paired FASTQ
- `fastp/` trimmed FASTQ + HTML + JSON
- `spades/` contigs fasta
- `quast/` assembly metrics files
- `mash/` full distances + closest hit
- `pharokka/` annotation outputs (if enabled)
- `report/` final HTML summary

## Troubleshooting

- Fetch failures: verify URLs and network access
- Container pull failures: verify Docker/Singularity auth and internet
- Pharokka resource failures: increase `process.memory` and `process.time`
- SLURM pending jobs: verify queue in `conf/slurm.config`
