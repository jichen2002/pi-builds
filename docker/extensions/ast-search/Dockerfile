# Structural search and rewrite with ast-grep.
# Disable the package's bundled Skill: this variant tests AST tools, not Skills.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG AST_GREP_VERSION=0.45.3
ARG AST_EXTENSION_VERSION=0.4.2

RUN npm install -g "@ast-grep/cli@${AST_GREP_VERSION}" \
    && ast-grep --version \
    && pi install "npm:@juvio15/pi-ast-grep@${AST_EXTENSION_VERSION}" \
    && node -e 'const fs=require("node:fs"); const path=require("node:path"); const file=path.join(process.env.HOME,".pi/agent/settings.json"); const settings=JSON.parse(fs.readFileSync(file,"utf8")); settings.packages=settings.packages.map(p=>{const source=typeof p==="string"?p:p.source; return source.startsWith("npm:@juvio15/pi-ast-grep@")?{source,skills:[]}:p}); fs.writeFileSync(file,JSON.stringify(settings,null,2)+"\n")'
