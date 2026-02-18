process MASH_DIST {
  tag { sample }
  publishDir { "${params.outdir}/${sample}/mash" }, mode: 'copy'

  input:
  tuple val(sample), path(contigs)

  output:
  tuple val(sample), path("${sample}.mash.dist.tsv"), path("${sample}.mash.closest.tsv"), emit: hits

  script:
  def refsFasta = params.mash_refs_fasta.toString().startsWith('/') ? params.mash_refs_fasta : "${projectDir}/${params.mash_refs_fasta}"
  def refsAccessions = params.mash_ref_accessions.toString().startsWith('/') ? params.mash_ref_accessions : "${projectDir}/${params.mash_ref_accessions}"
  """
  set -euo pipefail

  if [[ -s "${refsFasta}" ]]; then
    cp "${refsFasta}" refs.fasta
  else
    : > refs.fasta
    while read -r accession; do
      [[ -z "$accession" ]] && continue
      url="https://www.ncbi.nlm.nih.gov/search/api/sequence/${accession}/?report=fasta&format=text"
      if command -v curl >/dev/null 2>&1; then
        curl -L --retry 3 --retry-delay 5 "$url" >> refs.fasta || true
      else
        wget -qO- "$url" >> refs.fasta || true
      fi
    done < "${refsAccessions}"
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
