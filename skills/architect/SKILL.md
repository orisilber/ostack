---
name: architect
description: Settle types, signatures, and module boundaries when the user asks to architect or a workflow finds a consequential unresolved design. Return a sketch to the caller, or implement it in full mode.
disable-model-invocation: true
---

# Architect

Settle the caller's usage, types, and ownership before committing to a shape.
Reuse an established design when it already answers the consequential questions.

## Modes and ownership

- **Full** is the default for direct architect usage: design, implement, and
  verify the requested change.
- **Design-only** returns a design package and stops. The caller owns product
  edits, decomposition, implementation, and final verification. Do not write
  production implementation code in this mode.
- **Full with checkpoint** pauses after the design only when the invoker
  explicitly requested that checkpoint.

Callers that own implementation must select `architect design-only` explicitly.
A design-only return is a handoff to that caller, not a request for another user
approval. Preserve already granted authority throughout.

## Ground the decision

Reuse the caller's current evidence and inspect contracts the design could
change. Invoke the **how** skill for a material gap in behavior or ownership,
and the **why** skill when unresolved historical constraints affect the choice.
A mechanical change with a clear target does not require another investigation.

Write the caller's usage first. Derive the type sketch, signatures, and module
map from it. Use [references/rationale-template.md](references/rationale-template.md)
for a substantial package; scale the detail to the decision.

## Compare only consequential alternatives

If grounding leaves multiple viable shapes and choosing poorly would cause
substantial rework, or the user explicitly requests alternatives, route through
the **arena** skill. Pass the grounding and
[references/runner-prompt.md](references/runner-prompt.md). Candidates produce
design packages only; no production implementation edits.

Set Arena's supported runner-role override to `architect runners`. Arena owns
candidate spawning, fallback handling, and its separate `arena cross-judge`
role. Do not merge `arena runners` into the design-candidate panel.

The selected role resolves from its line in
`~/.cursor/rules/ostack-models.mdc`, then generic `judgment`, then `inherit`.
Arena passes each resolved value as the subagent `model` argument; `inherit`
omits that argument. Hosts that do not load the rule use `inherit`. Do not
substitute nearby model IDs or claim the requested model was the one that ran
without host evidence.

Candidate count follows the useful design directions, not model-list length.
Reuse an available model for distinct directions when necessary. When there
is one established, reversible shape, produce that grounded candidate directly
and record why a comparison would not change the decision.

## Select and return the contract

Check the candidate against
[references/design-red-flags.md](references/design-red-flags.md). Reject
information leaks, shallow wrappers, and unnecessary coupling. Compare viable
alternatives on what callers need to know and what complexity the interface hides.
Reuse a prior comparison that still answers this decision.

Return the usage sketch, selected types and signatures, module ownership,
material alternatives, and constraints implementation must preserve.
In design-only mode, stop here. In full mode, continue unless the user requested
a checkpoint. Commit a scaffold separately only when authorized and useful to
review; a design handoff does not authorize a product commit.

## Implement in full mode

Fill in the chosen design and verify the accepted behavior. Keep verification
appropriate to the task: bug reproduction, feature acceptance followed by
retention coverage, or refactoring equivalence.

Treat implementation deviations as evidence. A local correction need not
restart design. Revisit the shape when the same friction recurs across callers:
leaking internal rules, repeated special cases, or incompatible ownership.
Compare again only if the new evidence leaves a consequential choice.

Return the implemented result and its verification, with the design rationale
at the depth needed to review it. The calling workflow owns publication and
any subsequent reviewer interaction.
