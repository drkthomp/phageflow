process MASH_DIST {
  tag sample
  publishDir { "${params.outdir}/${sample}/mash" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)
  path(refs_fasta)
  path(refs_accessions)

  output:
  tuple val(sample), path("${sample}.mash.dist.tsv"), path("${sample}.mash.closest.tsv"), emit: hits

  script:
  """
  set -euo pipefail

  if [[ -s "${refs_fasta}" ]]; then
    cp "${refs_fasta}" refs.fasta
  else
    : > refs.fasta
    while read -r accession; do
      [[ -z "\$accession" ]] && continue
      url="https://www.ncbi.nlm.nih.gov/search/api/sequence/\${accession}/?report=fasta&format=text"
      if command -v curl >/dev/null 2>&1; then
        curl -L --retry 3 --retry-delay 5 "\$url" >> refs.fasta || true
      else
        wget -qO- "\$url" >> refs.fasta || true
      fi
    done < "${refs_accessions}"
  fi

  if [[ ! -s refs.fasta ]]; then
    printf ">fallback_ref\nATGCGTACGTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTA\n" > refs.fasta
  fi

  mash sketch -o refs.msh refs.fasta
  mash dist refs.msh ${contigs} | sort -k3,3g > ${sample}.mash.dist.raw.tsv

  printf "reference\tquery\tdistance\tp_value\tshared_hashes\n" > ${sample}.mash.dist.tsv
  cat ${sample}.mash.dist.raw.tsv >> ${sample}.mash.dist.tsv

  printf "reference\tquery\tdistance\tp_value\tshared_hashes\n" > ${sample}.mash.closest.tsv
  head -n 1 ${sample}.mash.dist.raw.tsv >> ${sample}.mash.closest.tsv || true
  """
}
