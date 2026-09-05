# Local verification

Run `bash evals/lint.sh` from the repository root. It validates skill metadata,
dependencies, declared CLI examples, installer upgrades, workflow routes, and
the deterministic audit regression fixtures. It does not launch model agents
or modify external services. Git, jq, Bash, Python, and PyYAML are required;
the existing evaluation helper installs missing PyYAML into `evals/.venv`.

The TypeScript teaching examples are extracted directly from the Markdown,
compiled with strict checking and `noUncheckedIndexedAccess`, and exercised
at runtime. Provide an installed TypeScript package through `TYPESCRIPT_PATH`
if it is not resolvable locally. Version 5.9.3 was used for this audit:

```bash
TYPESCRIPT_PATH=/path/to/node_modules/typescript bash evals/lint.sh
```

Without the compiler, lint explicitly warns that those checks were skipped.
`OSTACK_LINT_SKIP_CLI_CHECKS=1` skips installed CLI help probes for offline runs.
It does not skip the executable regression, metadata, route, or installer checks.

Model-behavior scenarios under `evals/scenarios` run separately through
`evals/run.sh`; their presence is not evidence that an agent completed them.
The audit report records the checks actually executed and remaining live
service and model validation.

`python3 tests/autonomy-regressions.py` runs the checkpoint and GitHub collector
against disposable Git repositories and an offline `gh` fixture. It covers
pending and failed CI, a changed head with stale approval, fresh approval,
pagination, API failures, reduced authority, and worktree isolation. These are
executable helper tests; they do not establish live review-bot or scheduler
behavior. The GitHub delivery YAML scenario uses a local bare remote and checks
the final head and readiness result, in addition to the agent's narration.
