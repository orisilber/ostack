---
name: e2e-verify
description: Verify UI changes with real browser automation — Playwright flows, behavior assertions, and screenshots at key states. Triggers "e2e check", "verify in browser", "test the UI", "screenshot verification". Use ONLY for runtime UI verification, not static code review.
---

# E2E Verify

Static checks can't see a broken UI. For user-facing changes, drive the real
thing before pushing.

## 1. Reuse the repo's setup — don't import your own

- Existing `playwright.config.*` / `cypress.config.*` / e2e dir → follow its
  conventions exactly (fixtures, auth helpers, base URL).
- None → start the app dev server, write ONE standalone Playwright script
  (`npx playwright` available via npx), delete nothing afterward; save it under
  the repo's script location and mention it to the caller.

## 2. Deterministic by construction

- Fixed viewport (1280×800 default), fixed test data, seeded/fixed clock if the
  UI shows time.
- Auth: reuse the repo's test login helper; never hardcode real credentials —
  read from env/config the repo already defines.
- Wait on signals (element visible, network idle), never `sleep`.

## 3. The pass

Script the ticket's acceptance criteria as a user journey:

1. Arrange: navigate + authenticate + seed state
2. Act: perform the changed flow
3. Assert: behavior (text present/absent, element states, navigation) AND
   screenshot at each key state into `e2e-artifacts/` (gitignored)
4. Capture console errors throughout — any new console error = failure,
   even if visuals look right

## 4. Verdict format

```
E2E: PASS|FAIL
Flows: <what was driven>
Screenshots: <paths>
Console errors: <none | list>
```

On FAIL: include the failing assertion + last screenshot path. Fix product code
(adjust selectors freely if the UI intentionally changed), re-run max 3 times
→ `escalate`.

## 5. Flake protocol

One automatic re-run for transient failures (timeout with no assertion
mismatch). A step that fails twice is a real bug or a bad selector — diagnose,
don't retry a third time.

## 6. Cleanup

Kill any dev server or background process you started. Leave `e2e-artifacts/`
for the caller to inspect; never commit it.
