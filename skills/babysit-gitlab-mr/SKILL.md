---
name: babysit-gitlab-mr
description: Babysit a GitLab merge request end-to-end using glab CLI — find or create the MR from a URL or current branch, drive the review bot by commenting "!review", fix or push back on review comments in a loop until the bot approves, verify all non-optional CI pipeline jobs pass, then optionally enter watch mode polling for human comments until approval. Triggers: "babysit mr", "babysit this mr", "run review loop", "!review", "watch my merge request", "gitlab pipeline check". Use ONLY for GitLab MR babysitting workflows, not GitHub PRs.
---

# Babysit GitLab MR

Drive one MR through the review-bot loop and green pipeline, hands-off. This is a
long-running task: every wasted token is multiplied by dozens of iterations. The
rules below are not optional.

## Hard token-efficiency rules

1. **Never dump raw JSON or full diffs/logs.** Always project with `--jq` and cap
   with `head`/`tail`. If output would exceed ~50 lines, you projected wrong.
2. **Block, don't busy-poll.** Waiting for comments/CI = ONE bash call that loops
   internally with `sleep` and returns only when there is news or timeout. Never
   spend LLM turns checking "anything yet?".
3. **Persist state** in `.git/babysit-mr-state.json` (inside `.git`, never
   committed). Read it once at phase start, write it after changes. Never re-read
   it between consecutive tool calls in the same turn.
4. **Chain commands** with `&&` into single bash calls. One step = one call.
5. **Summarize before acting**: reduce each review round to a compact table of
   threads (id / author / verdict: FIX|REJECT / one-line gist) in your working
   memory. Work from the summary, not repeated API reads.
6. Commits are terse (`fix: address review: X, Y`). Push silently.

## State file

```json
{ "mr_iid": 0, "project_id": "", "branch": "", "me": "", "last_seen_note": 0,
  "round": 0, "mode": "", "bot_usernames": [], "done_marker": "" }
```

Create/update it with a single `cat > .git/babysit-mr-state.json <<'EOF'` call.
If resuming an interrupted run, rebuild missing fields from `glab mr view`.
Capture `me` once via `glab api user --jq .username`.

## Phase 0 — Resolve the MR

- User gave a URL: extract project path + IID from it.
- Otherwise derive from the current branch:
  `glab mr view <branch> -F json --jq '{iid,project_id,web_url,state}'`
  (empty result ⇒ no MR exists).
- If none: `git push -u origin HEAD` then
  `glab mr create --fill --fill-commit-body --source-branch <branch> --yes`
  (never interactive prompts; if `--fill` fails because branch is pushed, drop it).
- Record `mr_iid`, `project_id` (numeric), `branch` in state.
- Detect the review bot: from existing bot comments or project CI config
  (e.g. a reviewer bot username). Store in `bot_usernames`. Ask the user only if
  genuinely ambiguous.

Self-hosted GitLab: export `GITLAB_HOST=<host>` once at session start if
`glab repo view` fails against gitlab.com defaults.

## Phase 1 — Review loop

Round structure:

1. Kick off: `glab mr note <iid> -m '!review'` (skip re-posting if the previous
   round already triggered this exact push — track via `round` vs latest commit SHA).
2. **Wait for review comments** — one blocking call (~10 min budget), repeat as needed.
   Payload shape per discussion: `{id, individual_note, notes:[{body, system,
   author:{username}}]}`. Verify the query once on the first call, then freeze it.
   Exclude `$ME` (your own `!review` notes and replies) and system notes —
   everything else counts, including the bot:

