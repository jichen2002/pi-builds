# Skill-only experimental variant. No executable Extension or third-party tool
# is added: Pi advertises this SKILL.md and loads its body only on demand.
# Requires Docker BuildKit (Dockerfile heredoc syntax).
# syntax=docker/dockerfile:1.7
ARG BASE_IMAGE=pi-builds:baseline
FROM ${BASE_IMAGE}

COPY <<'SKILL' /root/.pi/agent/skills/regression-debugging/SKILL.md
---
name: regression-debugging
description: Use for debugging failing tests, regressions, or unexpected runtime behavior in an unfamiliar codebase. Provides a reproducible evidence-first bug-fixing workflow.
---

# Regression debugging

Use this workflow when asked to fix failing tests or unexpected behavior:

1. Reproduce the failure with the narrowest available test or command. Save the exact failing output.
2. Locate the entry point and relevant implementation with the existing read and bash tools. Follow callers and data flow only as needed.
3. Form a testable hypothesis explaining the observed failure. Prefer the smallest change that addresses that cause.
4. Run the reproducer after editing. Then run nearby tests or targeted type checks to detect regressions.
5. Report the root cause, changed files, commands run, and any remaining uncertainty.

Do not claim a test passed unless you actually ran it. Avoid unrelated refactoring.
SKILL
