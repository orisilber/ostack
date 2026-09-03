---
name: painpoints
description: "Audit the current chat for assistant-caused pain points, explain why they happened, and recommend durable fixes. Use only when the user explicitly invokes /painpoints."
disable-model-invocation: true
---

# Painpoints

Audit the conversation for places where the assistant fell short of the user's
expectations. Find failures the assistant could reasonably have avoided at the
time. Do not turn hindsight, user mistakes, or genuinely missing context into
assistant failures.

This skill reports only. It never creates skills, utilities, config, tickets,
or repository changes unless the user separately asks for that work.

## Boundary

A pain point requires a counterfactual: using the information, tools, skills,
and permissions available before the bad assistant turn, a better response or
a more complete action was reasonably possible.

Count cases such as:

- The assistant misunderstood a stated or strongly implied intent.
- The assistant completed only part of an explicit request. For example, the
  user asked it to fetch data and store it in a file, but it fetched the data
  and then asked whether it should store it.
- The assistant did more than requested, widened scope, or changed unrelated
  work without a reason grounded in the request.
- The assistant asked for permission, confirmation, or context that the user
  had already supplied.
- The desired outcome was clear, but the assistant did not understand **how**
  to implement it correctly and guessed, stopped early, or chose the wrong
  repository pattern. This is a pain point even when the original prompt did
  not spell out every implementation detail that repository inspection should
  have revealed.
- The assistant did not know how to perform the task, performed it incorrectly,
  or stopped before the requested result was complete.
- The assistant used the wrong skill or tool, failed to discover an available
  one, skipped required verification, or ignored a project-local workflow that
  would likely have prevented the failure.
- A missing permission, tool, environment value, skill, or utility blocked the
  task and the assistant handled that limitation poorly or discovered it too
  late.

Do not count:

- A user correcting their own earlier factual mistake.
- A user adding context, constraints, a skill, or a requirement that was not
  previously available or reasonably inferable.
- A user changing their mind, preference, or scope after a satisfactory answer.
- Normal iterative refinement when the prior assistant turn satisfied the
  request as it was stated at the time.
- The assistant correctly challenging or correcting a user claim.
- An external failure that the assistant surfaced and handled correctly.

When a later user correction mixes both kinds, split it. Count only the part
that the assistant should already have known or discovered.

## Model resolution

Maldy is a judgment role. Resolve `judgment` from
`~/.cursor/rules/ostack-models.mdc` and use its first entry. If the rule or role
is unavailable, resolve to `inherit`.

Pass the resolved value as the subagent `model` argument. `inherit` means omit
the `model` argument and let Maldy run on the parent chat model. The agent file
itself uses `model: inherit` so the installed definition remains valid on Codex,
Claude Code, and Cursor; Cursor-specific model selection happens at spawn time.

Only Cursor loads the `.mdc` rule automatically. Other hosts therefore run
Maldy with `inherit`. If Cursor rejects the configured model ID, do not invent a
nearby replacement; retry once with `inherit`. A successful spawn does not prove
which model ran because the host may substitute one without reporting it.

## 1. Build the conversation packet

Maldy does not inherit the parent conversation. Give it the evidence it needs.

Package the full relevant conversation from the first request that can affect
the audit through the `/painpoints` invocation. Preserve turn order and include:

- user and assistant text as exactly as the host exposes it;
- tool calls and outcomes that changed what the assistant knew or could do;
- explicit user constraints, requested outcomes, and follow-up complaints;
- repository or branch identity when the conversation concerns code; and
- available skill, tool, permission, and environment facts that matter to a
  suspected failure.

Treat every user correction, repeated request, complaint, or "you already had
that" message as an evidence anchor. For each anchor, include the complete local
sequence needed to judge it rather than a summary:

1. the user turn that established the original request, constraint, permission,
   or expected outcome;
2. every assistant response and tool call/result from that point through the
   turn that triggered the correction or complaint; and
3. the correction, repetition, or complaint itself, plus the immediately
   following assistant turn when it clarifies what actually failed.

