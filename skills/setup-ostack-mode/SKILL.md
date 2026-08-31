---
name: setup-ostack-mode
description: Configure the models used by ostack-mode's delegated roles. Triggers "configure ostack models", "set up ostack mode", or changing the ostack model configuration.
disable-model-invocation: true
---

# Setup ostack mode

Configure the one model file shared by ostack-mode and its model-aware leaf
skills. The canonical file is `models.json` under `$OSTACK_CONFIG_HOME` when
that variable is set, or `~/.config/ostack` otherwise. Never read, write, or
edit pstack's `~/.cursor/rules/pstack-models.mdc`; pstack owns that file.

## 1. Detect the host's model choices

Use the models exposed by the current host as the source of truth. Do not
invent a model ID, copy a slug from documentation, or guess a nearby model
when a host rejects one. `inherit` is always valid and means that the
subagent inherits the parent model. If the host cannot expose a model list,
offer `inherit` and model IDs the user explicitly supplies.

## 2. Read the current configuration

Resolve the path before reading it:

```text
config directory = $OSTACK_CONFIG_HOME when set
                  ~/.config/ostack otherwise
config file      = <config directory>/models.json
```

If the file is missing, invalid, or contains an empty model array, report one
recoverable configuration warning and use `inherit` for this run. Do not
silently reuse an old pstack configuration and do not overwrite an existing
valid file until the new candidate passes validation.

## 3. Ask for the four generic roles in one batch

Show the current value (or `inherit` when no valid value exists) and ask for
all four generic roles together:

- `exploration`: discovery and investigation workers
- `implementation`: implementation and bulk workers
- `judgment`: architecture, review, comparison, and critique panels
- `prose`: explainers and synthesis writers

Each role is an array with at least one entry. A single-agent role uses its
first entry. A panel role uses every entry once. Keep `inherit` as the only
entry in its array; it must not be mixed with model IDs. An explicit rejection
of one model entry removes that entry from a panel. Continue with the
remaining entries, and use `inherit` only when no entries remain. Never claim
that a successful delegation proves which model actually ran: the host may
silently substitute a model.

## 4. Offer advanced overrides only when appropriate

Do not burden a first-time setup with advanced choices. Offer overrides when
the existing configuration already has an `overrides` object, or when the
user explicitly asks for advanced per-skill settings. The supported keys are:

```text
architect.runners       arena.runners       arena.cross-judge
how.explorer            how.explainer       how.critics
interrogate.reviewers   swarm.workers       why.investigators
why.synthesizer
```

Use the same non-empty-array and `inherit` rules for overrides. An exact
skill-role override wins over its generic role; if it is absent, resolve the
declared generic role; if that is absent or unusable, resolve to `inherit`.

## 5. Validate the complete candidate

Before writing anything, validate the complete replacement as one document:

- top-level `version` is `1`;
- `roles` is an object containing the four generic role arrays;
- `overrides`, when present, is an object;
- every configured value is a non-empty array of unique, non-empty strings;
- no array combines `inherit` with another entry;
- every real model ID came from the current host or was explicitly supplied
  by the user.

If validation fails, explain the invalid field and ask for a corrected value.
Do not partially write a document.

## 6. Replace atomically

Create the destination directory if needed. Write the validated JSON to a
temporary file in the same directory, validate that temporary file again, and
replace `models.json` with an atomic rename. Remove the temporary file after a
failure. A failed directory creation, write, validation, or rename must leave
the previous valid file untouched; report the failure instead of deleting or
truncating it. Re-running setup is idempotent and replaces the whole document,
including stale overrides the user removed.

## 7. Confirm the result

Report the resolved path, the four generic roles, and any advanced overrides
that were written. State that missing or rejected entries fall back to
`inherit`, and that model identity is requested rather than confirmed unless
the host explicitly exposes the model that ran. Do not offer to change
pstack's configuration.
