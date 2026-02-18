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
  recommendation="none"

  set +e
  pharokka.py \
    -i ${contigs} \
    -o pharokka_out \
    -p ${sample} \
    -t ${task.cpus} \
    > ${sample}.pharokka.stdout.log \
    2> ${sample}.pharokka.stderr.log
  pharokka_exit=$?
  set -e

  if [[ ${pharokka_exit} -eq 0 ]]; then
    cp pharokka_out/*.gff ${sample}.pharokka.gff
    cp pharokka_out/*.faa ${sample}.pharokka.cds.faa
  else
    if grep -qi 'install_databases.py' ${sample}.pharokka.stderr.log ${sample}.pharokka.stdout.log; then
      status="skipped_missing_db"
      recommendation="Please run install_databases.py."
    else
      status="failed_runtime"
      recommendation="Check Pharokka stderr and stdout logs."
    fi

    printf "##gff-version 3\n" > ${sample}.pharokka.gff
    : > ${sample}.pharokka.cds.faa
  fi

  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "status\t%s\n" "${status}" >> ${sample}.pharokka.summary.tsv
  printf "recommendation\t%s\n" "${recommendation}" >> ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\tNA\n" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
