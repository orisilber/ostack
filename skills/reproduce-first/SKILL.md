---
name: reproduce-first
description: For bug tickets. Write a failing test that reproduces the reported behavior before attempting any fix, then fix against it. Triggers "reproduce the bug", "failing test first", "bug ticket". Not for features or refactors.
---

# Reproduce First

A bug you can't reproduce, you can't fix, and a fix without a failing test
first is a guess that might regress later.

## Order is mandatory

1. RED: test exists, fails for the reported reason
2. Fix code (never touch the test's assertions)
3. GREEN: same test passes
4. `verify-changes` → commit as two commits:
   - `test: reproduce #<iid>` (the failing-state test)
   - `fix: <what> (#<iid>)`

## 1. Extract repro conditions from the report

From the ticket: expected vs actual, exact input, environment, steps. Anything
missing → that's what clarify-requirements should have covered; if still
missing, attempt with the most literal reading of the report.

## 2. Write the smallest failing test

- Placement + framework = repo conventions (`test/`, `__tests__/`, `*_test.go`,
  pytest). Find sibling tests of the affected module and mimic one.
- Smallest = reproduces the defect with minimum setup; no shotgun assertions.
- Deterministic: fixed clock/seed/locale where relevant; no network (mock it).

## 3. Confirm RED honestly

Run it. The failure mode must match the reported symptom:

- Test passes immediately → either bug is already fixed (comment on the ticket
  saying so, close via babysit flow) or you misread the report. Do not invent a
  different bug to have something red.
- Failure is unrelated (env broken, import error) → fix the harness, not yet
  the product code.

## 4. Fix, then protect

Implement the minimal fix. Re-run the repro test AND its neighbors in the same
file/directory to catch regressions. If fixing requires changing the test's
assertions, stop: either the report was wrong (escalate) or you're writing a
different feature than reported.

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

- Never change an existing test to match a wrong implementation, and never weaken
  an assertion unless the expected behavior genuinely changed and you can say how.
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
