args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 10) {
  stop('Usage: make_report.R <sample> <fastp_html> <fastp_json> <quast_tsv> <quast_report> <mash_dist> <mash_closest> <pharokka_summary> <output_html> <report_rmd>')
}

sample <- args[[1]]
fastp_html <- args[[2]]
fastp_json <- args[[3]]
quast_tsv <- args[[4]]
quast_report <- args[[5]]
mash_dist <- args[[6]]
mash_closest <- args[[7]]
pharokka_summary <- args[[8]]
output_html <- args[[9]]
report_rmd <- args[[10]]

rmarkdown::render(
  input = report_rmd,
  output_file = output_html,
  params = list(
    sample = sample,
    fastp_html = fastp_html,
    fastp_json = fastp_json,
    quast_tsv = quast_tsv,
    quast_report = quast_report,
    mash_dist = mash_dist,
    mash_closest = mash_closest,
    pharokka_summary = pharokka_summary
  ),
  envir = new.env(parent = globalenv())
)
