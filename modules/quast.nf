process QUAST {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/quast" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)

  output:
  tuple val(sample), path("${sample}.quast.tsv"), path("${sample}.quast.report.txt"), emit: metrics

  script:
  """
  set -euo pipefail

  quast.py \
    ${contigs} \
    -o quast_out \
    --threads ${task.cpus}

  cp quast_out/report.txt ${sample}.quast.report.txt

  if [[ -f quast_out/transposed_report.tsv ]]; then
    cp quast_out/transposed_report.tsv ${sample}.quast.tsv
  elif [[ -f quast_out/report.tsv ]]; then
    cp quast_out/report.tsv ${sample}.quast.tsv
  else
    printf "metric\tvalue\n" > ${sample}.quast.tsv
    printf "contigs\tNA\n" >> ${sample}.quast.tsv
    printf "total_length\tNA\n" >> ${sample}.quast.tsv
    printf "N50\tNA\n" >> ${sample}.quast.tsv
  fi
  """

  stub:
  """
  set -euo pipefail
  printf "metric\tvalue\ncontigs\t1\ntotal_length\t56\nN50\t56\n" > ${sample}.quast.tsv
  printf "QUAST stub report for ${sample}\n" > ${sample}.quast.report.txt
  """
}
