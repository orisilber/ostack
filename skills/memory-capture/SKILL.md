---
name: memory-capture
description: Save explicit user preferences, stable procedures, project decisions, and useful facts to agent-memory without storing secrets or transient noise.
---

# Capture memory

Store memory only when it will help future work:

- User explicitly says remember, always, never, prefer, or forget.
- User confirms durable project convention or decision.
- Procedure succeeded and is reusable.
- Useful fact has clear scope and provenance.

Do not store greetings, one-off reasoning, raw tool output, full logs, secrets,
credentials, tokens, private keys, or temporary guesses. Service redaction is a
last safety net, not permission to send secrets.

## Write steps

1. Search same scope first.
2. Choose scope deliberately:
   - `global` for personal preference or cross-project procedure.
   - `repo` for repository convention, decision, or how-to.
   - `session` for current conversation facts that should not become durable.
     Omit `sessionId` when calling through MCP; transport session is used.
3. Choose kind: `preference`, `procedure`, `decision`, or `fact`.
4. Write concise content. Include conditions and exceptions.
5. Add provenance.
6. Use `memory_store`; service deduplicates normalized content.
7. Tell user what was remembered when user requested capture.

Global memory must not override fresh user instructions. Update or forget only
after explicit correction or request. Use `memory_update` for correction and
`memory_forget` only with confirmed memory ID.
