---
name: blahaj-mode
description: Cursor-first orchestration for investigation, bug-fix, feature, and refactoring work. Classifies the requested outcome, selects only an implemented route, and stops at the authorized boundary.
icon: paw
color: magenta
disable-model-invocation: true
---

# Blahaj Mode

Blahaj Mode is a thin coordinator. It chooses a task kind and an outcome,
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

## Routed workflow skills

When a playbook routes through a workflow skill that owns delegation, invoke
that installed skill and follow the routed mode or phase completely. Do not
inline, imitate, or replace its procedure in the coordinator.

Routed workflow skills own their own subagent type, model selection, fan-out,
readonly behavior, and fallback semantics. In ostack this applies to skills
such as `how`, `why`, `architect`, `arena`, `interrogate`, and `swarm`, plus any
future skill whose contract explicitly owns delegated execution. Respect those
choices instead of substituting coordinator defaults.

A routed workflow may expose supported inputs that intentionally alter one of
its defaults for a nested call. A caller may pass only an override declared by
the callee's contract; the callee still owns resolution and execution. For
example, Arena may accept a runner-role override while retaining ownership of
candidate spawning, cross-judging, grafting, verification, and fallback
handling. Do not inject undeclared model, fan-out, or subagent overrides.

A playbook may explicitly scope a named skill to one mode or phase. In that
case, follow only that scoped portion and do not silently enter later phases of
the skill. Procedural leaf skills that do not own delegation are governed by
the exact playbook step that calls them; naming one does not automatically turn
its entire standalone workflow into the route.

If a required routed workflow skill cannot be resolved, report that failure
rather than silently doing the work in the parent agent. Optional conditional
steps may be skipped only when their playbook condition is false, with the skip
reason kept visible in the task list.

## Resolve feature size before route selection

Select `large-feature` instead of `feature` when the user asks to implement new
behavior and either condition is true:

- The work has at least two independently verifiable implementation scopes
  after shared foundations are separated.
- The complete change cannot reasonably finish in one agent session.

Judge the work shape after a short repository inspection. Do not infer size
from the prompt length or a raw file count. A request for only a plan remains a
`multi-phase-plan` request, even when the planned feature is large.

## Choose the exploration shape

Use `how` when the existing system is unclear but the target is known. Use
`arena` when the task is hard because the solution choice is uncertain, at
least two viable approaches exist, and committing to one approach would cause
substantial rework if it is wrong. An established local pattern or mechanical
change does not need an arena. A playbook may name narrower triggers for its
domain.

## Empty-registry behavior

If the registry contains no routes, emit `Route: none`, select no playbook, and
continue with the normal leaf-skill workflow. This is a supported fallback, not
an error.

## Verification boundary

Use `verify-changes` when work changes files. It runs declared repository checks
and prefers a matching project-local `verify-*` skill for affected user
behavior. It delegates browser mechanics to `e2e-verify`. Do not copy commands
or feature recipes into this coordinator. If a requested outcome would require
an unauthorized external write, stop at the safe boundary and explain what
remains.

## Review boundary

Before review, the `mr-open` and `merge-ready` outcome tails invoke
`no-comments` on the current branch diff. The parent applies accepted findings.
If that cleanup changes files after the base playbook's successful verification,
the opening-MR tail reruns `verify-changes` before any external write. Do not run
this gate for `answer` or `local-change` unless the user invokes it explicitly.

## Model configuration

Delegating skills run their subagents on configured models rather than always
inheriting the parent. `setup-blahaj-mode` writes that configuration to
`~/.cursor/rules/ostack-models.mdc` as an always-applied Cursor rule, so Cursor
loads its role lines into every session.

Resolve a role by taking its skill-role line (`how critics`), then its generic
role line (`judgment`), then `inherit`. Review panels run one reviewer per entry.
Architecture and arena choose candidate count from useful directions, assigning
available model entries to those candidates. A single-agent role uses the first
entry. A resolved `inherit` means omit the
subagent `model` argument and run on the parent chat model, and no line mixes
`inherit` with a model ID. When the host rejects an entry, drop it and run the
rest, falling back to `inherit` only when nothing is left. Do not swap in a
nearby model ID, and do not read a successful delegation as proof of which
model ran, because the host may substitute one without saying so.

Hosts other than Cursor do not load `.mdc` rules, so every role there resolves
to `inherit` and delegation runs on the parent model. This skill keeps the role
labels and a filled-in example under `references/`.
