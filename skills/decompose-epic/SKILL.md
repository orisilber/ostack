---
name: decompose-epic
description: Split a GitLab epic into atomic, conflict-free agent tickets with acceptance criteria and disjoint file scopes, and create them as issues. Triggers "decompose epic", "break down issue", "create backlog", "split into tasks". Use ONLY for epic→ticket decomposition, not for claiming or implementing tickets.
---

# Decompose Epic

One epic in, N ready-to-claim tickets out. Quality bar: each ticket must be
completable in ONE agent session and parallel-safe.

## 1. Read the epic once

Accept either a real GitLab epic (group-level) or an issue acting as epic
(labeled `epic`) — check which when resolving the ref. Read body + comments:

```bash
glab issue view <iid> -F json --jq '{title,description,labels}'
glab issue view <iid> -c 2>/dev/null | tail -60   # comments, capped
```

If discussion is long, summarize it before proceeding — never re-read it later.
Explore the codebase enough to name real files/modules per ticket; guessing
scopes from titles alone is how parallel agents collide.

## 2. Draft tickets (in memory, no API calls yet)

Each ticket needs:

- **Title**: imperative, `<type>: <what>` — implementable without reading the epic
- **Description**: goal (2–3 sentences), acceptance criteria as a CHECKLIST
  (each item objectively checkable), explicit out-of-scope line
- **Scope**: files/modules it touches — MUST be disjoint across tickets;
  shared foundations (types, utils, interfaces) become their OWN first ticket
  that others depend on
- **Dependencies**: which ticket iids must merge first (DAG, prefer shallow)
- **Size**: if you can't state the touched files, it's too big — split

## 3. Self-check before creating

Run this matrix mentally against the draft:

1. Any two tickets touching the same file? → merge them or extract a shared
   foundation ticket.
2. Can each be verified independently? If two tickets only make sense together,
   they are one ticket.
3. Does any acceptance criterion require human judgment ("looks good")?
   Rewrite it into something checkable or drop it.
4. Is there a final integration ticket (wiring + e2e) if the pieces interact?

## 4. Show ONE approval table, then create

Present: `# | title | scope | depends on` — user edits/approves ONCE (skip
approval entirely when invoked with "auto" / from a loop).

Create with:

```bash
glab issue create -t "<title>" -d "<description>" -l agent-ready
```

Then record dependency edges by adding to each description:
`Depends on #<iid>.` (GitLab cross-links automatically). Add `agent-priority`
label to the critical-path start.

## 5. Output

One summary block: created iids, the DAG as `a → b` lines, suggested parallel
lanes (which tickets can run simultaneously). Nothing else.
