# Spawn isolated pi subprocesses using Pi's official subagent example.
# Example agents' hard-coded Claude model selections are stripped, so each
# subagent inherits the calling session's model and thinking level.
# Workflow prompt templates are intentionally NOT copied.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG PI_SOURCE_COMMIT=4a080252f06caf63a525d7873c5d94d3c23887e0
ARG EXAMPLE_ROOT=https://raw.githubusercontent.com/earendil-works/pi

RUN mkdir -p /root/.pi/agent/extensions/subagent /root/.pi/agent/agents \
    && curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/subagent/index.ts" \
        -o /root/.pi/agent/extensions/subagent/index.ts \
    && curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/subagent/agents.ts" \
        -o /root/.pi/agent/extensions/subagent/agents.ts \
    && for agent in scout planner reviewer worker; do \
         curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/subagent/agents/${agent}.md" \
           -o "/root/.pi/agent/agents/${agent}.md" || exit 1; \
         sed -i '/^model: /d' "/root/.pi/agent/agents/${agent}.md"; \
       done \
    && test -s /root/.pi/agent/extensions/subagent/index.ts \
    && test -s /root/.pi/agent/extensions/subagent/agents.ts \
    && test "$(find /root/.pi/agent/agents -maxdepth 1 -name '*.md' | wc -l)" -eq 4
