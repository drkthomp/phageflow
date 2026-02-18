process PHAROKKA {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/pharokka" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)

  output:
  tuple val(sample), path("${sample}.pharokka.gff"), path("${sample}.pharokka.cds.faa"), path("${sample}.pharokka.summary.tsv"), emit: annotations

  script:
  """
  set -euo pipefail

  status="success"
  set +e
  pharokka.py \
    -i ${contigs} \
    -o pharokka_out \
    -p ${sample} \
    -t ${task.cpus}
  pharokka_exit=$?
  set -e

  if [[ ${pharokka_exit} -eq 0 ]]; then
    cp pharokka_out/*.gff ${sample}.pharokka.gff
    cp pharokka_out/*.faa ${sample}.pharokka.cds.faa
  else
    status="failed_missing_db"
    printf "##gff-version 3\n" > ${sample}.pharokka.gff
    : > ${sample}.pharokka.cds.faa
  fi

  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "status\t%s\n" "${status}" >> ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\tNA\n" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
