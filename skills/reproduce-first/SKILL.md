---
name: reproduce-first
description: For bug tickets. Write a failing test that reproduces the reported behavior before attempting any fix, then fix against it. Triggers "reproduce the bug", "failing test first", "bug ticket". Not for features or refactors.
---

# Reproduce First

Establish the reported failure before changing product code. Prefer a focused
test; use the executable or manual fallback below when a new test is impractical.

## Default order

1. RED: test exists, fails for the reported reason
2. Fix code without weakening a valid assertion
3. GREEN: same test passes
4. `verify-changes` → preserve the red-before/green-after evidence. Use two
   commits (`test: reproduce #<iid>` and `fix: <what> (#<iid>)`) when the
   repository or review process benefits from that separation; one coherent
   commit is fine when it keeps the evidence reviewable.

## 1. Extract repro conditions from the report

From the ticket: expected vs actual, exact input, environment, steps. Anything
missing: inspect the linked evidence first, then ask only for a material fact
that cannot be recovered. New evidence can justify a later clarification.

## 2. Write the smallest failing test

- Placement + framework = repo conventions (`test/`, `__tests__/`, `*_test.go`,
  pytest). Find sibling tests of the affected module and mimic one.
- Smallest = reproduces the defect with minimum setup; no shotgun assertions.
- Deterministic: fixed clock/seed/locale where relevant; no network (mock it).

## 3. Confirm RED honestly

Run it. The failure mode must match the reported symptom:

- Test passes immediately: investigate whether the bug is already fixed or the
  reproduction missed a condition. Report the evidence; comment on or close the
  ticket only when that tracker action is authorized. Do not invent another bug.
- Failure is unrelated (env broken, import error) → fix the harness, not yet
  the product code.

## 4. Fix, then protect

Implement the minimal fix. Re-run the repro test AND its neighbors in the same
file/directory to catch regressions. Do not weaken an assertion merely to make
the implementation pass. If the report or test encoded the wrong expected
behavior, stop and document that correction, then update the assertion only
after the intended behavior is established. A changed expectation is a behavior
decision, not a test workaround.

## When a unit test is the wrong tool

The failing test is the default, not a ritual. A test path is impractical when it
would need broad harness setup, brittle mocks, slow end-to-end infrastructure,
production-only state, or large unrelated fixture churn. Prefer no new test over a
bad one. A bad test mostly exercises mocks, encodes current implementation
details, depends on timing or global state, or would be deleted the moment it
proved the fix.

Impractical does not mean skip the step. Say out loud why the test isn't worth its
cost, then reproduce with the closest executable check you can re-run: a targeted
script, an `e2e-verify` flow, a snapshot comparison, a log assertion, a focused
integration check, or one documented manual command. The rule is unchanged: the
broken behavior is observable and failing before you touch product code.

Guardrails either way:

- Never change an existing test to match a wrong implementation. Change an
  assertion only when the expected behavior genuinely changed or the original
  report was shown to be mistaken, and record why.
- Keep the repro focused on this bug. Sibling coverage, if it's warranted, lands
  after the focused fix.
- A flaky bug gets a deterministic repro where possible; name the signal you
  locked down.

## Cannot reproduce after 3 honest attempts

→ `escalate` with: exact attempts tried, environments, and your best hypothesis.
Do not ship a speculative fix.

## Report the evidence, not the outcome

Name the failing-before check and the failure it produced, then the passing-after
run and any neighbors you ran with it. If you could not demonstrate a failing
state, say so explicitly and name the check you used instead. "Fixed and tested"
without those two lines is a self-report, which is exactly what `prove-it-works`
rejects.
