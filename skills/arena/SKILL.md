---
name: arena
description: Compare independent candidates for a consequential design or implementation choice, select a base, integrate useful improvements, and verify the result. Use for arena, competing approaches, or an explicit comparison; use swarm for disjoint work.
disable-model-invocation: true
---

# Arena

Produce one selected or synthesized artifact with evidence for the choice.
Preserve the caller's acceptance scope, write boundaries, and test sequencing.

## Candidates and models

Choose the candidate count from the useful directions and the requested
comparison, usually two or three. Candidates run on the parent model: omit the
subagent `model` argument. When the user names models in the request, assign
them to candidates or to a separate judge as the user asked. If the host rejects
a named model, say so and run that candidate on the parent model. Do not
substitute a nearby model.

## Frame and run

1. State the artifact, acceptance criteria, caller-owned boundaries, and two or
   more viable directions for the requested comparison. Reuse adequate grounding.
2. Give each candidate the same acceptance scope and a disjoint output directory
   or worktree. A branch name alone does not isolate writes.
3. Launch the candidates using the host's supported delegation API. Each returns
   its artifact, important decisions, and verification evidence.
4. Wait for outputs before judging them. Inspect the actual artifacts; report
   missing candidates and do not count failed delegation as a completed comparison.

For a design-only caller, every candidate returns a design package and leaves
production code alone. For feature implementation, preserve the caller's
test-last constraint: existing checks can run, and permanent feature tests wait
until real-interface acceptance. Arena verification does not replace that gate.

## Choose and integrate

Assess every candidate against the same concrete criteria. Inspect the affected
contracts and evidence closely enough to justify the choice. The parent judges.
Add a separate read-only judge only when the user names a model for it; an
unavailable judge does not stall the parent's review.

Choose on evidence and maintainability. Agreement is corroboration, not proof;
a concrete counterexample can outweigh consensus. Resolve material disagreements
by checking the artifact or running a focused experiment.

Use the strongest base and port only improvements that earn their complexity.
No graft is required when the base already covers the useful ideas. Divergent
candidates do not automatically imply an invalid task: clarify the disputed
constraint only when it prevents a justified decision.

## Verify and return

Verify the integrated artifact against its acceptance scope and the caller's
required checks. Fix a local defect directly; repeat the comparison only when
new evidence invalidates the design or rubric.

Return one artifact and a short decision record: why this base, useful grafts,
material rejected alternatives, dropouts, and observed verification. Keep the
record proportional to the decision. The caller owns publication and later work.