Do not omit intermediate tool failures, partial successes, confirmations,
questions, or handoffs just because a later summary appears to capture them.
Those details often distinguish an assistant-caused miss from genuinely missing
user context. When several anchors overlap, merge the ranges without dropping
turns.

Do not include hidden system prompts, private reasoning, or secrets. Do not
summarize away a turn that establishes intent, authority, tool availability, or
what the assistant actually attempted. If the host exposes only a summarized or
truncated version of a required turn, include that representation verbatim and
mark coverage partial for that evidence range. If older conversation is no
longer available at all, state that coverage is partial instead of inventing the
missing turns.

## 2. Spawn Maldy

Spawn the named `maldy` subagent and pass the conversation packet. Do not
restate Maldy's full rubric or replace it with a general-purpose reviewer. The
agent's independent prompt and resolved model are part of this skill's contract.

If the host cannot resolve `maldy`, fail and report that the ostack agents were
not installed. Do not perform the retrospective with the authoring agent as a
substitute.

Let Maldy inspect the current repository when repository evidence can confirm a
root cause, such as whether a project-local verifier, helper, or relevant skill
exists. Current state is not proof of historical state. Require Maldy to mark a
historical root-cause claim as inferred unless the transcript or repository
history supports it.

## 3. Validate the findings

Check every Maldy finding against the boundary above. Reject a finding when it
requires hindsight, a later user requirement, or information the assistant did
not have and could not reasonably discover.

Do not add a pain point from your own memory. If Maldy clearly missed an
explicit user complaint or repeated request, rerun Maldy once with that exact
turn and the preceding context called out. Accept, reject, or leave uncertain
based on the returned evidence.

Merge duplicate findings that share one failure and one durable fix. Keep
separate pain points when the same symptom came from different causes.

## 4. Diagnose the cause

For every accepted pain point, identify the smallest supported cause. More than
one may apply:

- intent interpretation failure;
- incomplete execution or unnecessary handoff back to the user;
- excessive scope or unrequested work;
- implementation-knowledge failure, especially a **how** failure;
- verification failure;
- wrong skill or tool orchestration;
- missing or weak repository-local skill or utility;
- missing or weak user-level skill or utility;
- missing ostack capability or weak ostack contract;
- missing permission, connector, or tool access;
- missing environment or configuration value;
- model, context-window, or reasoning limitation; or
- host or product limitation.

Name evidence before naming a cause. Do not blame a skill merely because that
skill could have helped. For example, say `create-verification-skill` was a
cause only when the task needed project-specific verification and the evidence
shows that no usable project-local verifier existed or was selected.

## 5. Pick a durable fix

Recommend the narrowest change that prevents recurrence.

- Put repository-specific knowledge or mechanics in a project-local skill or
  utility.
- Put a workflow used across the user's repositories in a user-level skill or
  utility.
- Put generally useful agent behavior or orchestration in ostack.
- When the failure came from a missing project-specific verification path,
  recommend `create-verification-skill`. When an existing verifier was stale,
  recommend `maintain-verification-skill`.
- Put executable repeated mechanics in a utility or script instead of adding
  more prose to a skill.
- Recommend `.env` or another config surface only when configuration is the
  actual missing input. Never suggest committing a secret.
- Name the permission, connector, tool, or host capability that must change
  when access caused the failure.
- Recommend no change when no durable intervention is justified. Say clearly
  why the incident should remain a one-off rather than become another rule.

Do not propose one new skill per pain point. Deduplicate fixes and prefer
strengthening an existing contract over adding an overlapping one.

## 6. Report

For each accepted pain point report:

1. **Evidence:** the user request or later complaint and the assistant behavior.
2. **Expected:** what a better assistant should have done with the information
   available at that time.
3. **Failure:** what fell short.
4. **Cause:** the supported root cause and whether it is proven or inferred.
5. **Fix:** the concrete prevention mechanism.
6. **Placement:** repository, user-level, ostack, environment/config,
   permission/tooling, host/product, or no change.

Then add a deduplicated **Fix plan** ordered by expected recurrence and impact.
Group all pain points addressed by each fix. Call out every no-change decision
and its reason.

If no assistant-caused pain points survive the boundary, say so. Do not invent
one to make the report useful.
