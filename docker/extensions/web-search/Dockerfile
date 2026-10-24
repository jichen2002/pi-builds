# Pi Coding Agent + pi-web-access. Only web_search is registered and
# DeepSeek is the only allowed search provider. Key is supplied at runtime.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG WEB_ACCESS_VERSION=0.44.0

RUN pi install "npm:pi-web-access@${WEB_ACCESS_VERSION}" \
    && test -s /root/.pi/agent/settings.json

COPY docker/extensions/web-search/web-search.json /root/.pi/agent/web-search.json

# Catch invalid config during image construction without needing an API key.
RUN node -e 'const fs=require("node:fs"); const c=JSON.parse(fs.readFileSync("/root/.pi/agent/web-search.json","utf8")); if(c.provider!=="deepseek" || c.toolActivation!=="eager" || c.webSearch.allowedProviders.join(",")!=="deepseek" || !c.tools.webSearch.enabled || Object.entries(c.tools).some(([k,v])=>k!=="webSearch"&&v.enabled)) process.exit(1)'

# No DEEPSEEK_API_KEY ARG/ENV: pass -e DEEPSEEK_API_KEY only at runtime.
