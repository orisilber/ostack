---
name: arena
description: Run N parallel candidates at the same artifact, judge them, then graft the strongest parts of the losers into one base. Triggers "arena this", "try a few approaches", "compare implementations". Use only when one attempt would lock in the wrong shape; slice-and-cover parallelism is swarm.
disable-model-invocation: true
---

# Arena

Fan out N parallel attempts at the same task. Read every candidate end to end. Pick the strongest as the base. Graft the best ideas from the others into it. Verify the synthesized result.

## Model resolution

Arena owns model resolution for its subagents. The runner role defaults to
`arena runners`. A nested caller may explicitly pass a **runner-role override**
when this contract says that override is supported by the caller's workflow.
When present, resolve that role instead of `arena runners`; do not merge both
panels. `arena cross-judge` is not changed by a runner-role override.

Resolve the selected runner role and `arena cross-judge`, both generic role
`judgment`, from `~/.cursor/rules/ostack-models.mdc`. For each role use its
skill-role line first, then its generic role line, then `inherit`.

The selected runner role is a panel. Run one subagent per resolved entry, so the
entry count sets the fan-out. If the host rejects an entry, drop it and run the
rest. Fall back to `inherit` only when nothing is left.

`arena cross-judge` is a pool rather than a panel. Pick one entry from it, and
prefer a different model family from the parent's when the host allows it.

Pass the resolved value as the subagent `model` argument. `inherit` means omit
`model` and let the subagent run on the parent chat model. A line never mixes
`inherit` with a model ID. Hosts that do not load the rule resolve every role
to `inherit`. When the host rejects a model ID, do not swap in a nearby one. A
successful call proves nothing about which model ran, because the host may
substitute one without saying so.

## Start

Open a todolist with one entry per phase before launching anything. The arena runs autonomously and the list keeps phases from silently disappearing.

1. Frame
2. Fan out
3. Cross-judge
4. Pick
5. Graft
6. Verify

## Phase A: Frame

The N candidates will receive the same prompt, so the prompt is the contract. Get it right before spawning anything.

1. State the artifact each candidate is producing.
2. Derive the rubric. State what success looks like for *this* task, then turn it into 3-6 concrete gradeable criteria. Concrete: `Adds a --dry-run flag that skips writes`. Vague: `code is correct`. The rubric is the picker's tool in Phase D; candidates only see the task.
3. Pick the runners from the resolved runner-role panel. Spawn more when the arena covers multiple design directions. Same model N times when the work is generation-bound rather than judgment-sensitive.
4. Assign output paths. Each candidate writes to its own location (a git worktree where possible, otherwise `/tmp/arena-<slug>/candidate-<n>/`). N candidates writing to the same path is shared mutable state and fails the the **separate-before-serializing-shared-state** principle test.

## Phase B: Fan out

Spawn all N subagents in one message with `run_in_background: true`, each with the task, the path to the shared grounding, its own output path, and instructions to produce both the artifact and a short rationale.

The rationale is mandatory. Without it, the parent cannot tell whether a candidate's structure is principled or accidental, which makes Phase E grafting unreliable. Each rationale names the alternatives the candidate considered and what it rejected.

If a candidate fails to produce output, proceed with N-1 and note the dropout in the synthesis record.

## Phase C: Cross-judge

After all Phase B candidates complete, choose one judge from the resolved
`arena cross-judge` pool, preferring a different family from the parent when
possible. On a single-vendor host, prefer a different reasoning tier and say
the judge shares the parent's family. Spawn one readonly judge subagent on that
model. It sees the rubric and the candidates by path label, scores each
criterion, and recommends a base with rationale. It runs in parallel with the
parent's reading in Phase D, not with the candidates themselves. Spawning while
the candidates are still writing means the judge sees partial or empty outputs
and reports them as dropouts.

## Phase D: Pick a base

Read every candidate end to end before picking. Skimming N candidates surfaces only the candidate whose surface looks most familiar.

Score each candidate against the rubric criterion by criterion, not on holistic feel. Compare against the cross-judge. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base on which candidate a future maintainer can extend most easily without breaking invariants. Prefer the cleaner boundary or smaller surface area when two feel tied, per the Laziness Protocol.

Record the pick and the reason in a short synthesis note alongside the base artifact, including the cross-judge's verdict.

## Phase E: Graft

Walk each losing candidate once more and identify what is worth porting into the base. The signal is usually one or two things per candidate, not most of it.

Fold each graft in by hand, per the **redesign-from-first-principles** principle. Don't paste mechanically. The result has to remain coherent under one mental model.

Record what was grafted, from which candidate, and what was rejected and why. The rejection notes are the highest-signal part of the record. Future readers learn from what you considered and dropped, not just what you kept.

When N candidates converge on the same shape, that is a strong agreement signal. Note the convergence in the record and ship the consensus shape. No graft is needed. When N candidates wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

The synthesized artifact has to hold up under the same scrutiny as any other output, per the **prove-it-works** principle. The arena does not earn you a pass.

If verification surfaces a problem the arena did not catch, either Phase A was wrong (re-frame and re-run) or one candidate caught it and you missed the graft (go back to Phase E). Don't paper over.

## Outputs

One synthesized artifact. One short synthesis note alongside, naming the base, the grafts (with source candidate), the rejections, the dropouts if any, and the verification result.
