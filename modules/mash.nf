process MASH_DIST {
  tag "${sample}"
  publishDir { "${params.outdir}/${sample}/mash" }, mode: 'copy', overwrite: true

  input:
  tuple val(sample), path(contigs)
  path(refs_fasta)
  path(refs_accessions)

  output:
  tuple val(sample), path("${sample}.mash.dist.tsv"), path("${sample}.mash.closest.tsv"), emit: hits

  script:
  """
  set -euo pipefail

  top_n=${params.mash_refine_top_n ?: 20}
  refine_k=${params.mash_refine_k ?: 17}
  refine_s=${params.mash_refine_s ?: 5000}

  : > refs.fasta

  if [[ -s "${refs_fasta}" ]]; then
    cp "${refs_fasta}" refs.fasta
  fi

  ref_bases=\$(awk '/^>/{next}{gsub(/[[:space:]]/, "", \$0); n+=length(\$0)} END{print n+0}' refs.fasta)

  if [[ \${ref_bases} -lt 50000 ]]; then
    : > refs.fasta
    while read -r accession; do
      [[ -z "\$accession" ]] && continue
      url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=\${accession}&rettype=fasta&retmode=text"
      if command -v curl >/dev/null 2>&1; then
        curl -L --retry 3 --retry-delay 5 "\$url" >> refs.fasta || true
      else
        wget -qO- "\$url" >> refs.fasta || true
      fi
    done < "${refs_accessions}"
  fi

  ref_records=\$(grep -c '^>' refs.fasta || true)
  ref_bases=\$(awk '/^>/{next}{gsub(/[[:space:]]/, "", \$0); n+=length(\$0)} END{print n+0}' refs.fasta)

  if [[ \${ref_records} -eq 0 || \${ref_bases} -lt 50000 ]]; then
    echo "ERROR: Mash reference set is insufficient (records=\${ref_records}, bases=\${ref_bases})." >&2
    echo "ERROR: Provide a valid refs.fasta or accession list with retrievable genomes." >&2
    exit 1
  fi

  mash sketch -i -o refs.msh refs.fasta
  mash dist refs.msh ${contigs} | sort -k3,3g > ${sample}.mash.dist.coarse.tsv

  cp ${sample}.mash.dist.coarse.tsv ${sample}.mash.dist.final.tsv

  if [[ -s ${sample}.mash.dist.coarse.tsv ]]; then
    head -n "\${top_n}" ${sample}.mash.dist.coarse.tsv > ${sample}.mash.top.tsv
    cut -f1 ${sample}.mash.top.tsv > ${sample}.mash.top.refs

    python - <<'PY'
from pathlib import Path

refs = {line.strip() for line in Path("${sample}.mash.top.refs").read_text().splitlines() if line.strip()}
in_fasta = Path("refs.fasta")
out_fasta = Path("refs.top.fasta")

keep = False
kept = set()
with in_fasta.open() as inp, out_fasta.open("w") as out:
    for line in inp:
        if line.startswith(">"):
            name = line[1:].strip().split()[0]
            keep = name in refs and name not in kept
            if keep:
                kept.add(name)
                out.write(line)
        elif keep:
            out.write(line)
PY

    if [[ -s refs.top.fasta ]]; then
      mash sketch -k "\${refine_k}" -s "\${refine_s}" -i -o refs_top_refined.msh refs.top.fasta
      mash dist -k "\${refine_k}" -s "\${refine_s}" refs_top_refined.msh ${contigs} | sort -k3,3g > ${sample}.mash.dist.refined.tsv

      if [[ -s ${sample}.mash.dist.refined.tsv ]]; then
        awk 'NR==FNR{top[\$1]=1; next} !(\$1 in top)' ${sample}.mash.top.refs ${sample}.mash.dist.coarse.tsv > ${sample}.mash.dist.non_top.tsv
        cat ${sample}.mash.dist.refined.tsv ${sample}.mash.dist.non_top.tsv | sort -k3,3g > ${sample}.mash.dist.final.tsv
      fi
    fi
  fi

  printf "reference\tquery\tdistance\tp_value\tshared_hashes\n" > ${sample}.mash.dist.tsv
  cat ${sample}.mash.dist.final.tsv >> ${sample}.mash.dist.tsv

  printf "reference\tquery\tdistance\tp_value\tshared_hashes\n" > ${sample}.mash.closest.tsv
  head -n 1 ${sample}.mash.dist.final.tsv >> ${sample}.mash.closest.tsv || true
  """

  stub:
  """
  set -euo pipefail
  printf "reference\tquery\tdistance\tp_value\tshared_hashes\n" > ${sample}.mash.dist.tsv
  printf "ref_stub\t${sample}.contigs.fasta\t0.0500\t1e-10\t100/1000\n" >> ${sample}.mash.dist.tsv
  cp ${sample}.mash.dist.tsv ${sample}.mash.closest.tsv
  """
}
