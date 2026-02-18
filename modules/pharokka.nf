process PHAROKKA {
  tag { sample }
  publishDir { "${params.outdir}/${sample}/pharokka" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)

  output:
  tuple val(sample), path("${sample}.pharokka.gff"), path("${sample}.pharokka.cds.faa"), path("${sample}.pharokka.summary.tsv"), emit: annotations

  script:
  """
  set -euo pipefail

  pharokka.py \
    -i ${contigs} \
    -o pharokka_out \
    -p ${sample} \
    -t ${task.cpus}

  gff_file=$(find pharokka_out -maxdepth 1 -name "*.gff" | head -n 1)
  faa_file=$(find pharokka_out -maxdepth 1 -name "*.faa" | head -n 1)

  cp "$gff_file" ${sample}.pharokka.gff
  cp "$faa_file" ${sample}.pharokka.cds.faa

  proteins=$(grep -c '^>' ${sample}.pharokka.cds.faa || true)
  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\t%s\n" "$proteins" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