```bash
# ME='orisilber'; LAST=123   # last_seen_note from state file
for i in $(seq 1 20); do
  OUT=$(glab api "projects/$PROJECT_ID/merge_requests/$MR_IID/discussions?per_page=100&sort=asc" \
    --jq "[.[] | select(any(.notes[]; .system | not)) | select(any(.notes[]; .author.username != \"$ME\" and .id > $LAST)) | {disc: .id, nid: ([.notes[].id] | max), by: (.notes | map(select(.author.username != \"$ME\" and .id > $LAST)) | last | .author.username), text: ((.notes | map(select(.id > $LAST) | .body)) | join(\" || \"))[0:400]}]")
  [ -n "$OUT" ] && [ "$OUT" != "[]" ] && [ "$OUT" != "null" ] && { echo "$OUT"; exit 0; }
  sleep 30
done
echo NO_CHANGE
```

   Note: discussion `id` is an opaque string — always use max numeric **note id**
   (`nid`) as the "last seen" cursor. Trigger rule = a non-system note from
   someone other than you with id > LAST (so your own replies never re-trigger).

   On `NO_CHANGE`: re-check that the bot actually ran (pipeline status); if the
   bot never started, investigate CI, do NOT spam more `!review` comments — max
   2 nudges total, then report to user.
3. **Triage each thread** → verdict per thread:
   - `FIX`: valid issue. Make the code change.
   - `REJECT`: wrong/preference/out-of-scope. Reply on the thread with a concrete
     technical justification (file paths, behavior, constraints — 1–3 sentences,
     no fluff), then resolve it:
     `glab api -X PUT "projects/$PID/merge_requests/$IID/discussions/$DISC_ID" -f resolved=true`
   - Ambiguous/breaking user intent: batch ambiguous threads, ask the user ONCE
     per round (not per thread).
4. Apply all FIXes in one pass. Run lint/typecheck/tests if the repo defines them.
5. Commit (`fix: address review round N: <topics>`) and push.
6. Update `last_seen_note` to the highest note id seen; increment `round`; write state.
7. Comment `!review` again. Go to 2.

**Loop exit**: latest bot response reports clean/approved (match markers like
"no issues|all clear|LGTM|approved|✅" — confirm the bot's actual wording on the
first round and reuse exactly that) AND zero unresolved actionable threads.
Cap: 15 rounds, then stop and report.

## Phase 2 — Pipeline gate

Do not trust the bot's word alone. Walk the pipeline:

1. Find head pipeline:
   `glab ci list --ref <branch> -F json --jq '[.[] | select(.sha=="'<latest_sha>'")][0] | {id,status}'`
2. **Wait for completion** with the same one-blocking-call pattern:
   poll `--jq .status` every 30s until `success|failed|canceled`, 20 min budget.
3. Enumerate jobs:
   `glab api "projects/$PID/pipelines/$PIPE_ID/jobs?per_page=100" --jq '[.[] | {name,stage,status,allow_failure}] | map(select(.allow_failure | not))'`
4. Every non-optional job must be `success`. Any failure:
   pull ONLY the tail of the log
   (`glab api "projects/$PID/jobs/$JOB_ID/trace" | tail -40`), diagnose, fix,
   commit, push → this re-enters Phase 1 (new commit may draw new review).
   Retry-once is allowed only for obvious flakes (network timeouts, runner lost).
5. Gate passes when: pipeline `success` AND all non-optional jobs `success`.

## Phase 3 — Report, then offer watch mode

Report concisely: MR url, rounds used, what was fixed vs rejected, pipeline status.

Then ask the user whether to enter **watch mode**: poll periodically for new
human comments and handle each (FIX or REJECT per Phase-1 rules), pushing and
re-commenting `!review` after fixes, over and over until the MR is **approved**
or the user says stop.

Watch mode = the same wait-loop, but filtering to **human** authors only
(`select(.notes[0].author.username as $u | ($BOTS + [$ME] | index($u)) | not)`),
with an approval check folded into each poll:

```bash
--jq '{comments: <new human discussions>, approved: <approval state>}'
```

Wake only on news; otherwise sleep inside the script. Between wake-ups, emit one
line per action taken, nothing else. Exit watch mode on approval, MR close/merge,
or explicit user stop. Check in with the user at least every hour even if quiet
(single-line status).

## Failure handling

- glab auth error → tell user to run `glab auth login`, stop.
- Branch pushed by someone else mid-run → `git pull --rebase`, re-run affected phase.
- Bot silent > 30 min despite pipeline success → report to user instead of looping.
- Any point: user interrupt wins immediately; leave a one-line summary of where
  the loop stopped so it can resume from the state file.
