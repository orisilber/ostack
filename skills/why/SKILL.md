---
name: why
description: Recover design rationale, regressions, and the origin of a code decision from cited history. Start with directly linked evidence and expand when a material gap remains. Runtime flow belongs to how.
---

# Why

Answer the historical question from evidence. Pin the named symbol, decision, or
time period, then inspect the relevant code and its introducing or changing
commits. Follow directly linked reviews, tickets, or design records.

## Start small

Use blame on the relevant lines and bounded history for the target file. Follow
renames or older commits when needed; do not dump full file history by default.
Read the review or ticket that states the rationale. If it directly answers the
question without a material contradiction, give the cited answer and stop.

A source comment may explicitly document intent. Inferring intent from code
shape alone is weaker evidence and must be labeled as inference. Do not turn an
empty search into a claim that the decision was never documented or ticketed.

## Expand when evidence warrants it

For an unresolved gap, conflicting sources, or an explicitly broad investigation,
read [references/investigation.md](references/investigation.md). It covers model
resolution and independent investigators. Use the smallest relevant set of
sources from [references/source-playbook.md](references/source-playbook.md),
then load only the matching source playbooks. Tool availability is not a reason
to search an unrelated service.

When the evidence is thin or contradictory, use
[references/epistemics.md](references/epistemics.md) to calibrate confidence.
For a substantial delegated synthesis, use
[references/synthesizer-prompt.md](references/synthesizer-prompt.md); a simple
answer does not require another agent or the full reporting template.

## Return

Lead with the best-supported explanation and cite its concrete evidence.
Separate facts from inference, show material contradictions, and name meaningful
gaps with the query and permission scope. Report sources actually consulted;
do not produce an all-source checklist for a one-commit answer.

When the question precedes a change, translate relevant findings into
constraints to preserve, change, or avoid. Keep the user's original scope.
