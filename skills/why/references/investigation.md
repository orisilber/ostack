# Expanded historical investigation

Use when direct history leaves a material gap, sources conflict, or the user
requests broad coverage. Reuse the code anchor and findings already collected.

## Choose sources

Read [source-playbook.md](source-playbook.md), then select categories by the
remaining question. Source control, tickets, documents, chat, observability,
errors, and analytics can each help, but none is mandatory merely because its
tool is installed. Verify relevant connectors or CLI access on this host before
claiming a source is available.

## Search

Search one or two sources directly in the parent. When the user asked for broad
coverage across several independent sources, run one read-only investigator per
source in parallel. Give each [investigator-prompt.md](investigator-prompt.md),
its one source playbook, the question, and the shared code anchor.
Investigators run on the parent model: omit the subagent `model` argument
unless the user named a model. Use
[sources/incident-postmortem.md](sources/incident-postmortem.md) only when an
incident could explain the defensive behavior.

Use the host's supported read-only mode when it retains the needed tools.
If a host strips read connectors in that mode, use the minimum supported mode
and explicitly limit the investigator to reads.

Keep full source records available, with compact findings in the parent.
Record a null result as no match within the searched query and access scope.
Never infer that a ticket or decision did not exist from one failed search.

## Synthesis

Synthesize in the parent using [answer-format.md](answer-format.md) and
[epistemics.md](epistemics.md). Preserve confidence qualifiers and reconcile
conflicting records before writing a causal account. A single-source answer
can be conclusive when the source explicitly records the decision.
