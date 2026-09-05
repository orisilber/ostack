---
name: pick-next-task
description: Select and claim one agent-ready work item, create its branch, and return a handoff. Use for "pick next task" or "claim ticket"; implementation is a separate outcome.
---

# Pick next task

Return one claimed item with a usable branch and acceptance criteria. The
originating tracker owns selection, assignment, and decisions; resolve the code
host from the repository. Do not assume that every repository uses GitLab.

## Resolve the queue

Check authenticated tracker access and resolve the stable current-user account
ID from its identity endpoint or verified configuration. Store it as
`MY_ACCOUNT_ID`; email addresses and display names cannot replace an account
ID in ownership checks.

Use the project/team the user or repository named. Commit ticket prefixes can
suggest a project, but conflicting prefixes require disambiguation before a
write. Resolve `PROJECT_KEY`, `TEAM_FIELD`, and `TEAM` from repository/user
configuration (for example `OSTACK_JIRA_TEAM_FIELD` and `OSTACK_JIRA_TEAM`).
If the configured queue is project-wide, omit the team clause deliberately.
If a team restriction is required and unknown, ask instead of widening it.

Use a provider connector or installed CLI against the same site and project.
For Jira, read candidates using the resolved JQL:

```bash
acli jira workitem search --jql "$JQL" \
  --fields "key,issuetype,status,priority,labels,summary" --limit 30 --csv
```

Build JQL for unassigned, actionable items in the authorized project/team,
ordered by priority and age. Escape configured values for JQL. Use the project's
actual status and issue-type names.

Prefer `agent-priority`, then `agent-ready`, then a small, well-specified item.
Read the selected description and acceptance criteria before claiming. Skip
assigned, blocked, canceled, out-of-team, or underspecified work whose missing
intent cannot be resolved. Authorized changes to sensitive-area source files
are eligible; a production operation requiring missing authority is a dependency.

## Claim without inventing exclusivity

Prefer a provider-supported conditional claim and verify its exact account ID.
Ordinary assignment plus read-back is last-writer-wins: A can read A before B
assigns and reads B, so both can otherwise proceed.

If conditional claiming is unavailable, use a known single dispatcher or shared
claim lock covering all automated claimants of this queue. A local worktree
lock does not coordinate other hosts. Keep the claim recheck, assignment, and
confirmation inside that serialized operation. Without such a policy or
mechanism, return the selected candidate and explain that it cannot safely be
claimed concurrently; do not write an assignment.

Within the serialized fallback, re-read that the item is still unassigned and
actionable, assign once, and verify the exact account ID. Example for Jira's
`fields` JSON shape (confirm the installed provider's shape first):

```bash
acli jira workitem assign --key "$KEY" --assignee '@me' --yes
acli jira workitem view "$KEY" --fields assignee --json \
  | jq -e --arg id "$MY_ACCOUNT_ID" '.fields.assignee.accountId == $id'
```

Any failed request or mismatched/missing ID means no confirmed claim. Do not
transition, create a branch, or overwrite another claimant. A known dispatcher
serializes automated claims; it does not make human reassignment impossible.
Respect a later reassignment and stop work on that item.

After a confirmed claim, transition to the project's in-progress state if that
is part of its workflow. Do not guess a rejected transition's replacement.

## Prepare the branch

Inspect branch naming before choosing `BRANCH`:

```bash
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin
```

Use repository conventions, include the ticket key, and resolve the actual
remote default/base branch before switching. Protect existing local changes
with an isolated worktree when needed. Create the chosen branch from the
verified base. Only after creation succeeds, record its real name on the
originating item if comments were authorized:

```bash
acli jira workitem comment create --key "$KEY" \
  --body "Claimed by agent session. Branch: $BRANCH"
```

If branching fails after assignment, report the confirmed assignment and the
branching failure; do not pretend the item is ready or silently claim another.

## Handoff and stop

Return `Claimed <KEY>: <summary>`, the branch, acceptance criteria, unresolved
dependencies, provider identity, and the claim mechanism used. A selection-only
or empty-queue result says that no claim was made and includes the searched scope.

The caller owns implementation, `reproduce-first` for a bug, `verify-changes`,
and the requested review outcome. Use `babysit-gitlab-mr` only for GitLab and
only when that review outcome was requested. Do not implement, publish a PR, or
close the item merely because intake completed.

In batch mode, one dispatcher claims at most one item per run and then hands it
to a worker. Workers do not race each other through ordinary assignment.

For a GitLab issue queue, use the same policy and its provider's issue API.
Resolve the numeric current-user ID, preserve other assignees/labels, and verify
the exact ID after assignment. Use the originating provider for every later
comment and transition as well.
