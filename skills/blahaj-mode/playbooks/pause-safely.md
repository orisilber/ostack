# Pause-safely playbook

Use this route when the user asks to pause, stop, or leave work ready to resume.

1. Stop at the current atomic boundary: never interrupt a write, migration,
   commit, or external request halfway through.
2. Record current status, changed files, verification state, and the exact next
   action in a durable resume note.
3. Use `show-me-your-work` only when a decision trail already exists or the run
   needs one to preserve a non-obvious choice.
4. Leave the worktree recoverable and report anything that remains in flight.

Pausing does not discard changes, delete a worktree, close an MR, or send a
message to an external system.
