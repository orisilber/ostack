---
name: deploy-watch
description: "Watch a deployment's health after release: compare error/latency/uptime against baseline, roll back or alert per pre-authorized policy. Triggers \"watch the deploy\", \"post-deploy check\", \"monitor rollout\", \"set up deploy watch\". Not for triggering deploys, that's CI's job."
---

# Deploy Watch

The last mile of autonomy: notice breakage before users do, act within
pre-granted limits.

## 0. Load the watch contract (required before watching anything)

Per-project config in `AGENTS.md`, or a `deploy-watch.json` adjacent to
`.gitlab-ci.yml`, or (in a monorepo) adjacent to the specific service's own
`AGENTS.md`. Check all three locations relevant to the thing being watched
before concluding no contract exists. The contract defines the trigger
policy, not the tooling; tooling is discovered fresh every run (step 1),
because two projects on this same skill can watch completely different
stacks:

```json
{
  "env": "production",
  "baseline_minutes": 30,
  "watch_minutes": 60,
  "poll_seconds": 120,
  "rollback": { "authorized": true, "command": "<exact rollback cmd>" },
  "triggers": [
    { "metric": "error_rate", "condition": ">2x baseline", "severity": "auto_rollback" },
    { "metric": "p95_latency", "condition": ">2x baseline", "severity": "alert" },
    { "metric": "uptime", "condition": "<99%", "severity": "auto_rollback" }
  ]
}
```

No contract found → this is a soft stop, not a hard escalate. Ask the human
once, batched: (a) run first-time setup now (§0a) and produce a contract, or
(b) stop until one exists. Never assume (a) silently: the contract encodes
a trust boundary (auto-rollback authorization) that only a human can grant.
Watching without defined triggers produces noise, not safety either way:
never invent a threshold, and never invent a metric a trigger doesn't name.

## 0a. First-time setup (no contract exists)

Run only after the human picked (a) above. Exploring the repo first (CI
config, existing monitoring code, README/AGENTS.md) to pre-fill or
smart-guess answers is encouraged, since it makes the ask shorter, but always
show what was found and let the human confirm or correct it. Never answer
one of these for them and skip the question; a silently-guessed source is
the same failure the "never invent a metric" rule already forbids.

Ask once, batched, free text (this is intentionally open-ended, not
multiple-choice: "I don't know" is a valid answer for 1-4, and just leaves
that category to fresh discovery per run instead of a fixed source):

```
Setting up deploy-watch for this project, five questions, answer what you can:

1. Deploy: which environment should I watch (e.g. production, staging)? How
   does a change reach that environment, and how would I check whether a
   given commit/SHA is currently live there? (CI system name, a CLI, a
   dashboard URL, an MCP tool, whatever you actually use)
2. Rollback: is there a command I'm authorized to run automatically if a
   trigger fires? Give the exact command, or say "no"; if no, I will always
   alert/escalate instead of auto-rolling-back.
3. Metrics: where do I check error rate, latency, and uptime? Name the tool
   (Datadog, Grafana, Prometheus, CloudWatch, an internal CLI, an HTTP
   endpoint, an MCP server) and the exact query/command/URL if you know it.
4. Logs: where should I pull evidence from when something looks wrong?
   Same detail level as above.
5. Defaults, say "defaults" to accept all, or override any:
   - thresholds: error_rate >2x baseline -> auto_rollback (if authorized)
     else alert; p95_latency >2x baseline -> alert; uptime <99% ->
     auto_rollback (if authorized) else alert
   - timing: baseline_minutes=30, watch_minutes=60, poll_seconds=120
```

Write the answers to `deploy-watch.json` at the repo root (or beside the
relevant service's own `AGENTS.md` in a monorepo with more than one watched
service, ask which if that's ambiguous), extending the step 0 schema with a
`sources` block. `env` is always the literal environment named in the
answer to question 1, never assumed: a setup run for staging must record
`"env": "staging"`, not default to production because that's the usual
target.

```json
{
  "env": "<the environment named in question 1, e.g. production>",
  "baseline_minutes": 30,
  "watch_minutes": 60,
  "poll_seconds": 120,
  "rollback": { "authorized": true, "command": "<exact rollback cmd>" },
  "triggers": [
    { "metric": "error_rate", "condition": ">2x baseline", "severity": "auto_rollback" },
    { "metric": "p95_latency", "condition": ">2x baseline", "severity": "alert" },
    { "metric": "uptime", "condition": "<99%", "severity": "auto_rollback" }
  ],
  "sources": {
    "deploy_status": { "type": "cli", "detail": "<verbatim answer: command, URL, or MCP tool name>" },
    "metrics":       { "type": "mcp", "detail": "<...>" },
    "logs":          { "type": "http", "detail": "<...>" },
    "uptime":        { "type": "other", "detail": "<...>" }
  }
}
```

`type` is whichever of `cli` / `http` / `mcp` / `other` matches the answer.
A category the human answered "I don't know" to is simply omitted from
`sources`, step 1 falls back to live discovery for that category only, same
as a contract with no `sources` block at all.

Keep it untracked without touching the project's own `.gitignore` (that file
is shared and committed; this contract is a local, possibly credential-
adjacent artifact). Resolve the exclude file with `git rev-parse`, never a
literal `.git/info/exclude` path: in a linked worktree `.git` is a file, not
a directory, so that literal path fails with "Not a directory", and running
from a subdirectory of the repo (e.g. a service folder in a monorepo)
means a relative `.git/...` path from cwd is wrong too. Compute the entry
relative to the repo root regardless of where `deploy-watch.json` landed or
where this command runs from:

