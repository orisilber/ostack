---
name: memory-admin
description: Review, export, correct, archive, or delete agent-memory records only after explicit user request.
disable-model-invocation: true
---

# Administer memory

Never perform memory administration automatically.

For explicit review or export:

1. Ask which scope to inspect if user did not specify one.
2. Call `memory_list` with explicit scopes and context.
3. Show IDs, kinds, scopes, titles, and timestamps before mutation.

For correction:

- Confirm target ID and intended replacement.
- Use `memory_update`.
- Re-search updated scope.

For archival:

- Confirm target ID.
- Use `memory_archive` with `confirm: true`.
- Re-search to verify record is hidden from active results.

For deletion:

- Confirm exact memory ID and consequence.
- Call `memory_forget` with `confirm: true`.
- Report whether deletion succeeded.

Do not delete by broad query. Do not expose records outside requested scope.
