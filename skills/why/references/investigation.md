# Expanded historical investigation

Use when direct history leaves a material gap, sources conflict, or the user
requests broad coverage. Reuse the code anchor and findings already collected.

## Model resolution

Resolve `why.investigators` and `why.synthesizer` from the canonical ostack
configuration at `$OSTACK_CONFIG_HOME/models.json`, or
`~/.config/ostack/models.json` when the variable is unset. Use the exact
override first, then the generic role (`exploration` or `prose`), then
`inherit`. A missing, invalid, or empty configuration is recoverable: report
the fallback once and use `inherit`.

Each investigator uses the first resolved entry, and the synthesizer is a
single-agent role that also uses its first entry. If a configured entry is
rejected, use `inherit` for that subagent; never select a nearby model ID. A
successful subagent call does not prove which model ran because the host may
silently substitute it.


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
