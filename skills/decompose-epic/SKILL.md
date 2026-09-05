---
name: decompose-epic
description: Split a Jira epic into atomic, conflict-free tickets with acceptance criteria and disjoint file scopes. Triggers "decompose epic", "break down ticket", "split into tasks". Not for claiming or implementing tickets.
---

# Decompose Epic

One epic in, N ready-to-claim tickets out. Quality bar: each ticket must be
completable in ONE agent session and parallel-safe.

Spec still in Confluence, not Jira? That's `spec-to-backlog` (Atlassian plugin),
then come back here to make its output agent-shaped.

## 1. Read the epic once

```bash
PROJECT_KEY="${PROJECT_KEY:-${EPIC%%-*}}"
acli jira workitem view "$EPIC" --fields "summary,description,labels,status,priority"
acli jira workitem search --jql "parent = $EPIC" \
  --fields "key,issuetype,status,assignee,summary" --limit 50 --paginate --csv
acli jira workitem comment list --key "$EPIC"
```

`search --fields` renders only a fixed display set: key, type, status, priority,
assignee, labels, summary. Anything else (`created`, `resolved`, `description`)
errors as `field '<name>' is not allowed`; read those per ticket with
`workitem view` instead.

Children already exist → you are *extending* a decomposition, not starting one.
Drain every page before drafting. If the provider cannot prove that the listing
is complete, report the inventory as incomplete and do not create tickets yet;
never rely on the first page to avoid duplicate scope.

If discussion is long, summarize it now and work from the summary. Never
re-read it later. Then explore the codebase enough to name real files and
modules per ticket. Guessing scopes from titles is how parallel agents collide.

## 2. Draft tickets (in memory, no API calls yet)

Each ticket needs:

- **Summary**: imperative, prefixed the way the project does it (`[FE]` / `[BE]`),
  implementable without reading the epic.
- **Description**: goal in 2–3 sentences, acceptance criteria as a CHECKLIST
  (each item objectively checkable), explicit out-of-scope line.
- **Scope**: the files and modules it touches, and must be disjoint across tickets.
  Shared foundations (types, API client, feature flag, util) become their own
  first ticket that the others depend on.
- **Dependencies**: which tickets must merge first. A DAG, kept shallow.
- **Type**: `Story` for behavior, `Production Bug` only for a real reported
  defect, `Sub-task` when the parent is a Story rather than an Epic. Match the
  types the project actually has; `acli jira project view` if unsure.
- **Size**: if you can't state the touched files, it's too big. Split.

## 3. Self-check before creating

Run this matrix against the draft:

1. Any two tickets touching the same file? → merge them, or extract a shared
   foundation ticket both depend on.
2. Can each be verified independently? If two only make sense together, they are
   one ticket.
3. Does any acceptance criterion need human judgment ("looks good", "feels
   fast")? Rewrite it into something checkable, or drop it.
4. Is there a final integration ticket (wiring + `e2e-verify`) if the pieces
   interact at runtime?
5. Does any ticket land in an `escalate` forbidden zone (auth, payments,
   migrations, infra)? Keep it in the plan, but mark it human-only so no agent
   claims it.

## 4. Show ONE approval table, then create

Present `# | summary | type | scope | depends on`. The user edits or approves
once unless the caller has already supplied explicit authorization to create
these children (for example, a trusted automation policy). The words "auto" or
"from a loop" alone do not grant a new external write.

Write each description to a file rather than inlining it. Jira descriptions are
multi-line and shell-quoting them is where this step breaks:

```bash
acli jira workitem create \
  --project "$PROJECT_KEY" --type Story --parent "$EPIC" \
  --summary "[FE] Add brand column to the prompts table" \
  --description-file /tmp/ticket-1.md \
  --label agent-ready --json
```

- `--parent` takes the Epic key for Story/Task children, or the Story key for
  `Sub-task` children. A rejected parent means the project's hierarchy differs:
  check with `acli jira workitem view "$EPIC" --fields issuetype` and adjust the
  child type instead of dropping the link.
- Many tickets, no per-ticket descriptions needed → one
  `acli jira workitem create-bulk --from-json tickets.json` pass, then a
  `workitem edit --description-file` per ticket. Slower than it looks; prefer the
  per-ticket create.
- Add `agent-priority` to the critical-path starter only.

Record dependency edges as real Jira links, not prose:

```bash
acli jira workitem link create --out "$BLOCKER" --in "$BLOCKED" --type Blocks --yes
```

`--out` is the ticket that blocks; `--in` is the one waiting. Getting these
backwards inverts the whole plan, so verify one edge with
`acli jira workitem link list --key "$BLOCKED"` before creating the rest.

## 5. Output

One summary block: created keys, the DAG as `<KEY>-1 → <KEY>-2` lines, and the
suggested parallel lanes (which tickets can run simultaneously). Nothing else.

`pick-next-task` picks these up from here. If the lanes matter, say so in the
epic as one comment. That's where the next session looks:

```bash
acli jira workitem comment create --key "$EPIC" --body-file /tmp/lanes.md
```

## Fallback: repos whose queue is GitLab issues

`glab issue view <iid>` to read, `glab issue create -t … -d … -l agent-ready` to
create, and `Depends on #<iid>.` in the description for edges (GitLab cross-links
automatically). Verify the output shape of those commands once on your GitLab
version before relying on them.
