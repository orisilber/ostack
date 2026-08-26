---
name: pick-next-task
description: Claim the next unit of work from Jira autonomously — filter by agent-ready criteria with acli/JQL, self-assign, move to In Progress, create the branch, and hand off to implementation. Triggers "pick next task", "what should I work on", "claim ticket", "start next issue". Use ONLY for task acquisition from Jira, not for doing or planning the work itself.
---

# Pick Next Task

Turn an empty queue into a claimed, branch-ready ticket. Jira is the queue;
GitLab is only where the work lands later.

## 0. Preconditions (once per session, then cache)

```bash
acli jira auth status                    # must print "✓ Authenticated" + site
```

Not authenticated → `acli jira auth login --web`, and if that fails, `escalate`
(scope wall: you can't grant yourself Jira access).

Resolve the project key from the repo instead of asking:

```bash
git log --oneline -100 | grep -oE '\b[A-Z]{2,6}-[0-9]+\b' \
  | cut -d- -f1 | sort | uniq -c | sort -rn | head -3
```

The dominant prefix is the project key (`DMI`, `LNX`, …). Two keys close in
count means the repo serves two teams — take the one the user named, else the
top one, and say which you picked in one line.

Host with the Atlassian MCP connected → use it for the *reads* in step 1 and
`acli` for every *write* in step 2. Never mix: a read through one path and a
write through the other is how you claim a ticket someone already took.

## 1. Selection criteria (first match wins)

```bash
acli jira workitem search --jql "$JQL" \
  --fields "key,issuetype,status,priority,labels,summary" --limit 30 --csv
```

Base `$JQL` — unassigned, actionable, mine to take:

```
project = DMI AND statusCategory != Done AND assignee IS EMPTY
  AND status IN (Open, Backlog) AND issuetype IN (Story, Task, "Production Bug", Sub-task)
  ORDER BY priority DESC, created ASC
```

Then pick, in order:

1. Label `agent-priority`.
2. Oldest with label `agent-ready`.
3. Highest `priority` (`Critical` > `High` > …) that is small and well-specified.
4. Oldest unassigned Sub-task under an epic already in flight — its siblings
   have proven the scope.

`agent-ready` / `agent-priority` are an opt-in convention. In a project that
hasn't adopted them, criteria 3 and 4 carry the whole selection, so the
well-specified test is doing real work: read the description before claiming.

Skip on sight: assigned to anyone, `status` in `Blocked`/`Cancelled`, a
`[Design]`/`[QA]` prefix that needs a human in a tool you don't have, an empty
description, or anything inside `escalate`'s forbidden zones (auth, payments,
migrations, infra). Missing acceptance criteria is not a skip if you run
`clarify-requirements` immediately after claiming — it IS a skip if nobody is
around to answer.

Read the one you chose in full before claiming:

```bash
acli jira workitem view "$KEY" --fields "summary,description,status,labels,parent,priority"
```

## 2. Claim atomically

Jira assignment is last-writer-wins, so assign and then **read back** — that
read is the claim check, not the write.

```bash
acli jira workitem assign --key "$KEY" --assignee '@me' --yes
acli jira workitem view "$KEY" --fields assignee --json | grep -i "$MY_EMAIL"
```

Read-back shows someone else → they got it, back to step 1 silently, no comment,
no complaint. Read-back shows you → take it out of the pool:

```bash
acli jira workitem transition --key "$KEY" --status "In Progress" --yes
acli jira workitem comment create --key "$KEY" \
  --body "Claimed by agent session. Branch: $BRANCH"
```

A rejected transition name (workflows differ per project) is not a failure:
list what the workflow actually offers, pick the closest in-flight status, and
say which you used. Never loop on it.

Announce with ONE line: `Claimed DMI-1234: <summary>`.

## 3. Branch convention

Match the repo's existing shape rather than inventing one:

```bash
git log --format='%(refname:short)' --all -50 2>/dev/null | head -20
git fetch origin && git switch -c "$BRANCH" "origin/$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d/ -f2-)"
```

Default when the repo has no clear pattern:
`<type>/<squad>/<KEY>-<slug>` — e.g. `bugfix/ravens/DMI-18844-asset-picker-chip-flicker`.

- `<type>`: `feature` for Story, `bugfix` for Production Bug, `fix`/`chore`/`test` otherwise. Use the commitlint types the repo actually allows.
- `<squad>`: a squad label on the ticket (`llamas`, `ravens`, `grizzlies`, `owls`, `lynx`). No squad label → drop the segment, don't guess.
- `<slug>`: 4–6 words, kebab-case, from the summary with `[FE]`/`[BE]` tags stripped.

The ticket key goes in every commit subject too: `fix(DMI-1234): <subject>`.
That link is what makes the MR traceable back to the queue.

## 4. Handoff contract

After claiming, the flow is always:

1. `clarify-requirements` (if anything is ambiguous) — post the questions as a
   Jira comment so the answer lands where the next session will look.
2. implement (`reproduce-first` first if it's a bug)
3. `verify-changes` before push
4. `babysit-gitlab-mr` for review + pipeline
5. On merge: `acli jira workitem transition --key "$KEY" --status "Done" --yes`
   only if the team's workflow says the developer closes it. Many teams close on
   QA, so check once and then respect it.

Never skip 3 — the gate runs before every push, no exceptions.

## 5. Failure to find anything

Empty result set is a real answer. Report `No agent-ready work in <KEY>` plus the
JQL you ran, and stop. Do not widen the filter until you find something claimable
— that's how an agent ends up rewriting the auth layer at 3am.

## Batch mode

Invoked repeatedly (e.g. via `/loop`), this skill IS the intake pump: each run
claims at most ONE ticket and returns. Never claim several — parallel sessions
each claim their own.

## Fallback: repos whose queue is GitLab issues

Same shape, different verbs: `glab issue list`, claim by
`glab api -X PUT "projects/$PID/issues/$IID" -f "assignee_ids[]=$MY_ID"`
(first writer wins there), add labels with `add_labels=` and never `--label`,
which replaces. Everything from step 3 on is identical.
