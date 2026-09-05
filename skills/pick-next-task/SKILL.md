---
name: pick-next-task
description: Claim the next Jira work item by agent-ready criteria, self-assign, branch, and hand off to implementation. Triggers "pick next task", "what should I work on", "claim ticket". Not for doing or planning the work itself.
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

The dominant prefix is the project key. Two keys close in count means the repo
serves two projects. Take the one the user named, else the top one, store it as
`$PROJECT_KEY`, and say which you picked in one line. If no key appears, ask for
the project instead of inventing one.

Resolve the team filter from repository or user configuration, for example
`OSTACK_JIRA_TEAM_FIELD` and `OSTACK_JIRA_TEAM`. Do not infer organization
names from a hardcoded list. If the project requires a team filter and no
configuration is available, ask once and cache the answer; do not silently widen
the search to another team's queue.

Resolve the current user's stable account ID from the authenticated provider
before the claim write and store it as `$MY_ACCOUNT_ID`. Use the provider's
identity endpoint or the account ID returned by its auth status command. If a
stable ID cannot be resolved, stop before claiming; an email or display name is
not a safe substitute for the read-back comparison.

Host with the Atlassian MCP connected → use it for the *reads* in step 1 and
`acli` for every *write* in step 2. Never mix: a read through one path and a
write through the other is how you claim a ticket someone already took.

## 1. Selection criteria (first match wins)

```bash
acli jira workitem search --jql "$JQL" \
  --fields "key,issuetype,status,priority,labels,summary" --limit 30 --csv
```

Base `$JQL`, unassigned, actionable, my team's, mine to take:

```
project = $PROJECT_KEY AND statusCategory != Done AND assignee IS EMPTY
  AND status IN (Open, Backlog) AND issuetype IN (Story, Task, "Production Bug", Sub-task)
  AND $TEAM_FIELD = '$TEAM'
  ORDER BY priority DESC, created ASC
```

`$TEAM_FIELD`/`$TEAM` come from step 0. A ticket outside your team doesn't
qualify, no matter how well it fits everything below.

Then pick, in order:

1. Label `agent-priority`.
2. Oldest with label `agent-ready`.
3. Highest `priority` (`Critical` > `High` > …) that is small and well-specified.
4. Oldest unassigned Sub-task under an epic already in flight. Its siblings
   have proven the scope.

`agent-ready` / `agent-priority` are an opt-in convention. In a project that
hasn't adopted them, criteria 3 and 4 carry the whole selection, so the
well-specified test is doing real work: read the description before claiming.

Skip on sight: assigned to anyone, `status` in `Blocked`/`Cancelled`, a
`[Design]`/`[QA]` prefix that needs a human in a tool you don't have, an empty
description, or anything inside `escalate`'s forbidden zones (auth, payments,
migrations, infra). Missing acceptance criteria is not a skip if you run
`clarify-requirements` immediately after claiming. It IS a skip if nobody is
around to answer.

Read the one you chose in full before claiming:

```bash
acli jira workitem view "$KEY" --fields "summary,description,status,labels,parent,priority"
```

## 2. Claim with an explicit race check

Assignment is last-writer-wins on many Jira installations; assign-and-read-back
is not atomic and cannot prove that another agent did not interleave a claim.
Prefer the provider's conditional/compare-and-set assignment when available.
Otherwise assign once, resolve the current user's stable account ID before the
write, read back the exact account ID, and abandon the ticket immediately if it
does not match. Report this as best-effort claiming, not atomic claiming.

```bash
acli jira workitem assign --key "$KEY" --assignee '@me' --yes
acli jira workitem view "$KEY" --fields assignee --json | jq -e --arg id "$MY_ACCOUNT_ID" '.assignee.accountId == $id'
```

Read-back shows someone else → they got it, back to step 1 silently, no comment,
no complaint. Read-back shows you → take it out of the pool:

```bash
acli jira workitem transition --key "$KEY" --status "In Progress" --yes
```

A rejected transition name (workflows differ per project) is not a failure:
list what the workflow actually offers, pick the closest in-flight status, and
say which you used. Never loop on it.

Announce with ONE line: `Claimed <KEY>: <summary>`.

## 3. Branch convention

Match the repo's existing shape rather than inventing one:

```bash
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin | head -20
git fetch origin && git switch -c "$BRANCH" "origin/$(git symbolic-ref --short refs/remotes/origin/HEAD | cut -d/ -f2-)"
```

After the branch exists, record the handoff on the originating ticket:

```bash
acli jira workitem comment create --key "$KEY" \
  --body "Claimed by agent session. Branch: $BRANCH"
```

Default when the repo has no clear pattern:
`<type>/<squad>/<KEY>-<slug>`, e.g. `bugfix/<team>/<KEY>-1234-asset-picker-chip-flicker`.
A `<KEY>/<slug>` variant (`fix/<team>/<KEY>-19024/negative-duration-url`) is equally
fine; the Jira↔GitLab bot links the MR off the key either way.

- `<type>`: `feature` for Story, `bugfix` for Production Bug, `fix`/`chore`/`test` otherwise. Use the commitlint types the repo actually allows.
- `<squad>`: the configured team label on the ticket. No team label → drop the segment, don't guess.
- `<slug>`: 4–6 words, kebab-case, from the summary with `[FE]`/`[BE]` tags stripped.

The ticket key goes in every commit subject too: `fix(<KEY>): <subject>`.
That link is what makes the MR traceable back to the queue: the Jira↔GitLab bot
sees the key and comments the MR onto the ticket, which is how the next session
finds the work without being told.

## 4. Handoff contract

After claiming, the flow is always:

1. `clarify-requirements` (if anything is ambiguous). Post the questions on the
   originating provider so the answer lands where the next session will look.
2. implement (`reproduce-first` first if it's a bug)
3. `verify-changes` before push
4. `babysit-gitlab-mr` for review + pipeline
5. On merge: `acli jira workitem transition --key "$KEY" --status "Done" --yes`
   only if the team's workflow says the developer closes it. Many teams close on
   QA, so check once and then respect it.

Never skip 3. The gate runs before every push, no exceptions.

## 5. Failure to find anything

Empty result set is a real answer. Report `No agent-ready work for team <TEAM>
in <KEY>` plus the JQL you ran, and stop. Do not widen the filter, team scope
included, until you find something claimable. That's how an agent ends up
rewriting the auth layer at 3am, or working another team's backlog uninvited.

## Batch mode

Invoked repeatedly (e.g. via `/loop`), this skill IS the intake pump: each run
claims at most ONE ticket and returns. Never claim several. Parallel sessions
each claim their own.

## Fallback: repos whose queue is GitLab issues

Same shape, different verbs: `glab issue list --label "$TEAM"` (reuse the
configured team label; GitLab tracks it as a label, not a field), claim by the
provider's conditional assignment when available. Resolve the authenticated
GitLab user's numeric ID once as `$MY_ID` before the write. A plain `glab api
-X PUT "projects/$PID/issues/$IID" -f "assignee_ids[]=$MY_ID"` is also
best-effort: read back the exact account ID and abandon on mismatch. Add labels
with `add_labels=` and never `--label`, which replaces. Everything from step 3
on is identical.
