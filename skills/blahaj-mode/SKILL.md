---
name: blahaj-mode
description: Working agreement for engineering tasks. Settles how far the task may go, applies the bug, feature, and refactor proof gates, verifies, and stops at the authorized boundary. `/blahaj-mode deliver <task>` runs autonomously through a merge-ready PR/MR.
icon: paw
color: magenta
disable-model-invocation: true
---

# Blahaj Mode

Blahaj Mode is a working agreement, not a router. It fixes how far a task may
go, what proof each kind of change needs, and where to stop. Everything else is
ordinary engineering judgment.

## Outcome and authority

Before substantive work, emit one line: `Outcome: <outcome>`.

| Outcome | Allows |
|---|---|
| `answer` | Read-only work. No edits. |
| `local-change` | Edit and verify locally. No push, PR/MR, or other external write. |
| `mr-open` | Also commit, push, and open or update one PR/MR. |
| `merge-ready` | Also drive review and CI until the current head is ready to merge. |

Resolve the outcome from the request:

1. Questions default to `answer`.
2. Requested code changes default to `local-change`.
3. Explicitly opening, creating, or updating a PR/MR selects `mr-open`.
4. Explicitly babysitting, getting green, or reaching merge-ready selects
   `merge-ready`.

Never infer an external write from a ticket, branch, remote, or the fact that
code changed.

Negative constraints always win and lower the outcome: no edits or read-only
means `answer`; no PR/MR or no external writes means `local-change`; no
reviewer contact or no babysitting means at most `mr-open`.

No outcome authorizes merging, enabling auto-merge, releasing, deploying, or
another irreversible external action. Each needs its own explicit
authorization.

## Deliver mode

`/blahaj-mode deliver <task>` runs autonomously. For an implementation task it
raises the default outcome to `merge-ready`: research, choose the approach,
implement, verify, open the PR/MR, and address review and CI without routine
checkpoints. A question stays `answer`, and negative constraints still lower
the outcome.

Saying "autonomously" without `deliver` changes persistence only. Keep going
without check-ins, but stay at the outcome the request authorized.

## Decisions

Settle routine, reversible engineering choices yourself from repository
evidence and established local patterns. Follow `escalate` for when to ask,
what counts as a real boundary, and when repeated attempts stop earning
progress. A failed check is work to do, not a reason to ask.

Pass the original request, acceptance criteria, outcome, constraints, and
existing authorization to every skill you invoke, so a nested skill neither
asks again for authority already given nor widens the task. Contacting
reviewers needs explicit authorization from the request or deliver mode, and a
host restriction on contacting others always wins.

## Gates by kind of work

Use `how` when runtime behavior or ownership is unclear, and `why` when
history could constrain the change. Before introducing a new public boundary,
write the caller's usage and the types first, and check them against the
design red flags in the **principles** skill. Use `arena` only when the user
asks for competing implementations.

- **Question.** Answer from source and history with citations. No edits.
- **Bug.** Run only the reproduction phase of `reproduce-first`: the smallest
  deterministic check that fails for the reported reason. Weigh competing
  causes against evidence, fix the smallest one the evidence supports, run
  `verify-changes`, and report the failing-before and passing-after evidence.
- **Feature.** Name the data shape, boundary, and acceptance behavior. Build
  the whole accepted scope without adding or editing feature-specific tests;
  existing tests may run. Prove every acceptance behavior through the real UI,
  API, CLI, or integration path. Then run `feature-retention-tests`, the
  focused retention tests, and `verify-changes`. When the feature has at least
  two independently verifiable scopes after shared foundations, or cannot
  finish in one session, follow
  [references/large-feature.md](references/large-feature.md).
- **Refactor.** Pin current behavior when it is unclear or an external
  contract could move. Remove dead weight before adding structure, migrate
  every caller and delete the old shape in the same change, and prove
  equivalence with `verify-changes`. Split out any discovered feature or bug.
- **UI or visual change.** Prove it through `e2e-verify`. For visual parity,
  capture labeled baseline and result screenshots of the same states.
- **Resume.** Follow [references/session-pickup.md](references/session-pickup.md).
- **Pause.** Stop at an atomic boundary, never halfway through a write,
  commit, or external request. Save a paused checkpoint through
  [references/continuation.md](references/continuation.md), disable any
  schedule created for the task, and report what remains in flight. Pausing
  never discards changes, deletes a worktree, or closes a PR/MR.

Other work needs no gate beyond verification.

## Comments

Do not write comments that narrate what code does, justify a workaround, or
keep commented-out code. Keep a comment only for a legal header, a public API
contract, an issue link for a constraint code cannot express, or behavior
forced by something outside the codebase. Reshape surprising code of our own
instead of explaining it. `no-comments` cleans up an existing diff on request.

## Verification and delivery

Run `verify-changes` whenever work changes files, and report the exact checks
and results. Never report a check you did not watch finish.

For `mr-open` and `merge-ready`, follow
[references/opening-an-mr.md](references/opening-an-mr.md) once verification
passes. For `merge-ready`, continue with
[references/merge-ready.md](references/merge-ready.md). When an outcome would
need an unauthorized write, stop at the safe boundary and say what remains.

## Continuation

For work spanning interruptions or external waits, follow
[references/continuation.md](references/continuation.md). On "continue" for a
known task, restore its original outcome and constraints first; a checkpoint
never grants permission. Do not promise an unattended restart unless a host
scheduler has actually accepted it.

## Models

Subagents run on the parent model: omit the subagent `model` argument. Use a
different model only when the user names one in the request, for the role it
was named for. If the host rejects it, say so and continue on the parent model.