```bash
exclude="$(git rev-parse --git-path info/exclude)"
entry="$(git rev-parse --show-prefix)deploy-watch.json"
grep -qxF "$entry" "$exclude" 2>/dev/null || echo "$entry" >> "$exclude"
```

Only report the contract as untracked after this command exits 0. If it
fails, say so explicitly instead of claiming success; a written contract
that `git add -A` can still pick up is worse than one you flagged as still
tracked.

Close with one line: `Wrote deploy-watch.json (untracked via .git/info/exclude). Re-run deploy-watch now?`

## 1. Discover the sources (fresh every run, never hardcoded)

Same discovery method as `why`'s Discovery step: list what this host can
actually reach. In Cursor, use the available-tools map when present,
otherwise the `mcps/` directory it exposes. In Claude Code, the tool list
(including deferred tools findable via ToolSearch) plus the repo's
`.mcp.json`.

Map what you find to the category each trigger's metric actually needs, not
to a fixed vendor list:

- **Metrics** (`error_rate`, `p95_latency`, custom counters): a
  metrics/observability MCP.
- **Logs** (evidence for an `alert`, or a metric with no dashboard):
  a log-search MCP.
- **Deploy/build status** (has the rollout finished, which SHA is live):
  a CI MCP, or `glab ci` / `gh run` when no MCP covers it.
- **Uptime/synthetic checks**: whatever the project already uses; check
  `AGENTS.md` and `.gitlab-ci.yml` for a named tool before assuming one.

Classify an MCP by its name, server instructions, and tool names, the same
way `why` classifies an ambiguous MCP: by primary evidence, not by guessing
from a familiar-sounding name. Don't assume any specific vendor is present or
absent; check.

If the contract has a `sources` entry for a category, check that first:
verify it's still reachable with one lightweight call before trusting it for
the run. Only fall back to fresh discovery below for a category the contract
doesn't name, or whose named source no longer resolves.

No MCP covers a category a trigger needs → fall back to the CLI the
project's own CI or scripts already call (grep for it before inventing a
command). Still nothing → `escalate`: a trigger you can't read is the same
failure as a trigger that doesn't exist.

State the mapping once, before polling starts, one line:
`Sources: metrics=<mcp/cli>, logs=<mcp/cli>, deploy=<mcp/cli>`.

## 2. Establish baseline before judging

Read each mapped source for the `baseline_minutes` window prior to deploy.
One line: `Baseline: err 0.4% · p95 210ms · uptime 100%`.

## 3. Watch: blocking poll, never busy-loop

One bash call per ~10 min window (loop + sleep inside, like babysit-gitlab-mr),
projecting each metric to a single number via the mapped source's CLI/API
with `--jq` or equivalent. Wake only on trigger match or window end.

Each wake emits exactly one line:
`t+12m: OK (err 0.5% · p95 220ms · up 100%)` or
`t+14m: TRIGGER error_rate 1.1% > 2x baseline 0.4%`.

## 4. Action on trigger

- `auto_rollback` AND contract says `authorized: true` → run the exact
  configured command, then keep watching the ROLLBACK deploy to completion.
  Announce: `Rolled back <sha>: <trigger>`. Never improvise a different
  rollback path.
- `auto_rollback` but not authorized → `escalate` immediately with metric
  evidence; recommend rollback explicitly.
- `alert` → collect evidence (one screenshot/log tail), file an issue
  (`glab issue create`) tagged `deploy-alert`, continue watching.

## 5. End states

- Window elapsed clean → final line `Deploy healthy: <sha> after Nm`, stop.
- Rollback completed stable → summary + auto-created issue linking timeline, stop.
- Deteriorating-but-under-threshold at window end → extend once by
  `watch_minutes`, then report either way.

## Hard rules

Never touch infra beyond the authorized rollback command. Never silence
alerts. Two consecutive polls where a source is unreadable = treat as
`alert`, not as healthy.
