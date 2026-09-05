# Broad exploration

## Model resolution

Read the canonical ostack configuration at
`$OSTACK_CONFIG_HOME/models.json`, or `~/.config/ostack/models.json` when the
variable is unset. Resolve `how.explorer`, `how.explainer`, and `how.critics`
from the exact override first, then the generic role (`exploration`, `prose`,
or `judgment`), then `inherit`. A missing, invalid, or empty configuration is
recoverable: report the fallback once and use `inherit`.

The explorer and explainer roles are single-agent roles, so use the first
resolved entry. Critics are a panel, so run every resolved entry once.
`inherit` must be the only entry when it is selected. If the host rejects one
configured entry, remove it and continue with the remaining entries; use
`inherit` only when none remain. Do not choose a nearby model ID, and do not
claim that a successful subagent call proves which model actually ran because
the host may silently substitute it.


Split a broad question into independent slices only when delegation saves time.
Use [explorer-prompt.md](explorer-prompt.md) with a concrete slice and the existing
grounding. Keep workers read-only and within the host's supported tool surface.
A parent can trace the whole flow when it is cohesive or workers are unavailable.

Read findings against source, resolve contradictions, and synthesize in the
parent. A separate explainer using [explainer-prompt.md](explainer-prompt.md) is
optional for a large body of findings. Stop once the requested flow is explained.
