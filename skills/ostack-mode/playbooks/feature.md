# Feature playbook

Use this route when the user asks for new behavior.

1. Name the data shape, boundary, and acceptance behavior before editing.
2. Reuse current grounding; run `how` only for a material gap in behavior or ownership.
3. Run `architect` in `design-only` mode when a public boundary introduces a
   consequential unresolved shape. The caller retains implementation ownership. Record `architect skipped: <reason>` for a small change
   that follows an existing local pattern.
4. Reuse architect's comparison when it already covers the decision. Run `arena` when the user requests competing implementations, the task
   exposes incompatible boundaries or interactions, or one attempt would lock
   in a consequential choice between viable approaches. Otherwise record why
   it was not needed.
5. Implement the smallest complete vertical slice and its focused tests.
6. Run `verify-changes` and report the exact checks and result.

MR creation and reviewer interaction remain outcome tails. Do not infer them
from a branch, ticket, or a completed local change.
