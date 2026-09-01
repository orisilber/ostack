---
name: setup-blahaj-mode
description: Configure the models used by blahaj-mode's delegated roles. Triggers "configure ostack models", "set up blahaj mode", or changing the ostack model configuration.
disable-model-invocation: true
---

# Setup blahaj mode

Write `~/.cursor/rules/ostack-models.mdc`, an always-applied Cursor rule that
sets one model per ostack role. Always-applied is the whole point. The role
lines are in context when a skill fires, so no skill has to go read a file
before it can delegate.

A role with no line falls back to its generic role line, and a generic role
with no line falls back to `inherit`. An unconfigured ostack therefore
delegates on the parent model, which is what this skill exists to change.

Never read, write, or edit pstack's `~/.cursor/rules/` model rule; pstack owns
its own file and ostack owns `ostack-models.mdc`.

## Hosts other than Cursor

Only Cursor loads `.mdc` rules automatically. On any other host there is no
rule to load, so every role resolves to `inherit` and delegated work runs on
the parent model. Say so and stop. Write the rule from a non-Cursor host only
if the user explicitly supplies Cursor slugs to put in it.

## 1. Detect available models

Enumerate the model slugs you can pass to a subagent in this session. That is
the dependable source. Prefer a models API or CLI when the host has one, since
it lists everything the user is entitled to rather than everything you happened
to try. If you cannot detect any, ask the user to paste the slugs they have.

Never write a slug you have not confirmed. Do not copy one from documentation,
and do not reach for a nearby model when the host rejects your first choice.
`inherit` is the one value that is always valid without detection, and it runs
the subagent on the parent chat model.

## 2. Load current state

If `~/.cursor/rules/ostack-models.mdc` exists, read it and treat its values as
the current choices. Otherwise every role starts at `inherit`.

A `models.json` under `$OSTACK_CONFIG_HOME` or `~/.config/ostack` is a stale
configuration from an earlier ostack version. Nothing reads it anymore. Offer
its values as starting choices, tell the user the file is no longer consulted,
and leave it on disk; do not delete a file the user did not ask you to remove.

## 3. Map and confirm

Show every role with its current model, and flag any slug outside the detected
set as needing a choice. Then ask whether to keep the set as-is or change
specific roles, offering the detected models plus `inherit`. Use a question
tool rather than free text, and ask for every role in one batch instead of one
prompt per role.

The four generic roles cover every delegation:

- `exploration`: discovery and investigation workers
- `implementation`: implementation and bulk workers
- `judgment`: architecture, review, comparison, and critique panels
- `prose`: explainers and synthesis writers

The remaining lines are per-skill overrides of those four. Do not walk a
first-time setup through them. Offer them when the existing rule already sets
one, or when the user asks for per-skill control.

For panel roles (`architect runners`, `arena runners`, `how critics`,
`interrogate reviewers`) the value is a list and one subagent runs per entry,
so the list length sets the fan-out. `arena cross-judge` is also a list, but
arena picks one entry from it whose model family differs from the parent's
when possible. `swarm workers` is the model for every worker unless a race or
comparison assigns another model per arm.

## 4. Validate

Validate the complete rule before writing it:

- frontmatter sets `alwaysApply: true`;
- every line is a known role label followed by a comma-separated list;
- every list is non-empty and free of duplicate entries;
- no list mixes `inherit` with a model ID;
- every model ID came from the detected set or was explicitly supplied by the
  user.

A rule that points at a model the user cannot use breaks every delegation that
reads it. So stop and ask again rather than write an unvalidated slug. When
validation fails, name the bad line and ask for a corrected value. Never write
a partial rule.

## 5. Write the rule

Write the whole file so re-runs are idempotent and stale lines the user removed
actually disappear. A failed write must leave the previous rule untouched.
Report the failure instead of truncating it. The `blahaj-mode` skill keeps the
canonical role labels and a filled-in example under `references/`. The shape:

```
---
description: ostack per-role model choices
alwaysApply: true
---
# ostack model configuration. One line per role. Delete a line to fall back to
# the generic role line, or to `inherit` when that is absent too.
# `inherit` as a value: the role runs on the parent chat model (omit the
# subagent `model` argument). `inherit` cannot be mixed with a model ID.
exploration: <slug>
implementation: <slug>
judgment: <slug>
prose: <slug>
architect runners: <slug>, <slug>
arena runners: <slug>, <slug>
arena cross-judge: <slug>, <slug>
how explorer: <slug>
how explainer: <slug>
how critics: <slug>, <slug>
interrogate reviewers: <slug>, <slug>
swarm workers: <slug>
why investigators: <slug>
why synthesizer: <slug>
```

## 6. Confirm

Report the path you wrote and the roles in it, and say the rule takes effect in
new sessions. Say that a role with no line falls back to its generic role line
and then to `inherit`, and that `inherit` runs the role on the parent chat
model. Never claim a successful delegation proves which model ran. The host may
substitute one without saying so. Do not offer to change pstack's
configuration.
