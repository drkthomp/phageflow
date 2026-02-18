FROM mambaorg/micromamba:1.5.10

COPY --chown=$MAMBA_USER:$MAMBA_USER envs/nextflow-runtime.yml /tmp/nextflow-runtime.yml

RUN micromamba install -y -n base -f /tmp/nextflow-runtime.yml && \
    micromamba clean --all --yes

ENV NXF_HOME=/workspace/.nextflow
ENV NXF_WORK=/workspace/work
WORKDIR /workspace

ENTRYPOINT ["nextflow"]
