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

## Execution mode

Blahaj has two execution modes:

- **Normal** is the default. The user authorizes the outcome explicitly through
  the request, and Blahaj stops at that boundary.
- **Autonomous** is selected only when the user explicitly requests autonomous
  execution or when another explicit entry point, currently `djungelskog-mode`,
  invokes Blahaj in autonomous mode. The task route stays the same; autonomous
  mode changes persistence within the agreed task, not permission to publish.

Both modes use the same routes, playbooks, and verification gates.

Autonomous mode never authorizes merging, releasing, deploying, destructive
external actions, or any other irreversible operation that is not already
explicitly authorized. Negative constraints always win.

## First progress update

Emit exactly one routing line before doing substantive work:

- `Route: <task-kind> -> <outcome>` when an implemented route matches.
- `Route: none` when no registered route matches and the normal leaf skills run.

Do not claim a route that is not present in
[`references/routes.json`](references/routes.json). Do not invent a playbook or
silently substitute a nearby route.

## Resolve authorization and outcome

Honor negative constraints first. A request that says not to edit, not to open
an MR, not to contact reviewers, or not to contact an external system lowers
what the run may do regardless of execution mode.

In normal mode, resolve the strongest explicitly requested outcome:

1. Read-only questions default to `answer`.
2. Requested code changes default to `local-change`.
3. Explicitly opening, creating, or updating a PR/MR selects `mr-open`.
4. Explicitly babysitting, getting green, or reaching merge-ready selects
   `merge-ready`.

Never infer an external-write outcome in normal mode from a ticket, branch,
remote, or the fact that code changed.

In both modes, the requested outcome is the **authority ceiling**. Saying
"autonomously" alone does not authorize publishing. Explicitly invoking
`djungelskog-mode` opts into delivery through `merge-ready` for an implementation
task unless the user selects a lower outcome. Lower that ceiling for constraints:

- no edits or read-only only -> `answer`;
- no PR/MR or no external writes -> `local-change`;
- no reviewer contact or no babysitting -> at most `mr-open`;
- otherwise -> the requested outcome (the wrapper's default is `merge-ready`).

An explicit lower outcome from the user also lowers the ceiling. Autonomous
mode never raises authority above an explicit constraint.

## Select one route

1. If the user names a route ID, use it only when that route can satisfy the
   authorized outcome or, in autonomous mode, an allowed outcome at or below
   the authority ceiling.
2. Otherwise, walk `routes` in registry order and choose the first matching
   entry. In normal mode its `allowedOutcomes` must contain the resolved
   outcome. In autonomous mode it must contain at least one outcome at or below
   the authority ceiling.
3. In autonomous mode, after selecting the route, choose its strongest allowed
   outcome at or below the ceiling in this order: `merge-ready`, `mr-open`,
   `local-change`, `answer`.
4. If no entry matches, keep `Route: none` and use the applicable leaf skills
   directly. Autonomous mode still obeys the same authority ceiling and may not
   invent an external-write tail for an unregistered route.

When a route is selected, copy its base playbook steps followed by the selected
outcome tail into the task list. Keep skipped steps visible with the reason.
Complete the base work before an outcome tail. Pass the original request,
acceptance criteria, route, outcome, constraints, existing authorization, and
current evidence to each callee. This task contract prevents a nested skill
from asking again for authority already supplied or widening the task.
Reviewer messages require explicit authorization from the request or a host
that permits the wrapper's explicit delivery contract to supply it. A selected
tail never overrides a host restriction on contacting others.

## Decision policy in both modes

Choose routine engineering details and finish authorized work in both modes.
Use the smallest amount of machinery that can settle the task well.

- Inspect repository evidence before choosing a solution. Follow an established
  local pattern when it satisfies the acceptance behavior.
- Route through `how` when runtime behavior, ownership, or layering is unclear,
  and through `why` when history or an existing decision could constrain the
  change.
- Route through `architect` in the playbook-selected mode when a consequential
  public boundary needs to be settled before implementation.
- Route through `arena` when at least two materially viable approaches remain
  and choosing the wrong one would cause substantial rework. Do not run Arena
  merely because autonomous mode is active.
- Choose ordinary reversible engineering decisions yourself. Prefer repository
  evidence, explicit acceptance behavior, established conventions, smaller
  blast radius, and simpler public surfaces over asking the user for taste.
- Continue fixing implementation, verification, CI, and review failures while
  they remain inside the selected route and authority ceiling.

Interrupt the user only when the decision cannot responsibly be derived from
available evidence or the run hits a real authority boundary: ambiguous product
semantics that change externally observable behavior, conflicting explicit
requirements, missing credentials or permissions, a safety boundary, or an
irreversible/destructive action outside the authorization. Batch related
questions when possible. Do not ask for routine implementation preferences.

Pause only the blocked action and continue independent work. A failed check is
work to resolve, not a reason to ask whether to continue. Honor declared budgets;
there is no implicit task-wide timeout. Follow `escalate` when materially
different attempts stop producing progress.

## Continuation

For work spanning interruptions or external waits, read
[`references/continuation.md`](references/continuation.md). Save the task
contract and next action at meaningful boundaries. On "continue" for a known
task, restore its original route and authorized outcome before selecting a new
route. Reconcile the checkpoint with trusted conversation history and current
files; cached state does not grant permission. Recheck stale evidence and reuse
the existing change request. Do not promise an unattended restart unless a
supported host scheduler has actually accepted it.

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
