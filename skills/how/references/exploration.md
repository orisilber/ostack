# Broad exploration

## Model resolution

Resolve `how explorer`, `how explainer`, and `how critics` from
`~/.cursor/rules/ostack-models.mdc`. For each role use its skill-role line
first, then its generic role line, then `inherit`.

| Role | Generic role |
|---|---|
| `how explorer` | `exploration` |
| `how explainer` | `prose` |
| `how critics` | `judgment` |

Explorer and explainer are single-agent roles. Each uses the first resolved
entry, or `inherit` when the host rejects it.

`how critics` is a panel. Run one subagent per resolved entry, so the entry
count sets the fan-out. If the host rejects an entry, drop it and run the
rest. Fall back to `inherit` only when nothing is left.

Pass the resolved value as the subagent `model` argument. `inherit` means omit
`model` and let the subagent run on the parent chat model. A line never mixes
`inherit` with a model ID. Hosts that do not load the rule resolve every role
to `inherit`. When the host rejects a model ID, do not swap in a nearby one. A
successful call proves nothing about which model ran, because the host may
substitute one without saying so.


Split a broad question into independent slices only when delegation saves time.
Use [explorer-prompt.md](explorer-prompt.md) with a concrete slice and the existing
grounding. Keep workers read-only and within the host's supported tool surface.
A parent can trace the whole flow when it is cohesive or workers are unavailable.

Read findings against source, resolve contradictions, and synthesize in the
parent. A separate explainer using [explainer-prompt.md](explainer-prompt.md) is
optional for a large body of findings. Stop once the requested flow is explained.
