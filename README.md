# phageflow

`phageflow` is a Nextflow DSL2 pipeline focused on bacteriophage WGS analysis.

Pipeline stages:

1. Fetch paired FASTQs from public URLs
2. QC and trimming (`fastp`)
3. Assembly (`SPAdes`)
4. Assembly metrics (`QUAST`)
5. Genomic fingerprinting (`Mash`)
6. Phage annotation (`Pharokka`, optional)
7. Wet-lab-friendly HTML report (`R Markdown`)

## Versioning strategy (mamba + docker)

`phageflow` uses both systems, each where it is strongest:

- `mamba` pins the orchestration/runtime layer (Nextflow + Java + Docker CLI) in `envs/nextflow-runtime.yml`.
- `docker` pins bioinformatics tool execution per process (fastp/SPAdes/QUAST/Mash/Pharokka/Report) via `conf/base.config` containers.
- `mamba` process envs are also pinned in `envs/*.yml` and used with `-profile mamba` when Docker is unavailable.

This gives reproducibility plus flexibility across laptop/HPC environments.

## Quickstart

### Option A (recommended): run Nextflow from mamba, tools in Docker

```bash
mamba env create -f envs/nextflow-runtime.yml
mamba activate phageflow-nextflow-runtime
nextflow run main.nf -profile local,docker
```

### Option B: run Nextflow itself in a Docker runtime image

```bash
./bin/build_nextflow_runtime.sh
./bin/run_nextflow_docker.sh
```

### Option C: full mamba execution (no Docker)

```bash
mamba env create -f envs/nextflow-runtime.yml
mamba activate phageflow-nextflow-runtime
nextflow run main.nf -profile local,mamba
```

Use this mode when Docker is disallowed (certain HPC nodes). For phage annotation robustness, Docker mode is preferred.

```bash
nextflow run main.nf -profile local
```

With Docker:

```bash
nextflow run main.nf -profile local,docker
```

Dry-run wiring check:

```bash
nextflow run main.nf -profile local -stub-run -with-dag dag.svg
```

Generate provenance artifacts:

```bash
nextflow run main.nf -profile local -with-trace -with-timeline -with-report
```

## Input

`samplesheet.csv` format:

```csv
sample,fastq_1,fastq_2
SRR24913468,https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR249/008/SRR24913468/SRR24913468_1.fastq.gz,https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR249/008/SRR24913468/SRR24913468_2.fastq.gz
```

## Profiles

- `local`: local executor
- `slurm`: SLURM executor
- `mamba`: process environments resolved by Conda/Mamba
- `docker`: Docker containers enabled
- `singularity`: Singularity/Apptainer enabled

SLURM example:

```bash
nextflow run main.nf -profile slurm,singularity
```

SLURM + mamba example:

```bash
nextflow run main.nf -profile slurm,mamba
```

## Outputs

Per-sample outputs are published under `results/<sample>/`.

- `fastp` HTML + JSON
- `SPAdes` contigs (`contigs.fasta`)
- `QUAST` summaries
- `Mash` distance and closest-hit table
- `Pharokka` annotations (if enabled)
- Final HTML report

## Job-fit competency matrix

| Job requirement | Evidence in phageflow |
|---|---|
| Nextflow pipeline execution | `main.nf`, DSL2 modules, profile-based config |
| Genomic comparisons | `modules/mash.nf` distance and closest-hit tables |
| Protein annotations | `modules/pharokka.nf` + per-sample annotation summary |
| Wet-lab reporting | `assets/report.Rmd` + `bin/make_report.R` HTML report |
| Data management | Structured outputs in `results/<sample>/...` |
| QA and benchmarking | QUAST metrics + report summary table |
| SOP and transparency | `docs/SOP.md` and reproducible run commands |
| Containerized reproducibility | Docker/Singularity profiles in `nextflow.config` |
| HPC readiness | `conf/slurm.config` |

## SOP pointers

- Runbook: `docs/SOP.md`
- Benchmarking notes: `docs/benchmarking.md`

## Notes

- Default sample is SRR24913468 from PRJNA983107.
- `params.run_pharokka=true` by default; set to false for a lighter run.
- Mash references are sourced from `assets/mash_refs/accessions.txt` with fallback to `assets/mash_refs/refs.fasta`.
- Runtime Docker image definition is in `docker/nextflow-runtime.Dockerfile`.
