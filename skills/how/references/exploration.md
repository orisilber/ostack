# Broad exploration

Trace the flow in the parent when it is cohesive. Split a broad question into
independent read-only slices only when parallel reading saves real time, or
when one slice would flood the main context with raw output.

Give each explorer [explorer-prompt.md](explorer-prompt.md), a concrete slice,
and the existing grounding. Explorers run on the parent model: omit the subagent
`model` argument unless the user named a model. Keep them read-only and within
the host's supported tool surface.

Read their findings against the source, resolve contradictions, and write the
explanation yourself. Stop once the requested flow is explained.
