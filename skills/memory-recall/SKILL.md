---
name: memory-recall
description: Search agent-memory for user preferences, repository procedures, prior decisions, current-session facts, or interrupted work before answering or repeating work.
---

# Recall memory

Use memory when task depends on remembered preference, project practice, prior
decision, previous attempt, or loop state. Do not call memory for unrelated
questions.

## Scope selection

- `global`: personal preference or reusable procedure.
- `repo`: current repository convention, decision, or how-to.
- `session`: current conversation or temporary task state.
- Search multiple scopes only when needed. Put scopes explicitly in
  `memory_search`; service never broadens scope silently.

Call `memory_session_start` only when you need a stable ID outside the current
MCP session. Session-scoped tools fall back to the active MCP transport session
when `sessionId` is omitted. For repo scope, derive `repoId` from canonical git
remote; use repository root only when no remote exists.

## Search behavior

1. Search narrowest relevant scope first.
2. Use specific query terms and kind filter when known.
3. Treat results as evidence, not unquestionable truth.
4. Prefer newer explicit user instruction over older memory.
5. If memories conflict or confidence is low, ask user or state conflict.
6. Do not expose unrelated memory from another scope.

Never write memory during recall. Use `memory-capture` guidance only when new
stable information should persist.
