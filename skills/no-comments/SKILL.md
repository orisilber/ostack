---
name: no-comments
description: "Spawn Comment Sicko, fix accepted findings, and offer encodings for claimed constraints."
disable-model-invocation: true
---

# No comments

Spawn Comment Sicko. Act on accepted findings.

Authoring agents defend comments. Defer to Comment Sicko's fresh perspective.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, default `main`, including the working tree.

## Steps

1. **Spawn the reviewer.** Spawn the named `comment-sicko` subagent and pass the scope. If the host lacks named agent aliases, locate the installed ostack `agents/comment-sicko.md` definition and give its complete contents and the scope to a fresh, read-only delegated agent on the parent model. Do not paraphrase its rules. If neither delegation path is available, mark this review incomplete, report the missing capability, and continue independent work; do not replace independent review with the authoring agent's judgment or claim the review passed.
2. **Reject bad findings.** Reject scope escapes, deletion proposals that a keep exception protects, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty.
3. **Accept the rest.** The parent applies every accepted comment deletion; the read-only reviewer never edits files. A reshape flag on a surprise in our own code stays actionable, and its comment still gets deleted. A keep survives only with proof that it is about something we cannot change.
4. **Audit suppressions.** Check for scoped lint and TypeScript suppressions the reviewer missed. A suppression that silences a correctness or safety rule stays an actionable `MUST KILL`.
5. **Check thin claims.** Before accepting a thin `IMPORTANT` or `do not remove` kill or keep, run `how` or `why` on its symbol. Step 8 governs unresolved constraint claims. For ordinary narration, delete ambiguous kills and keeps.
6. **Rerun once.** Rerun one rejected report with the failure named. If the second report is also rejected, report it open and fail `/no-comments`.
7. **Fix accepted flags.** Fix trivial flags directly by deleting a dead path, dropping a parameter, or using the real API. When a fix needs a new shape, write the caller's usage and types first and check them against the design red flags in the **principles** skill. Implement the smallest root-cause fix in scope and remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. Never bolt on symptom guards, and never widen the scope to fix instances outside it.
8. **Encode constraints.** Constraint comments say `do not remove`, `do not change wording`, or `talk to X before changing`. Leave keeps about things we cannot change. Encode an established constraint with the cheapest in-scope type, runtime check, test, or CI lint, then delete the comment. The caller's existing authority covers reversible encodings that preserve established behavior. If semantics or scope remain unresolved, keep the constraint until clarified, report it open, and continue with the rest. Neither deleting the comment nor silence authorizes changing the behavior it protects.
9. **Report** the deletion count, restored comments, reruns, fixes, encodings, encoding offers, unenforced constraints, and other open work.
