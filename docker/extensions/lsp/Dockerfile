# LSP-only experimental variant. pi-diet-lsp has no AST search, auto-diagnostics
# or Skill injection. Install language servers at build time, not by the agent.
ARG BASE_IMAGE=pi-builds:baseline
FROM golang:1.27-bookworm AS gopls-build
ARG GOPLS_VERSION=v0.24.0
RUN CGO_ENABLED=0 go install "golang.org/x/tools/gopls@${GOPLS_VERSION}"

FROM ${BASE_IMAGE}

ARG LSP_EXTENSION_VERSION=0.1.9

# gopls invokes the Go toolchain to inspect the target workspace.
COPY --from=gopls-build /usr/local/go /usr/local/go
COPY --from=gopls-build /go/bin/gopls /usr/local/bin/gopls
ENV PATH="/usr/local/go/bin:${PATH}"

# TypeScript/JavaScript, Python, and Go LSP servers (not automatic downloads).
RUN npm install -g --ignore-scripts \
      typescript@5.9.3 \
      typescript-language-server@5.3.0 \
      pyright@1.1.413 \
    && pi install "npm:pi-diet-lsp@${LSP_EXTENSION_VERSION}" \
    && command -v gopls \
    && command -v pyright-langserver \
    && command -v typescript-language-server
