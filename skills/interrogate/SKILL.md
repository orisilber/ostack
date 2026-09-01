---
name: interrogate
description: Adversarial review panel over a diff. Independent reviewers attack it from different angles, then one lead judgment sorts every finding into act-on / consider / noted / dismissed. Triggers "interrogate", "adversarial review", "stress test this", "tear this apart". Use only on a changeset you want broken; it never auto-applies fixes, and a repo-local review skill wins where one exists.
disable-model-invocation: true
---

# Interrogate

Spawn one reviewer per configured model to adversarially review code changes. Each model gets the same prompt and rubric. The adversarial signal comes from model diversity, not assigned personas. Models differ in blind spots, priors, and reasoning patterns. Agreement across models is high-confidence signal; lone-model findings are worth reading but lower confidence.

The deliverable is a synthesized verdict. Do not auto-apply changes.

## Model resolution

Resolve `interrogate reviewers`, generic role `judgment`, from
`~/.cursor/rules/ostack-models.mdc`. Use the skill-role line first, then the
generic role line, then `inherit`.

This is a panel. Run one subagent per resolved entry, so the entry count sets
the fan-out. If the host rejects an entry, drop it and run the rest. Fall back
to `inherit` only when nothing is left.

Pass the resolved value as the subagent `model` argument. `inherit` means omit
`model` and let the subagent run on the parent chat model. A line never mixes
`inherit` with a model ID. Hosts that do not load the rule resolve every role
to `inherit`. When the host rejects a model ID, do not swap in a nearby one. A
successful call proves nothing about which model ran, because the host may
substitute one without saying so.

## Step 1, Determine Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that
- If on a feature branch, run `git diff main...HEAD` (or the appropriate base branch) for the full changeset
- If the user's message references recent work, gather the relevant files

Package the diff (or file contents) plus any surrounding context files the reviewers need to understand the code.

## Step 2, State the Intent

Before spawning reviewers, state the intent explicitly. What is this code trying to accomplish? Derive this from:

- The user's message
- Commit messages
- PR description if one exists
- The code itself

Write one clear paragraph. Reviewers challenge whether the work achieves the intent well, not whether the intent itself is correct. If you're unsure about the intent, ask the user before proceeding.

## Step 3, Spawn Reviewers

Launch all reviewers in a single message. Create one reviewer per entry in the
resolved `interrogate reviewers` panel and label them in spawn order (Reviewer
A, Reviewer B, and so on). The resolved entries define the panel's size and
requested models.

For each reviewer:
- `subagent_type`: `generalPurpose` in Cursor; `Explore` (read-only) or `general-purpose` in Claude Code
- `model`: one entry from the resolved `interrogate reviewers` panel
- `readonly`: `true`

If a configured model entry is rejected, remove that entry from this panel and
continue with the remaining entries. Use `inherit` only when no entries
remain. Do not pick a nearby slug or edit the model configuration as part of a
review.

Read `references/reviewer-prompt.md` and fill in the template with:
1. The stated intent
2. The diff or file contents
3. The review rubric from `references/rubric.md`
4. The code-quality lens from `references/code-quality-review.md`

The same filled template goes to all reviewers, so every model applies the code-quality lens.

Each reviewer produces structured findings as described in the prompt template.

## Step 4, Synthesize

As results come back, build a unified picture:

1. **Parse all findings** from the reviewers
2. **Identify consensus**. Findings raised by 2+ models independently are highest signal.
3. **Identify lone-model findings**. Still worth reading, but weight accordingly.
4. **Deduplicate**. Different models may describe the same issue differently. Merge these and note which models raised it.
5. **Note disagreements**. If one model flags something and another explicitly says the opposite, that's useful context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read `references/lead-judgment.md` for the full framework. Reviewers only see a slice of the codebase. You have the full context (the goal, the constraints, the timeline, which tradeoffs were already considered). Use that context aggressively.

Categorize every finding using these buckets:

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider**. Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed**. Wrong, nitpicky, or missing context. Brief explanation why.

For each finding, include:
- Which model(s) raised it
- The category (act on / consider / noted / dismissed)
- A one-line rationale for the categorization

## Output Format

Present the verdict in this structure:

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [model name], [N findings] (one bullet per reviewer)

### Act On
[Findings that should be addressed. For each: description, which models raised it, why it matters.]

### Consider
[Findings worth thinking about. For each: description, which models raised it, tradeoff involved.]

### Noted
[Valid but low-priority. Brief list.]

### Dismissed
[Rejected findings with brief rationale. This shows the user what was filtered out and why, so they can override your judgment if they disagree.]

### Agreement Map
[Where did models agree, where did they diverge, and what does the pattern of agreement/disagreement tell us?]
