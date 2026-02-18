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
  install_hint=""
  db_install_ran="false"
  db_dir="${configuredDbDir}"
  pharokka_bin="$(command -v pharokka.py || true)"

  if [[ -z "${db_dir}" && -n "${pharokka_bin}" ]]; then
    db_dir="$(dirname "${pharokka_bin}")/../databases"
  fi

  run_install_databases() {
    db_install_ran="true"
    set +e
    if [[ -n "${db_dir}" ]]; then
      install_databases.py --db_dir "${db_dir}" > install_databases.log 2>&1
      install_exit=$?
      if [[ ${install_exit} -ne 0 ]]; then
        install_databases.py >> install_databases.log 2>&1
      fi
    else
      install_databases.py > install_databases.log 2>&1
    fi
    set -e
  }

  if [[ -z "${db_dir}" || ! -d "${db_dir}" || ! -f "${db_dir}/VERSION_1_8_0" ]]; then
    run_install_databases
  fi

  set +e
  pharokka.py \
    -i ${contigs} \
    -o pharokka_out \
    -p ${sample} \
    -t ${task.cpus} > pharokka.log 2>&1
  pharokka_exit=$?
  set -e

  if [[ ${pharokka_exit} -ne 0 ]] && grep -q 'Please run install_databases.py' pharokka.log; then
    install_hint='The database directory was unsuccessfully checked. Please run install_databases.py.'
    run_install_databases
    set +e
    pharokka.py \
      -i ${contigs} \
      -o pharokka_out \
      -p ${sample} \
      -t ${task.cpus} >> pharokka.log 2>&1
    pharokka_exit=$?
    set -e
  fi

  if [[ ${pharokka_exit} -eq 0 ]]; then
    cp pharokka_out/*.gff ${sample}.pharokka.gff
    cp pharokka_out/*.faa ${sample}.pharokka.cds.faa
  else
    status="skipped_missing_db"
    printf "##gff-version 3\n" > ${sample}.pharokka.gff
    : > ${sample}.pharokka.cds.faa
  fi

  printf "metric\tvalue\n" > ${sample}.pharokka.summary.tsv
  printf "status\t%s\n" "${status}" >> ${sample}.pharokka.summary.tsv
  printf "db_install_attempted\t%s\n" "${db_install_ran}" >> ${sample}.pharokka.summary.tsv
  printf "db_dir\t%s\n" "${db_dir}" >> ${sample}.pharokka.summary.tsv
  printf "install_hint\t%s\n" "${install_hint}" >> ${sample}.pharokka.summary.tsv
  printf "predicted_proteins\tNA\n" >> ${sample}.pharokka.summary.tsv
  printf "gff_file\t%s\n" "${sample}.pharokka.gff" >> ${sample}.pharokka.summary.tsv
  """
}
