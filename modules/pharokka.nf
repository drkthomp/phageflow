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

  cp pharokka_out/*.gff ${sample}.pharokka.gff
  cp pharokka_out/*.faa ${sample}.pharokka.cds.faa

  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\tNA\n" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
