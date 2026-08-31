---
name: swarm
description: Fan out N parallel workers across slices or races, drain them, and return one aggregated report. Triggers "swarm this", "one worker per package", "parallel coverage", "run the gauntlet". Use only for bulk work with a stated done predicate; competing attempts at one artifact are arena.
disable-model-invocation: true
---

# Swarm

Fan out N parallel workers, cloud where the host has them, local otherwise. They may cover separate slices, race the same brief, or mix both. The parent waits, aggregates, and returns one report.

## Model resolution

Resolve `swarm.workers` from the canonical ostack configuration at
`$OSTACK_CONFIG_HOME/models.json`, or `~/.config/ostack/models.json` when the
variable is unset. Use the exact override first, then the generic
`implementation` role, then `inherit`. A missing, invalid, or empty
configuration is recoverable: report the fallback once and use `inherit`.

Workers use the first resolved entry unless a race or comparison explicitly
assigns another configured entry. If the host rejects an entry, use `inherit`
for that worker; never pick a nearby model ID. Do not claim that a successful
worker call proves which model ran because the host may silently substitute it.

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Set N from the user or derive it from the shape. N is total workers, not the cloud concurrency limit.
4. Pick the worker model from the resolved `swarm.workers` role; workers are
   bulk labor, so use the first configured entry. For a model race, name each
   arm's model up front and use only configured entries.
5. Give each worker its own writable output when it writes. Use a worktree, branch, or `/tmp/swarm-<slug>/worker-<n>/`.

## Phase B: Fan out

Spawn all N workers in one message, backgrounded, on the configured model.

- **Cursor**: `subagent_type: generalPurpose`, `environment: "cloud"`, `run_in_background: true`. Use `environment: "local"` only when the worker needs something on the user's computer. A worker starting from a non-default pushed branch takes `cloud_base_branch`.
- **Claude Code**: the Agent tool backgrounded, one call per worker in a single message. Workers that write to the same repo take `isolation: "worktree"`. There is no cloud environment: every worker is local, so N is bounded by the machine, not by a remote pool. Cap N accordingly and say what you capped.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

Keep a compact result table, one-line evidenced issues, and explicit gaps or dropouts.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.
