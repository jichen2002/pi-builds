# Pi upstream examples, pinned to the same source revision as pi-coding-agent 1.4.0.
# The Todo tool works headlessly. The separate Plan Mode is opt-in via --plan
# or /plan and its plan-to-execution confirmation requires an interactive UI.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

ARG PI_SOURCE_COMMIT=4a080252f06caf63a525d7873c5d94d3c23887e0
ARG EXAMPLE_ROOT=https://raw.githubusercontent.com/earendil-works/pi

RUN mkdir -p /root/.pi/agent/extensions/plan-mode \
    && curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/todo.ts" \
        -o /root/.pi/agent/extensions/todo.ts \
    && curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/plan-mode/index.ts" \
        -o /root/.pi/agent/extensions/plan-mode/index.ts \
    && curl -fsSL --retry 3 "${EXAMPLE_ROOT}/${PI_SOURCE_COMMIT}/packages/coding-agent/examples/extensions/plan-mode/utils.ts" \
        -o /root/.pi/agent/extensions/plan-mode/utils.ts \
    && test -s /root/.pi/agent/extensions/todo.ts \
    && test -s /root/.pi/agent/extensions/plan-mode/index.ts \
    && test -s /root/.pi/agent/extensions/plan-mode/utils.ts
