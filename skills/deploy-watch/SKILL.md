---
name: deploy-watch
description: "Watch a deployment's health after release: compare error/latency/uptime against baseline, roll back or alert per pre-authorized policy. Triggers \"watch the deploy\", \"post-deploy check\", \"monitor rollout\". Not for triggering deploys, that's CI's job."
---

# Deploy Watch

The last mile of autonomy: notice breakage before users do, act within
pre-granted limits.

## 0. Load the watch contract (required before watching anything)

Per-project config in `AGENTS.md` or `.gitlab-ci.yml`-adjacent
`deploy-watch.json`. The contract defines the trigger policy, not the
tooling; tooling is discovered fresh every run (step 1), because two
projects on this same skill can watch completely different stacks:

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

No contract found → `escalate`: watching without defined triggers produces
noise, not safety. Never invent a threshold, and never invent a metric a
trigger doesn't name.

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
