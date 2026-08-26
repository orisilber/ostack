---
name: pick-next-task
description: Claim the next unit of work from GitLab issues autonomously — filter by agent-ready criteria, assign self, create a branch, and hand off to implementation. Triggers "pick next task", "what should I work on", "claim ticket", "start next issue". Use ONLY for task acquisition from GitLab, not for doing or planning the work itself.
---

# Pick Next Task

Turn an empty queue into a claimed, branch-ready ticket.

## 1. Selection criteria (first match wins)

Query open issues, then pick by:

1. Label `agent-priority` (or highest priority label present)
2. Oldest issue with label `agent-ready`
3. Any unassigned issue that is small and well-specified

```bash
glab issue list --per-page 50 -F json \
  --jq '[.[] | select(.state=="opened") | {iid,title,labels:[.labels[].name],assignees:[.assignees[].username],created_at}]'
```

Filter in your head: assigned to someone else = skip; missing acceptance criteria
= skip unless you'll run clarify-requirements immediately after claiming.

## 2. Claim atomically (avoid two agents grabbing one ticket)

Get your numeric id once per session (`glab api user --jq .id`) → `$MY_ID`.
The **assignment is the claim** — first writer wins:

```bash
glab api -X PUT "projects/$PID/issues/$IID" -f "assignee_ids[]=$MY_ID"
```

If it fails because someone else got there first → back to step 1 silently.
Then add the label WITHOUT wiping existing ones (never use `--label`, it
replaces):

```bash
glab api -X PUT "projects/$PID/issues/$IID" -f add_labels=in-progress
```

Announce the claim with ONE line: `Claimed #<iid>: <title>`.

## 3. Branch convention

```bash
git fetch origin && git switch -c <type>/#<iid>-<slug> origin/<default-branch>
```

`<type>`: feat|fix|chore|test — inferred from the title. `<slug>`: 4–6 words,
kebab-case, from the title.

## 4. Handoff contract

After claiming, the flow is always:

1. `clarify-requirements` (if anything is ambiguous)
2. implement (`reproduce-first` first if it's a bug)
3. `verify-changes` before push
4. `babysit-gitlab-mr` for review + pipeline

Never skip 3 — the gate runs before every push, no exceptions.

## Batch mode

Invoked repeatedly (e.g. via `/loop`), this skill IS the intake pump: each run
claims at most ONE ticket and returns. Never claim several — parallel sessions
each claim their own.
