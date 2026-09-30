---
name: interrogate
description: Adversarial review of a diff. A fresh-context reviewer attacks it, then one lead judgment sorts every finding into act-on / consider / noted / dismissed. Triggers "interrogate", "adversarial review", "stress test this", "tear this apart". Use only on a changeset you want broken; it never auto-applies fixes, and a repo-local review skill wins where one exists.
disable-model-invocation: true
---

# Interrogate

Spawn a reviewer that has not seen the authoring work, give it the intent and
rubric, and judge its findings by demonstrated impact and source evidence. The
value comes from the fresh context, not from the number of reviewers.

The deliverable is a synthesized verdict. Do not auto-apply changes.

## Reviewers

Run one reviewer on the parent model by default: omit the subagent `model`
argument. When the user names other models in the request, add one reviewer per
named model as a second opinion. Different models miss different bugs, so a
named second opinion is worth its cost; an unnamed panel on the same model is
not. If the host rejects a named model, say so and continue with the rest. Do
not substitute a nearby model.

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

Launch every reviewer in a single message and label them in spawn order
(Reviewer A, Reviewer B, and so on).

For each reviewer:
- `subagent_type`: `generalPurpose` in Cursor; `Explore` (read-only) or `general-purpose` in Claude Code
- `model`: omitted for the default reviewer; the named model for a second opinion
- `readonly`: `true`

Read `references/reviewer-prompt.md` and fill in the template with:
1. The stated intent
2. The diff or file contents
3. The review rubric from `references/rubric.md`
4. The code-quality lens from `references/code-quality-review.md`

Every reviewer gets the same filled template.

Each reviewer produces structured findings as described in the prompt template.

## Step 4, Synthesize

Check every finding against the source. Trace the claimed failure and its
actual impact before accepting it. With more than one reviewer, merge
duplicates, note which reviewers raised each finding, and record explicit
disagreements. Agreement directs attention; it never sets severity.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator.

Read `references/lead-judgment.md` for the full framework. Reviewers only see a slice of the codebase. You have the full context (the goal, the constraints, the timeline, which tradeoffs were already considered). Use that context aggressively.

Categorize every finding using these buckets:

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. These would block a real PR.
- **Consider**. Legitimate points, but you're not sure they outweigh the cost of addressing them right now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact given the current stage.
- **Dismissed**. Wrong, nitpicky, or missing context. Brief explanation why.

Give each finding its category and a one-line rationale. With more than one
reviewer, also name who raised it.

## Output Format

Present the verdict in this structure:

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: model (parent or the named model) and finding count

### Act On
[Findings that should be addressed. For each: description and why it matters.]

### Consider
[Findings worth thinking about. For each: description and the tradeoff involved.]

### Noted
[Valid but low-priority. Brief list.]

### Dismissed
[Rejected findings with brief rationale. This shows the user what was filtered out and why, so they can override your judgment if they disagree.]

### Agreement Map
[Only when more than one reviewer ran: where they agreed, where they diverged, and what that tells us.]
