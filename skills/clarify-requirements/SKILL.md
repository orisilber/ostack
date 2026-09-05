---
name: clarify-requirements
description: Resolve material missing ticket requirements in one initial batch, preserving known answers and allowing later questions when new evidence changes the implementation.
---

# Clarify requirements

Read the originating ticket and relevant code. Ask only about missing behavior,
constraints, interfaces, or acceptance criteria that would change the result.
Skip the question round when the intent is clear.

Batch independent questions, usually no more than five. Supply a reasonable
default for reversible implementation choices. Use existing answers and user
instructions directly. A default does not supply permission for an external
action, and silence does not answer a consequential question.

Keep decisions in the current task. When updates to the originating ticket are
authorized, preserve its description and append a short Decisions record
(question, decision, date) through its own provider. A Jira answer belongs in
Jira even when code review later happens in GitLab. If ticket writes are outside
scope, hand back the decisions without publishing them.

Continue implementation once the material gaps are resolved. New evidence can
justify another focused question; do not force a guess to preserve a one-round
rule. Use `escalate` only for a real authority, access, or unresolved blocker.
