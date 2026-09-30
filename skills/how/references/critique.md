# Architectural critique

Reuse the explanation and traced source. Spawn one read-only critic that has
not seen your reasoning, and give it [critic-prompt.md](critic-prompt.md) and
[critique-rubric.md](critique-rubric.md). It runs on the parent model unless the
user named models; add one critic per named model as a second opinion. If the
host rejects a named model, say so and continue. If delegation is unavailable,
review locally and describe that limit.

Judge findings by concrete impact and source evidence. Separate actionable
issues, meaningful tradeoffs, and dismissed preferences. Agreement helps direct
attention but cannot establish correctness without evidence. Present the
explanation first, followed by the requested critique.
