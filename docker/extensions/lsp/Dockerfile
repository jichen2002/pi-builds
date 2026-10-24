# Python-only LSP experiment for SWE-bench Verified.
# pi-diet-lsp provides on-demand LSP tools without auto-diagnostics or Skills.
# Install only Pyright; the benchmark case supplies its own Python runtime.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG LSP_EXTENSION_VERSION=0.1.9
ARG PYRIGHT_VERSION=1.1.413

RUN npm install -g --ignore-scripts "pyright@${PYRIGHT_VERSION}" \
    && pi install "npm:pi-diet-lsp@${LSP_EXTENSION_VERSION}" \
    && command -v pyright-langserver \
    && pyright --version
