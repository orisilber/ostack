# Example ostack model rule

`setup-blahaj-mode` writes the live file to
`~/.cursor/rules/ostack-models.mdc`. Below is the shape it writes and the
generic defaults. Optional role labels appear below. A role resolves to
its skill-role line, then its generic role line, then `inherit`. A host that
does not load the rule resolves every role to `inherit`.

```
---
description: ostack per-role model choices
alwaysApply: true
---
# ostack model configuration. One line per role. Delete a line to fall back to
# the generic role line, or to `inherit` when that is absent too.
# `inherit` as a value: the role runs on the parent chat model (omit the
# subagent `model` argument). `inherit` cannot be mixed with a model ID on the
# same line.
exploration: inherit
implementation: inherit
judgment: inherit
prose: inherit
```

Run `setup-blahaj-mode` inside Cursor to select models that host can pass to a
subagent. Keep exact overrides absent unless a role should differ from its
generic default. Even an exact `inherit` override masks a changed generic role.

| Optional override | Generic fallback |
|---|---|
| `architect runners` | `judgment` |
| `arena runners` | `judgment` |
| `arena cross-judge` | `judgment` |
| `how explorer` | `exploration` |
| `how explainer` | `prose` |
| `how critics` | `judgment` |
| `interrogate reviewers` | `judgment` |
| `swarm workers` | `implementation` |
| `why investigators` | `exploration` |
| `why synthesizer` | `prose` |

For example, add `how critics: <confirmed-model>, <another-confirmed-model>`
only for an intentional critic override. Architecture and arena candidate count
comes from the requested design directions; the model list supplies available
models and can be reused for multiple candidates.
