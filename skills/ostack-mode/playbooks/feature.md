# Feature playbook

Use this route when the user asks for new behavior.

1. Name the data shape, boundary, and acceptance behavior before editing.
2. Run `how` over the affected subsystem.
3. Run `architect` when a public function, class, type, or ownership boundary
   crosses modules. Record `architect skipped: <reason>` for a small change
   that follows an existing local pattern.
4. Run `arena` only when the user requests competing implementations or the
   task exposes incompatible boundaries or interactions. Otherwise record why
   it was not needed.
5. Implement the smallest complete vertical slice and its focused tests.
6. Run `verify-changes` and report the exact checks and result.

MR creation and reviewer interaction remain outcome tails. Do not infer them
from a branch, ticket, or a completed local change.
