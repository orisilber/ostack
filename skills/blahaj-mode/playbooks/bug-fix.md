# Bug-fix playbook

Use this sequence when the user reports a defect and asks for a code change.
The first progress update must identify the selected outcome.

1. Extract expected behavior, actual behavior, reproduction conditions, and
   the affected surface.
2. Run `reproduce-first`. Keep the repro deterministic and do not weaken its
   assertion.
3. Use `how` for the affected runtime flow and `why` when regression history
   or an existing design decision could constrain the fix.
4. Form competing hypotheses and collect evidence that rules them in or out.
5. Use `architect` only when the fix crosses a function, module, or ownership
   boundary. Otherwise keep the change local.
6. Implement the smallest fix justified by the surviving evidence.
7. Run `verify-changes`, then report the failing-before and passing-after
   repro evidence.

The base playbook never opens an MR or contacts reviewers. Those actions are
separate outcome tails and require explicit authorization.
