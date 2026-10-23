# Pi Coding Agent baseline: no extra third-party capabilities.
# Build first: docker build -f docker/baseline/Dockerfile -t pi-builds:baseline .
FROM node:24-bookworm-slim

ARG PI_VERSION=1.4.0

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git ripgrep \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && pi --version

WORKDIR /workspace
ENTRYPOINT ["pi"]
