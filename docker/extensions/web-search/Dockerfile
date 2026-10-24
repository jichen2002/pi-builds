# Pi Coding Agent + pi-web-access. Only web_search is enabled by default.
# Select the search backend at runtime with a mounted web-search.json.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG WEB_ACCESS_VERSION=0.44.0

RUN pi install "npm:pi-web-access@${WEB_ACCESS_VERSION}" \
    && test -s /root/.pi/agent/settings.json

COPY docker/extensions/web-search/web-search.json /root/.pi/agent/web-search.json

# Catch invalid config during image construction without needing an API key.
RUN node -e 'const fs=require("node:fs"); const c=JSON.parse(fs.readFileSync("/root/.pi/agent/web-search.json","utf8")); if(c.provider!=="auto" || c.webSearch.allowedProviders!==undefined || c.toolActivation!=="eager" || c.workflow!=="none" || !c.tools.webSearch.enabled || Object.entries(c.tools).some(([k,v])=>k!=="webSearch"&&v.enabled)) process.exit(1)'

# Do not bake provider credentials into the image. Supply runtime environment
# variables and optionally bind-mount /root/.pi/agent/web-search.json.
