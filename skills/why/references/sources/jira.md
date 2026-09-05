# Jira (issue / ticket tracker)

## What this source contains

- Work items: Story, Task, Bug / Production Bug, Sub-task, Epic
- Descriptions, acceptance criteria, comment threads, status history
- Parent/child hierarchy (Epic → Story → Sub-task) and issue links (Blocks, Relates, Duplicate, Problem/Incident)
- Labels that categorize motivation (`customer:*`, squad names, `incident-followup`, `perf-regression`)
- Sprint and board membership, priority, fix version
- Attachments: specs, screenshots, Confluence links

Best at the **product or business forcing function**: who asked, what deadline, which customer, which incident.

## Access, in order of preference

1. **Atlassian MCP**, if connected. Richest for search and for fields the CLI hides.
2. **`acli`**, always available once authenticated (`acli jira auth status`). No MCP needed, which is why an absent Jira MCP is *not* a reason to skip this category.
3. Jira REST via `curl` with an API token, only for fields `acli` won't return.

Never assume the category is unavailable without trying `acli` first.

## How to search it

Start from the ticket keys the code anchor already gave you (branch names, commit subjects, MR titles almost always carry `PROJ-1234`):

```bash
acli jira workitem view PROJ-1234 \
  --fields "summary,description,status,labels,priority,parent,issuelinks,fixVersions"
acli jira workitem comment list --key PROJ-1234
```

Then widen by text, by area, and by time window around the ship date:

```bash
# text search across summary + description + comments
acli jira workitem search --jql \
  'project = PROJ AND text ~ "\"rate limit\"" ORDER BY created DESC' \
  --fields "key,issuetype,status,summary" --limit 30 --csv

# what shipped around the merge date (bracket the window, don't guess)
acli jira workitem search --jql \
  'project = PROJ AND resolved >= "2026/01/01" AND resolved <= "2026/01/31" AND text ~ "upload"' \
  --fields "key,status,summary" --limit 30 --csv

# the epic's whole family, for parent-initiative framing
acli jira workitem search --jql 'parent = PROJ-1200' --limit 50 --csv

# everything linked to the ticket, including incident links
acli jira workitem link list --key PROJ-1234
```

JQL notes that save a re-run: `text ~` matches summary, description and comments;
quote phrases twice (`text ~ "\"exact phrase\""`); `statusCategory != Done` beats
listing statuses by name because status vocabularies differ per project; dates are
`yyyy/MM/dd`; `--limit` and `--fields` are token discipline, not decoration.

`--fields` on `search` only renders a fixed display set (key, type, status,
priority, assignee, labels, summary). Asking it for `created` or `resolved` errors
out with `field '<name>' is not allowed`. Filter by date in the JQL and read the
timestamp from `workitem view` for the one ticket that matters. `--json` on a
search returns the full field payload per issue and will bury your context.

The Jira↔GitLab bot posts a comment on the ticket the moment an MR mentions its
key, so `comment list` is usually the cheapest ticket→MR bridge there is. Check it
before searching GitLab by hand.

## What to bring back

- The ticket that motivated the change, quoted, with its key as the citation
- The parent epic's framing when the ticket alone reads as arbitrary
- Comment threads where scope was cut or expanded, and by whom
- Linked incidents or duplicate reports that show this was a recurrence
- Labels and customer references that name the external forcing function

## Failure modes

- **Ticket key in the commit but no such issue**: the project was renamed or the item was moved. Search `text ~ "PROJ-1234"` before calling it missing.
- **Description is one line and the work is large**: the real rationale is in comments or Confluence. Follow the links; don't conclude "undocumented."
- **Status history mistaken for rationale**: a transition to Done tells you when, never why.
- A null result is scoped evidence: report "no matching ticket found in the
  searched Jira scope" and include the query, time range, and permission limits.
  Do not infer that the change was never ticketed; renamed keys, indexing,
  pagination, and access gaps can all produce an empty result.
