# Expanded historical investigation

Use when direct history leaves a material gap, sources conflict, or the user
requests broad coverage. Reuse the code anchor and findings already collected.

## Model resolution

Resolve `why investigators` and `why synthesizer` from
`~/.cursor/rules/ostack-models.mdc`. For each role use its skill-role line
first, then its generic role line, then `inherit`.

| Role | Generic role |
|---|---|
| `why investigators` | `exploration` |
| `why synthesizer` | `prose` |

Every investigator uses the first entry resolved for `why investigators`. The
synthesizer is a single-agent role and uses its own first entry. A subagent
whose entry the host rejects runs on `inherit`.

Pass the resolved value as the subagent `model` argument. `inherit` means omit
`model` and let the subagent run on the parent chat model. A line never mixes
`inherit` with a model ID. Hosts that do not load the rule resolve every role
to `inherit`. When the host rejects a model ID, do not swap in a nearby one. A
successful call proves nothing about which model ran, because the host may
substitute one without saying so.

## Choose and assign sources

Read [source-playbook.md](source-playbook.md), then select categories by the
remaining question. Source control, tickets, documents, chat, observability,
errors, and analytics can each help, but none is mandatory merely because its
tool is installed. Verify relevant connectors or CLI access on this host before
claiming a source is available.

Delegate independent source searches when that saves time. A narrow search can
stay in the parent or one worker. Give each investigator
[investigator-prompt.md](investigator-prompt.md), its one source playbook, the
question, and the shared code anchor. Use
[sources/incident-postmortem.md](sources/incident-postmortem.md) only when an
incident could explain the defensive behavior.

Use the host's supported read-only mode when it retains the needed tools.
If a host strips read connectors in that mode, use the minimum supported mode
and explicitly limit the investigator to reads. Do not assume Cursor, Claude,
or Codex exposes the same tool or model controls.

Keep full source records available, with compact findings in the parent.
Record a null result as no match within the searched query and access scope.
Never infer that a ticket or decision did not exist from one failed search.

## Synthesis

The parent can synthesize directly. For a large set of independent findings,
delegate using [synthesizer-prompt.md](synthesizer-prompt.md) and
[epistemics.md](epistemics.md). Preserve confidence qualifiers and reconcile
conflicting records before writing a causal account. A single-source answer
can be conclusive when the source explicitly records the decision.
