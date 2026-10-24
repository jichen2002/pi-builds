# Skills-only variant: vendored diagnosing-bugs and tdd from mattpocock/skills.
# The Skill text and companion files are pinned in this repository.
# No third-party Pi Extension or new tool is installed.
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

COPY docker/extensions/skills/skills/ /root/.pi/agent/skills/
COPY docker/extensions/skills/LICENSE.mattpocock /usr/share/doc/pi-builds-skills/LICENSE.mattpocock

RUN test -s /root/.pi/agent/skills/diagnosing-bugs/SKILL.md \
    && test -s /root/.pi/agent/skills/diagnosing-bugs/scripts/hitl-loop.template.sh \
    && test -s /root/.pi/agent/skills/tdd/SKILL.md \
    && test -s /root/.pi/agent/skills/tdd/tests.md \
    && test -s /root/.pi/agent/skills/tdd/mocking.md
