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

1. Spawn the named `comment-sicko` subagent and pass the scope. If the host lacks named agent aliases, locate the installed ostack `agents/comment-sicko.md` definition and give its complete contents and the scope to a fresh, read-only delegated agent with an inherited model. Do not paraphrase its rules. If neither delegation path is available, mark this review incomplete, report the missing capability, and continue independent work; do not replace independent review with the authoring agent's judgment or claim the gate passed.
2. Inspect its report. Reject scope escapes, exception-protected deletion proposals, misstated `MUST KILL` reasons, and flags that treat kept intentional code as guilty. The parent applies every accepted ordinary comment deletion; the read-only reviewer never edits files. Reshape flags on our-code surprises stay actionable, and their comments still get deleted. A keep survives only with proof it is about something we cannot change. Audit missed scoped lint and TypeScript suppressions. Correctness or safety suppressions stay actionable `MUST KILL`s. Before accepting thin `IMPORTANT` or `do not remove` kills or keeps, run `/how` or `/why` on their symbol. Step 5 governs unresolved constraint claims. For ordinary narration, delete ambiguous kills or keeps. Rerun one rejected report with the failure named. Reject a second, report it open, and fail `/no-comments`.
3. Fix trivial accepted flags directly by deleting a dead path, dropping a parameter, or using the real API. If any fix needs a shape, run `architect design-only` once for the accepted set and surrounding code. Stop at the sketch. Architect shapes. Step 4 implements.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, land the smallest in-scope fix and report the rest open. The root-cause and redesign rules in the **principles** skill guide intent only: fix real causes, redesign as if requirements always existed, never bolt on symptom guards. Neither authorizes widening the fence nor fixing instances outside it.
5. Constraint comments say `do not remove`, `do not change wording`, or `talk to X before changing`. Leave keeps about things we cannot change. Encode an established constraint using the cheapest in-scope type, runtime check, test, or CI lint, then delete the comment. The caller's existing authority covers reversible encodings that preserve established behavior; do not request separate approval for routine implementation choices. If semantics or scope remain unresolved, preserve the constraint until clarified, report that item open, and continue the rest. Neither deleting the comment nor silence authorizes changing the behavior it protects.
6. Report the deletion count, restored comments, reruns, architect sketch, fixes, encoding offers, encodings, unenforced constraints, and other open work.
