---
name: deploy-watch
description: Watch a deployment's health after release. Compare error/latency/uptime metrics against baseline, and roll back or alert per pre-authorized policy. Triggers "watch the deploy", "post-deploy check", "monitor rollout". Use only for post-deployment monitoring; triggering deploys belongs to CI, not this skill.
---

# Deploy Watch

The last mile of autonomy: notice breakage before users do, act within
pre-granted limits.

## 0. Load the watch contract (required before watching anything)

Per-project config in `AGENTS.md` or `.gitlab-ci.yml`-adjacent
`deploy-watch.json`:

```json
{
  "env": "production",
  "sources": { "errors": "<sentry/grafana URL or CLI>", "latency": "...", "uptime": "..." },
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
noise, not safety. Never invent thresholds.

## 1. Establish baseline before judging

Read each source for the `baseline_minutes` window prior to deploy. One line:
`Baseline: err 0.4% · p95 210ms · uptime 100%`.

## 2. Watch: blocking poll, never busy-loop

One bash call per ~10 min window (loop + sleep inside, like babysit-gitlab-mr),
projecting each metric to a single number via the source's CLI/API with `--jq`
or equivalent. Wake only on trigger match or window end.

Each wake emits exactly one line:
`t+12m: OK (err 0.5% · p95 220ms · up 100%)` or
`t+14m: TRIGGER error_rate 1.1% > 2x baseline 0.4%`.

## 3. Action on trigger

- `auto_rollback` AND contract says `authorized: true` → run the exact
  configured command, then keep watching the ROLLBACK deploy to completion.
  Announce: `Rolled back <sha>: <trigger>`. Never improvise a different
  rollback path.
- `auto_rollback` but not authorized → `escalate` immediately with metric
  evidence; recommend rollback explicitly.
- `alert` → collect evidence (one screenshot/log tail), file an issue
  (`glab issue create`) tagged `deploy-alert`, continue watching.

## 4. End states

- Window elapsed clean → final line `Deploy healthy: <sha> after Nm`, stop.
- Rollback completed stable → summary + auto-created issue linking timeline, stop.
- Deteriorating-but-under-threshold at window end → extend once by
  `watch_minutes`, then report either way.

## Hard rules

Never touch infra beyond the authorized rollback command. Never silence
alerts. Two consecutive polls where a source is unreadable = treat as
`alert`, not as healthy.
