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

## Quickstart

```bash
nextflow run main.nf -profile local
```

With Docker:

```bash
nextflow run main.nf -profile local,docker
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
- `docker`: Docker containers enabled
- `singularity`: Singularity/Apptainer enabled

## Outputs

Per-sample outputs are published under `results/<sample>/`.

- `fastp` HTML + JSON
- `SPAdes` contigs (`contigs.fasta`)
- `QUAST` summaries
- `Mash` distance and closest-hit table
- `Pharokka` annotations (if enabled)
- Final HTML report
