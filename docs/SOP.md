# SOP: Running phageflow

## Purpose

Run a reproducible bacteriophage WGS workflow from FASTQ retrieval to an HTML report for wet lab interpretation.

## Preconditions

- Nextflow installed
- Docker or Singularity/Apptainer available for containerized execution
- Internet access for FASTQ retrieval (and optional Mash accession fetching)

Recommended runtime setup:

```bash
mamba env create -f envs/nextflow-runtime.yml
mamba activate phageflow-nextflow-runtime
```

## Inputs

`samplesheet.csv` with columns:

- `sample`
- `fastq_1`
- `fastq_2`

## Standard run

```bash
nextflow run main.nf -profile local,docker
```

## Standard run without Docker (mamba process envs)

```bash
nextflow run main.nf -profile local,mamba
```

## Standard run with SLURM

```bash
nextflow run main.nf -profile slurm,singularity
```

SLURM with mamba envs:

```bash
nextflow run main.nf -profile slurm,mamba
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
- Mamba solve issues: run `mamba clean --all -y` and retry environment creation
- Pharokka resource failures: increase `process.memory` and `process.time`
- SLURM pending jobs: verify queue in `conf/slurm.config`
