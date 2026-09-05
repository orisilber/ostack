---
name: how
description: Explain a subsystem's behavior, runtime flow, and ownership. Use for "how does this work" or "which layer owns this"; load architectural critique only when requested.
---

# How

Trace the relevant input-to-output path and explain it with references to real
symbols and files. Resolve the target from the request and current context.
State a reasonable scope assumption when needed, and inspect only the contracts
that answer the question.

For a narrow question, read the relevant files and answer directly. Stop once
the flow and important decisions are supported by the source. Explain the
non-obvious parts; do not annotate every line or require a subagent.

For a broad subsystem with independent exploration angles, read
[references/exploration.md](references/exploration.md). Reuse any current
grounding supplied by the caller. Parallel exploration and a separate
synthesizer are useful options, not prerequisites.

For an explicitly requested architectural critique, read
[references/critique.md](references/critique.md) after establishing the behavior.
History and motivation questions route to the **why** skill.

Return the explanation at the user's requested depth: the main flow, ownership,
relevant source pointers, and material gotchas. Use
[references/explainer-prompt.md](references/explainer-prompt.md) for a substantial
structured explanation when that format helps.
