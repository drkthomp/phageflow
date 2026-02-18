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
    total_length=$(grep -E '^Total length' quast_out/report.txt | head -n 1 | cut -d':' -f2- | sed 's/^ //') || true
    n50_value=$(grep -E '^N50' quast_out/report.txt | head -n 1 | cut -d':' -f2- | sed 's/^ //') || true
    contigs_count=$(grep -E '^# contigs' quast_out/report.txt | head -n 1 | cut -d':' -f2- | sed 's/^ //') || true

    printf "contigs\t%s\n" "${contigs_count:-NA}" >> ${sample}.quast.tsv
    printf "total_length\t%s\n" "${total_length:-NA}" >> ${sample}.quast.tsv
    printf "N50\t%s\n" "${n50_value:-NA}" >> ${sample}.quast.tsv
  fi
  """
}
