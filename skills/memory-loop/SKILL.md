---
name: memory-loop
description: Persist and resume agent loop state across interruptions, retries, and repeated work using agent-memory checkpoints.
---

# Persist loop state

Use for long, retryable, multi-step, or interruption-prone work.

## Start or resume

1. Call `memory_session_start` only if you need an explicit session ID outside
   the current MCP session; otherwise omit `sessionId` and rely on MCP fallback.
2. Derive `repoId` from current git remote when repository context matters.
3. Call `loop_resume` after reconnect or before continuing interrupted work.
4. If no active run exists, call `loop_start`.
5. Read latest checkpoint before repeating any side effect.

Session memories and loop state expire after two days by default. Checkpoint
activity refreshes loop retention; keep the stable session and run IDs available
while the loop is active.

## Checkpoint policy

Call `loop_checkpoint`:

- After each meaningful completed step.
- Before risky, destructive, or retryable side effect.
- Before pausing or handing work to another agent.
- After recovering from an error.

Record only concise:

- completed work
- current state
- errors and unresolved risks
- artifact IDs or paths
- exact next action

Use stable idempotency key such as `step-<number>-<short-name>`. Reuse same
key when retrying same checkpoint. Never store credentials, tokens, or raw
command logs.

## Finish

Verify state before rerunning commands. Call `loop_finish` with `completed`,
`failed`, or `paused`. Save final checkpoint first when it helps future resume.
