nextflow.enable.dsl = 2

include { FETCH_FASTQ } from './modules/fetch_fastq'
include { FASTP } from './modules/fastp'
include { SPADES } from './modules/spades'
include { QUAST } from './modules/quast'
include { MASH_DIST } from './modules/mash'
include { PHAROKKA } from './modules/pharokka'

process REPORT {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/report" }, mode: 'copy'

  input:
  tuple val(sample), path(fastp_html), path(fastp_json), path(quast_tsv), path(quast_report), path(mash_dist), path(mash_closest), path(pharokka_summary)
  path(make_report_script)
  path(report_rmd)

  output:
  tuple val(sample), path("${sample}.report.html")

  script:
  """
  Rscript ${make_report_script} \
    ${sample} \
    ${fastp_html} \
    ${fastp_json} \
    ${quast_tsv} \
    ${quast_report} \
    ${mash_dist} \
    ${mash_closest} \
    ${pharokka_summary} \
    ${sample}.report.html \
    ${report_rmd}
  """

  stub:
  """
  set -euo pipefail
  printf '<html><body><h1>Report stub for ${sample}</h1></body></html>\n' > ${sample}.report.html
  """
}

workflow {
  channel
    .fromPath(params.input)
    .splitCsv(header: true)
    .map { row ->
      tuple(
        row?.sample?.toString()?.trim(),
        row?.fastq_1?.toString()?.trim(),
        row?.fastq_2?.toString()?.trim()
      )
    }
    .filter { sample, fastq1, fastq2 -> sample && fastq1 && fastq2 }
    .set { samples_ch }

  fetched = FETCH_FASTQ(samples_ch)
  qc = FASTP(fetched.reads)
  asm = SPADES(qc.reads)
  asm_qc = QUAST(asm.contigs)
  mash = MASH_DIST(
    asm.contigs,
    file(params.mash_refs_fasta.toString().startsWith('/') ? params.mash_refs_fasta : "${projectDir}/${params.mash_refs_fasta}"),
    file(params.mash_ref_accessions.toString().startsWith('/') ? params.mash_ref_accessions : "${projectDir}/${params.mash_ref_accessions}")
  )

  anno_summary_ch = channel.empty()

  if (params.run_pharokka) {
    phage_anno = PHAROKKA(asm.contigs)
    anno_summary_ch = phage_anno.annotations.map { sample, _gff, _faa, summary ->
      tuple(sample, summary)
    }
  } else {
    anno_summary_ch = asm.contigs.map { sample, _contigs ->
      tuple(sample, file("${projectDir}/assets/empty_pharokka_summary.tsv"))
    }
  }

  report_ch = qc.qc
    .join(asm_qc.metrics, by: 0)
    .join(mash.hits, by: 0)
    .join(anno_summary_ch, by: 0)

  REPORT(report_ch, file("${projectDir}/bin/make_report.R"), file("${projectDir}/assets/report.Rmd"))
}
