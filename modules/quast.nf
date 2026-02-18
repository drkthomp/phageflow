process QUAST {
  tag { sample }
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
    awk -F': ' '/^# contigs|^Total length|^N50|^GC \(%\)/ {gsub(/^ +/, "", $1); print $1"\t"$2}' quast_out/report.txt >> ${sample}.quast.tsv || true
  fi
  """
}
