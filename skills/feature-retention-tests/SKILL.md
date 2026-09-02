---
name: feature-retention-tests
description: Add durable automated coverage only after a new feature is fully implemented and proven through its real interface. Used by feature workflows; not for bug fixes or behavior-preserving refactors.
---

# Feature retention tests

Tests preserve accepted feature behavior. They do not drive feature implementation.

## Entry contract

Start only after the caller provides:

- the accepted behavior or done predicate;
- the completed implementation; and
- evidence that the feature was exercised through its real UI, API, CLI, or
  integration path without new feature-specific test code.

If any item is missing, return to implementation or acceptance verification.
Do not create tests yet.

## Choose retention coverage

Read the implementation diff, acceptance behavior, existing coverage, and
sibling tests. Protect the smallest stable, externally observable contracts
that would matter if they regressed.

Add no test when the behavior is already covered or meaningful coverage would
mostly test mocks, private structure, timing, or incidental rendering. Report
that decision and its evidence.

## Add tests last

Follow the repository's existing framework, placement, fixtures, and naming.

- Test accepted behavior and important edge cases discovered while exercising
  the completed feature.
- Prefer a real boundary over a private helper.
- Do not duplicate existing coverage or add shotgun assertions.
- Use snapshots only when the serialized or rendered output is itself the
  contract.
- Update an obsolete expectation only when the accepted feature intentionally
  changed that contract. Never weaken an unrelated assertion.
- Do not reshape working product code merely to make a test convenient.

## Prove the retention signal

Run the focused new or updated tests. When cheap and isolated, also show that a
new test fails against the pre-feature implementation or with the protected
behavior narrowly disabled. Never damage the working implementation to
manufacture a red run.

If a retention test fails against the accepted feature, diagnose the mismatch.
Do not redefine the accepted behavior or weaken the assertion just to make it
green.

Return:

- coverage added or skipped;
- accepted behaviors protected;
- focused commands and results;
- retention-signal evidence, or why it was not practical; and
- any behavior still lacking durable coverage.

The caller runs `verify-changes` after this skill completes.
