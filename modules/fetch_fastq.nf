process FETCH_FASTQ {
  tag { sample }
  publishDir { "${params.outdir}/${sample}/raw" }, mode: 'copy'

  input:
  tuple val(sample), val(fastq_1), val(fastq_2)

  output:
  tuple val(sample), path("${sample}_1.fastq.gz"), path("${sample}_2.fastq.gz"), emit: reads

  script:
  """
  set -euo pipefail

  if command -v curl >/dev/null 2>&1; then
    curl -L --retry 3 --retry-delay 5 -o ${sample}_1.fastq.gz ${fastq_1}
    curl -L --retry 3 --retry-delay 5 -o ${sample}_2.fastq.gz ${fastq_2}
  else
    wget -O ${sample}_1.fastq.gz ${fastq_1}
    wget -O ${sample}_2.fastq.gz ${fastq_2}
  fi
  """
}
