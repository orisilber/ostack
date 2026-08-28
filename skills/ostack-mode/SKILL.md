---
name: ostack-mode
description: Cursor-first orchestration for investigation, bug-fix, feature, and refactoring work. Classifies the requested outcome, selects only an implemented route, and stops at the authorized boundary.
disable-model-invocation: true
---

# Ostack Mode

Ostack Mode is a thin coordinator. It chooses a task kind and an outcome,
then makes the smallest applicable leaf-skill sequence visible to the user.
The route registry is the source of truth; read it before selecting a route.

## First progress update

Emit exactly one routing line before doing substantive work:

- `Route: <task-kind> -> <outcome>` when an implemented route matches.
- `Route: none` when no registered route matches and the normal leaf skills run.

Do not claim a route that is not present in
[`references/routes.json`](references/routes.json). Do not invent a playbook or
silently substitute a nearby route.

## Resolve the outcome before the task kind

Honor negative constraints first. A request that says not to edit, not to open
an MR, or not to contact an external system cannot select a write-capable tail.
Then resolve the strongest explicitly requested outcome:

1. Read-only questions default to `answer`.
2. Requested code changes default to `local-change`.
3. Explicitly opening or creating an MR selects `mr-open`.
4. Explicitly babysitting, getting green, or reaching merge-ready selects
   `merge-ready`.

Never infer an external-write outcome from a ticket, branch, remote, or the
fact that code changed. The selected outcome is the maximum this run may do.

## Select one route

1. If the user names a route ID, use it only when that route allows the
   resolved outcome.
2. Otherwise, walk `routes` in registry order and choose the first matching
   entry whose `allowedOutcomes` contains the resolved outcome.
3. If no entry matches, keep `Route: none` and use the applicable leaf skills
   directly.

When a route is selected, copy its base playbook steps followed by the selected
outcome tail into the task list. Keep skipped steps visible with the reason.
Complete the base work before an outcome tail. An MR or reviewer interaction is
never implicit.

## Empty-registry behavior

The initial registry intentionally contains no routes. In that state, emit
`Route: none`, select no playbook, and continue with the normal leaf-skill
workflow. This is a supported fallback, not an error.

## Verification boundary

Use `verify-changes` for repository checks when work changes files. Discover the
repository's own commands first; do not copy a command from this coordinator
into a playbook. If a requested outcome would require an external write that is
not authorized, stop at the safe boundary and explain what remains.

## Model configuration (reserved contract)

Model-aware leaf skills may read the canonical configuration at
`$OSTACK_CONFIG_HOME/models.json` or, when the variable is unset,
`~/.config/ostack/models.json`. Missing or invalid configuration falls back to
the host's inherited model and is reported once. A panel uses each configured
entry once; a single-agent role uses the first entry. `inherit` is never mixed
with another model ID. The example schema lives in
[`references/models.example.json`](references/models.example.json).
