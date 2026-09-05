# Set up a watch contract

Read only for first-time setup or missing contract values. Inspect relevant
service instructions, CI, monitoring configuration, and repository docs first.
An explicit setup request authorizes preparing the local contract; do not ask
permission to begin again.

Ask one batch containing only unanswered consequential values:

- Environment and the way to verify which SHA is live.
- Metrics, queries, and baseline/trigger definitions.
- Watch duration and polling interval.
- Exact rollback command and authority, if rollback is desired.
- Notification destinations or issue creation, if external reporting is desired.

Sources can be discovered from configuration; do not ask the user to repeat
them. Timing and threshold suggestions are proposals until accepted. Silence
does not accept a rollback policy. A complete supplied contract needs no
question round.

Use this schema as a shape, replacing values with the actual agreed policy:

```json
{
  "env": "<agreed environment>",
  "baseline_minutes": 30,
  "watch_minutes": 60,
  "poll_seconds": 120,
  "rollback": { "authorized": false, "command": null },
  "triggers": [
    { "metric": "error_rate", "condition": "<agreed threshold>", "severity": "alert" }
  ],
  "sources": {
    "deploy_status": { "type": "cli", "detail": "<exact command>" },
    "metrics": { "type": "mcp", "detail": "<tool and metric query>" }
  }
}
```

The example numbers are not defaults to apply without agreement. Validate
positive timing values, reachable sources, and actionable trigger conditions.
Use `cli`, `http`, `mcp`, or `other` as appropriate to each source. When
rollback is authorized, record its exact operation and post-rollback observation
duration. Keep credentials out of the contract; use existing credential stores.

Write the contract at the repository root or the relevant service directory,
preserving unrelated existing settings. A local contract should be untracked.
Pass the actual file path, from any invocation directory, to the checked helper:

```bash
python3 <deploy-watch-skill>/scripts/exclude-contract.py <actual-contract-path>
```

[scripts/exclude-contract.py](../scripts/exclude-contract.py) resolves Git's
exclude file for ordinary and linked worktrees, anchors and escapes the actual
repository-relative path, and checks the result. It refuses an already tracked
contract: adding an ignore entry cannot untrack it. Report that situation and
leave the index intact; do not claim success or silently remove tracked files.

If setup and watching were both requested, start the watch once the agreed
contract validates. Otherwise report its path and status and stop.
