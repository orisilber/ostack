# Bug-fix playbook

Use this sequence when the user reports a defect and asks for a code change.
The first progress update must identify the selected outcome.

1. Extract expected behavior, actual behavior, reproduction conditions, and
   the affected surface.
2. Use only the RED/reproduction phase of `reproduce-first`: establish the
   smallest deterministic failing check for the reported behavior and stop
   before that skill's fix, GREEN, verification, or commit phases.
3. Route through `how` for the affected runtime flow and through `why` when
   regression history or an existing design decision could constrain the fix.
4. Form competing hypotheses and collect evidence that rules them in or out.
5. When the fix crosses a function, module, or ownership boundary, route through
   `architect` in `design-only` mode. Otherwise keep the change local.
6. Implement the smallest fix justified by the surviving evidence.
7. Route through `verify-changes`, then report the failing-before and
   passing-after repro evidence.

The base playbook never opens an MR or contacts reviewers. Those actions are
separate outcome tails and require explicit authorization.
