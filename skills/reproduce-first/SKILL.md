---
name: reproduce-first
description: For bug tickets — write a failing test that reproduces the reported behavior before attempting any fix, then fix against it. Triggers "reproduce the bug", "failing test first", "bug ticket". Use ONLY for defect work, not features or refactors.
---

# Reproduce First

A bug you can't reproduce, you can't fix — and a fix without a failing test
first is a guess that might regress later.

## Order is mandatory

1. RED: test exists, fails for the REPORTED reason
2. Fix code (never touch the test's assertions)
3. GREEN: same test passes
4. `verify-changes` → commit as TWO commits:
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
  saying so, close via babysit flow) or you misread the report. Do NOT invent a
  different bug to have something red.
- Failure is unrelated (env broken, import error) → fix the harness, not yet
  the product code.

## 4. Fix, then protect

Implement the minimal fix. Re-run the repro test AND its neighbors in the same
file/directory to catch regressions. If fixing requires changing the test's
assertions — stop: either the report was wrong (escalate) or you're writing a
different feature than reported.

## Cannot reproduce after 3 honest attempts

→ `escalate` with: exact attempts tried, environments, and your best hypothesis.
Do NOT ship a speculative fix.
