# Example ostack model rule

`setup-ostack-mode` writes the live file to
`~/.cursor/rules/ostack-models.mdc`. Below is the shape it writes and the
canonical list of role labels the skills resolve against. A role resolves to
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
# A skill-role line (`how critics`) wins over its generic role (`judgment`).
exploration: gpt-5.6-sol-high
implementation: composer-2.5
judgment: gpt-5.6-sol-high
prose: cursor-grok-4.6-medium
architect runners: gpt-5.6-sol-high, cursor-grok-4.6-medium
arena runners: gpt-5.6-sol-high, cursor-grok-4.6-medium
arena cross-judge: gpt-5.6-sol-high, cursor-grok-4.6-medium
how explorer: gpt-5.6-sol-high
how explainer: cursor-grok-4.6-medium
how critics: gpt-5.6-sol-high, cursor-grok-4.6-medium
interrogate reviewers: gpt-5.6-sol-high, cursor-grok-4.6-medium
swarm workers: composer-2.5
why investigators: gpt-5.6-sol-high
why synthesizer: cursor-grok-4.6-medium
```

The slugs above are Cursor slugs and only an example. Run `setup-ostack-mode`
inside Cursor to write the slugs that session can really pass to a subagent.
