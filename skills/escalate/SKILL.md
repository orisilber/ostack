---
name: escalate
description: "Stop-and-ask policy for autonomous agents: decides when to halt and ping the human instead of guessing. Triggers \"escalate\", \"should I ask the user\", \"blocked\". Not for general questions."
---

# Escalate

Autonomy is bounded. This skill is the boundary. When any rule below matches,
stop working and emit one ask. Never continue past a hard stop.

## Hard stops (always halt, no judgment calls)

- **Consequential operations**: changing credentials or permissions, charging or
  moving money, applying a production migration, changing live infrastructure,
  exposing secrets, deleting data outside the worktree, destructive database
  commands, or force-pushing a shared branch. Editing and locally testing the
  corresponding source files is not by itself a hard stop when the user asked
  for that change and no external operation is being performed.
- **Security findings**: exposed credentials, vulnerable dependency with known CVE,
  suspicious code in the diff.
- **Spend/time budget**: the session exceeded a budget the user or calling
  workflow actually declared. The declared budget and bounded window may come
  from a calling skill for a long-running workflow. Do not invent a 30-minute
  limit.
- **Scope wall**: task requires access you don't have (prod systems, third-party
  consoles, approvals).

## Soft stops (halt after N attempts, default N=3)

- Ambiguous requirement that survives N interpretations (after
  clarify-requirements already ran).
- Failing check you cannot fix in N rounds despite verify-changes discipline.
- Flaky infrastructure blocking progress in N distinct runs.
- Merge conflicts whose two sides express genuinely conflicting intent.

## Not escalation material (handle yourself)

Style preferences, naming, missing tests you can write, transient network errors
(retry once), docs gaps you can fill, anything reversible inside the worktree.

The default outside the stops above is to proceed, not to ask. On reversible work,
act, present the result, and let the human course-correct after the fact. That is
the **never-block-on-the-human** principle, and this skill is its only boundary.
An ask that could have been a diff wastes the human's turn. When the two pull
against each other, a hard stop always wins.

## The ask: format exactly once, batched

```
ESCALATION: <task/ticket ref>
Blocked: <one sentence, concrete>
Tried: <numbered list of what was attempted, one line each>
Options:
  A) <action>: <consequence> (recommended)
  B) <action>: <consequence>
Default if no answer: <what you will do and when you will do it>
```

Rules: max 2 options unless truly unavoidable; every option gets a consequence;
state what safe work can continue while waiting. A default is an assumption for
reversible work, never authorization for a hard-stop action; silence cannot grant
missing access or approval. Never re-ask an already-answered question (check
ticket + state file first).

## After the answer

Resume from persisted state, not from memory. When Git is the right store, resolve
the worktree-safe path with `git rev-parse --git-path <skill>-state.json` rather
than assuming `.git/` is a directory. If interrupted mid-work, the state file is
what makes the restart cheap.
