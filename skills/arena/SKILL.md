---
name: arena
description: Compare independent candidates for a consequential design or implementation choice, select a base, integrate useful improvements, and verify the result. Use for arena, competing approaches, or an explicit comparison; use swarm for disjoint work.
disable-model-invocation: true
---

# Arena

Produce one selected or synthesized artifact with evidence for the choice.
Preserve the caller's acceptance scope, write boundaries, and test sequencing.

## Resolve models and candidate count

Arena owns resolution for its subagents. The runner role defaults to
`arena runners`. A nested caller may pass a supported **runner-role override**,
such as Architect's `architect runners`. Resolve that role instead of merging
it with the default panel. The judge role remains `arena cross-judge`.

Resolve each role from `~/.cursor/rules/ostack-models.mdc`: skill-role line,
then generic `judgment`, then `inherit`. Pass the resolved value as the
subagent `model` argument; `inherit` omits it. Hosts that do not load the rule
use `inherit`. Drop rejected entries, falling back to `inherit` when none
remain. Do not invent a nearby model ID or claim actual model identity from
a successful call alone.

The configured list supplies models, not candidate count. Choose N from useful
directions and the requested comparison, reusing a model for multiple candidates
when needed. A judge, when useful, takes one available entry, preferably from a
different model family when the host confirms that option.

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
contracts and evidence closely enough to justify the choice. Use a separate
read-only cross-judge when requested or when another assessment would materially
reduce uncertainty; an unavailable judge does not stall a supported parent review.

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
