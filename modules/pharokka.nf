process PHAROKKA {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/pharokka" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)

  output:
  tuple val(sample), path("${sample}.pharokka.gff"), path("${sample}.pharokka.cds.faa"), path("${sample}.pharokka.summary.tsv"), emit: annotations

  script:
  def configuredDbDir = params.pharokka_db_dir ? params.pharokka_db_dir.toString() : ''
  """
  set -euo pipefail

  status="success"
  db_dir="${configuredDbDir}"
  pharokka_bin="$(command -v pharokka.py || true)"

  if [[ -z "${db_dir}" && -n "${pharokka_bin}" ]]; then
    db_dir="$(dirname "${pharokka_bin}")/../databases"
  fi

  markers_found=0
  if [[ -n "${db_dir}" && -d "${db_dir}" ]]; then
    if find "${db_dir}" -type f -name 'VERSION_1_8_0' | grep -q .; then
      markers_found=$((markers_found + 1))
    fi
    if find "${db_dir}" -type f -iname '*phrog*annot*' | grep -q .; then
      markers_found=$((markers_found + 1))
    fi
    if find "${db_dir}" -type f -iname '*inphared*annot*' | grep -q .; then
      markers_found=$((markers_found + 1))
    fi
    if find "${db_dir}" -type f -iname '*.msh' | grep -q .; then
      markers_found=$((markers_found + 1))
    fi
  fi

  if [[ ${markers_found} -ge 3 ]]; then
    set +e
    pharokka.py \
      -i ${contigs} \
      -o pharokka_out \
      -p ${sample} \
      -t ${task.cpus}
    pharokka_exit=$?
    set -e

    if [[ ${pharokka_exit} -eq 0 ]]; then
      cp pharokka_out/*.gff ${sample}.pharokka.gff
      cp pharokka_out/*.faa ${sample}.pharokka.cds.faa
    else
      status="failed_runtime"
      printf "##gff-version 3\n" > ${sample}.pharokka.gff
      : > ${sample}.pharokka.cds.faa
    fi
  else
    status="skipped_missing_db"
    printf "##gff-version 3\n" > ${sample}.pharokka.gff
    : > ${sample}.pharokka.cds.faa
  fi

  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "status\t%s\n" "${status}" >> ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\tNA\n" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
