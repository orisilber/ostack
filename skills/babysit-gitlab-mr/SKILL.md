---
name: babysit-gitlab-mr
description: "Drive a GitLab MR through bot review and its pipeline, or watch requested human feedback. Use for babysit MR, !review, or watch my merge request. GitLab only."
---

# Babysit GitLab MR

Resolve the requested MR and outcome first. A review-and-fix request authorizes
the relevant replies and fixes; a read-only status request does not. Create a
missing MR only when the user requested creation. A watch request selects watch
mode directly; do not make it wait for an unrequested bot-review workflow.

Resolve the GitLab host from the MR URL or remote, then the numeric
`PROJECT_ID`, `MR_IID`, source branch, authenticated username `ME`, and bot
usernames `BOTS` (a JSON array). Verify that the checkout belongs to this MR
before editing. Use the MR API's current `sha` as the remote head; local HEAD
alone cannot identify what a review or pipeline checked.

## Persist state per MR and worktree

After resolving IDs, set:

```bash
STATE_FILE="$(git rev-parse --git-path "babysit-$PROJECT_ID-$MR_IID.json")"
```

Persist `project_id`, `mr_iid`, branch, mode, `last_seen_note`, `round`,
bot identities, `review_sha`, `review_request_note_id`, and
`approved_sha`. Write atomically, validate identity on resume, and permit only
one coordinator per MR. Do not confuse another MR's state with this task.

## Read complete feedback

Use [scripts/list-pages.sh](scripts/list-pages.sh) to drain list endpoints.
It emits one combined array only after complete success. An API error, invalid
JSON, or page ceiling is a failed read, never `NO_CHANGE` or approval.

```bash
bash <babysit-skill>/scripts/list-pages.sh "projects/$PROJECT_ID/merge_requests/$MR_IID/discussions" > "$DISCUSSIONS"
jq --arg me "$ME" --argjson last "$LAST" --argjson bots "$BOTS" \
  --argjson humans_only false -f <babysit-skill>/scripts/new-notes.jq "$DISCUSSIONS"
```

`DISCUSSIONS` is a task-specific scratch file and `LAST` is the persisted
cursor. Run the filter only after the fetch succeeds. Use
[scripts/new-notes.jq](scripts/new-notes.jq) for both bot review and watch mode;
set `humans_only` to true for watching. Every predicate applies to the same
note. Results preserve each note's author, ID, full body, and commit metadata.
Summarize only after reading the complete body; never decide approval from a
400-character preview or combine two authors into one attributed message.

On resume, inspect unresolved actionable discussions as well as new notes.
Advance `last_seen_note` only after handling the returned notes and persisting
their outcomes. An initial cursor is a snapshot of existing notes, not permission
to discard unresolved work.

## Bind each review to its commit

1. Fetch the remote MR SHA. Before asking for review, ensure the intended commits
   are pushed and the local MR checkout matches that SHA.
2. Record that SHA as `review_sha`, clear `approved_sha`, and post the
   configured review trigger once. Persist the returned request note ID as
   `review_request_note_id`. If posting has an uncertain outcome, inspect
   recent notes before retrying.
3. Recheck the remote SHA after posting. If it changed, invalidate the request
   association and inspect the new head before proceeding.
4. Read and triage complete new feedback. Accept approval only from the configured
   bot with evidence binding it to this request and `review_sha`: an explicit
   reviewed SHA in the response/metadata, or a matching request/job identifier
   whose review job ran on that SHA. A later timestamp alone is insufficient,
   since a delayed response can belong to an older run. If the bot exposes no
   reliable binding, report review as unconfirmed instead of claiming approval.
5. Match the bot's actual clean verdict, not a loose `approved|✅` regex.
   Read qualifiers and findings in the full response. Record `approved_sha`
   only when the matching review is clean and no actionable threads remain.
6. Fix accepted findings, run `verify-changes`, commit, and push as authorized.
   Every push starts again at step 1, including state updates and a new request
   association. Do not keep the first round's SHA after later fixes.

For rejected findings, reply with concrete technical evidence before resolving
the discussion. Every thread reply must open with
`🤖 Automated reply: LLM agent working for @<me>:`.
Batch questions only when findings conflict with unresolved user intent.

Use bounded host waits or polling windows that remain interruptible. Inspect
whether the bot ran before nudging a silent bot; at most two nudges and 15 review
rounds, then report the blocker. Do not busy-poll or dump raw logs into context.

## Gate the same remote head

Fetch the MR's current SHA and enumerate branch pipelines completely using the
list helper. Choose the newest pipeline for that exact SHA and branch; no
matching pipeline means pending or blocked, never green.

Wait for terminal state within a bounded window (20 minutes by default), then
fetch its jobs using the same helper:

```bash
bash <babysit-skill>/scripts/list-pages.sh "projects/$PROJECT_ID/pipelines/$PIPE_ID/jobs" > "$JOBS"
jq '[.[] | {name,stage,status,allow_failure}]' "$JOBS"
```

Pipeline success and every required job's success are necessary. For repositories
using required child/downstream pipelines, follow their bridge jobs too. A failed
fetch or incomplete job list cannot pass the gate. Diagnose failures from the
saved full logs, fix within scope, and re-enter the review loop after any push.

Immediately before declaring merge-ready, fetch the MR SHA again and require
`remote SHA == review_sha == approved_sha == pipeline SHA`. If any differs,
invalidate the result and verify the current commit.

## Watch and stop

For requested human-feedback watching, reuse the note filter with
`humans_only=true` and the same cursor. An old human note plus a new bot or
system note is not new human feedback. Handle changes within the requested
authority, re-entering review after a fix when that outcome was requested.

Stop at the requested duration, approval of the current head, MR close/merge, or
user stop. Stay quiet when nothing actionable changes. Do not extend a watch
because a report happened to finish. Report the MR URL, fixes and rejections,
reviewed SHA, pipeline result, and any unconfirmed evidence.
