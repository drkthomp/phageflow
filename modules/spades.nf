process SPADES {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/spades" }, mode: 'copy', overwrite: true

  input:
  tuple val(sample), path(read1), path(read2)

  output:
  tuple val(sample), path("${sample}.contigs.fasta"), emit: contigs

  script:
  """
  set -euo pipefail

  spades.py \
    -1 ${read1} \
    -2 ${read2} \
    -o spades_out \
    -t ${task.cpus} \
    --phred-offset ${params.spades_phred_offset}

  cp spades_out/contigs.fasta ${sample}.contigs.fasta
  """

  stub:
  """
  set -euo pipefail
  printf '>contig_1\nATGCGTACGTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAG\n' > ${sample}.contigs.fasta
  """
}
