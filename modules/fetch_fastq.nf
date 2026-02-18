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

  fetch_url() {
    url="$1"
    out="$2"
    if command -v curl >/dev/null 2>&1; then
      curl -L --retry 3 --retry-delay 5 -o "$out" "$url"
    else
      wget -O "$out" "$url"
    fi
  }

  fetch_url "${fastq_1}" "${sample}_1.fastq.gz"
  fetch_url "${fastq_2}" "${sample}_2.fastq.gz"
  """
}
