process FASTP {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/fastp" }, mode: 'copy'

  input:
  tuple val(sample), path(read1), path(read2)

  output:
  tuple val(sample), path("${sample}.trimmed_1.fastq.gz"), path("${sample}.trimmed_2.fastq.gz"), emit: reads
  tuple val(sample), path("${sample}.fastp.html"), path("${sample}.fastp.json"), emit: qc

  script:
  def readsToProcess = params.max_reads && params.max_reads.toInteger() > 0 ? "--reads_to_process ${params.max_reads}" : ""
  """
  set -euo pipefail

  fastp \
    --in1 ${read1} \
    --in2 ${read2} \
    --out1 ${sample}.trimmed_1.fastq.gz \
    --out2 ${sample}.trimmed_2.fastq.gz \
    --html ${sample}.fastp.html \
    --json ${sample}.fastp.json \
    --thread ${task.cpus} \
    ${readsToProcess}
  """

  stub:
  """
  set -euo pipefail
  printf '@stub\nN\n+\n#\n' | gzip -c > ${sample}.trimmed_1.fastq.gz
  cp ${sample}.trimmed_1.fastq.gz ${sample}.trimmed_2.fastq.gz
  printf '<html><body><h1>fastp stub</h1></body></html>\n' > ${sample}.fastp.html
  printf '{"summary":{"before_filtering":{},"after_filtering":{}},"stub":true}\n' > ${sample}.fastp.json
  """
}
