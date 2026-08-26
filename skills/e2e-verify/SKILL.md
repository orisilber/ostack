---
name: e2e-verify
description: "Verify UI changes with real Playwright automation: scripted user flows, web-first assertions, console-error capture, screenshots. Triggers \"e2e check\", \"verify in browser\", \"test the UI\". Not static code review."
---

# E2E Verify

Static checks can't see a broken UI. For user-facing changes, drive the real
thing before pushing. The deliverable is a script a reviewer can re-run, not a
description of what you clicked.

## 0. Browser MCP vs. Playwright

If the host has a browser MCP (Playwright MCP, chrome-devtools MCP), use it to
*explore*: find the real selectors, watch the flow, confirm the change is even
reachable. Then encode what you learned as a Playwright script and run that.
The MCP session proves nothing to the next person; the script does.

## 1. Reuse the repo's setup, don't import your own

- Existing `playwright.config.*` or e2e dir → follow its conventions exactly
  (fixtures, auth helpers, base URL, projects) and run through its own command:
  `npx playwright test <path> --reporter=line`.
- Cypress-only repo → use Cypress rather than adding a second framework.
- Neither → run Playwright out-of-tree so the repo stays clean:

```bash
E2E=~/.cache/ostack-e2e; mkdir -p "$E2E" && cd "$E2E"
[ -d node_modules/@playwright/test ] || npm i -D @playwright/test@latest
npx playwright install chromium          # first run only
```

Write specs to `$E2E/<ticket>.spec.ts` and run
`npx playwright test <ticket>.spec.ts --reporter=line --trace on`.

Keep the script. Mention its path in the verdict, and offer to land it in the
repo's e2e dir when the flow is worth regression coverage.

## 2. Base URL and auth from the repo, never hardcoded

The dev URL comes from the repo's own run/dev-env skill or its `vite`/`dev`
script. Read it; don't assume `localhost:3000`.

Login once, headed, and save the session:

```ts
// login.spec.ts: run with --headed, once per expiry window
await page.goto(BASE_URL);
// ...complete SSO by hand if it needs a human...
await page.context().storageState({ path: process.env.E2E_STATE! });
```

Then every real spec starts authenticated:

```ts
test.use({ storageState: process.env.E2E_STATE! });
```

`storageState` is a live session token. Keep it outside the repo
(`~/.cache/ostack-e2e/state.json`), `chmod 600`, never commit it, never paste its
contents into a report. Credentials come from env or the repo's existing config.
If neither exists, `escalate` rather than inventing a test user.

## 3. Deterministic by construction

- Fixed viewport (`{ width: 1280, height: 800 }` default).
- UI shows time or relative dates → freeze it: `await page.clock.install({ time: new Date('2026-01-15T10:00:00Z') })`. `page.clock` needs Playwright 1.45+; on an older pin (check `npx playwright --version`) stub `Date` yourself with `page.addInitScript` and say which you used.
- Third-party or flaky endpoint in the flow → `page.route()` it to a fixture.
  Never mock the endpoint the change itself touches; that's how a green run
  proves nothing.
- Wait on signals, never `sleep`: web-first assertions (`await expect(locator).toBeVisible()`),
  `page.waitForResponse`, `locator.waitFor()`. A `waitForTimeout` in the final
  script is a bug.
- Prefer role/label/test-id locators over CSS paths. If the only stable handle is
  a CSS chain, add a `data-testid` in the product code. That's a real fix, not
  test scaffolding.

## 4. The pass

Script the ticket's acceptance criteria as one user journey:

1. **Arrange**: navigate, authenticate via `storageState`, seed state.
2. **Act**: perform the changed flow the way a user would.
3. **Assert**: behavior first (text present/absent, element state, URL,
   network call fired), and a screenshot at each key state:
   `await page.screenshot({ path: 'artifacts/03-after-apply.png', animations: 'disabled' })`.
4. **Capture errors throughout**: attach these before the first `goto`:

```ts
const errors: string[] = [];
page.on('console', m => m.type() === 'error' && errors.push(m.text()));
page.on('pageerror', e => errors.push(`pageerror: ${e.message}`));
page.on('requestfailed', r => errors.push(`requestfailed: ${r.url()}`));
// ...at the end:
expect(errors.filter(e => !KNOWN_NOISE.some(n => e.includes(n)))).toEqual([]);
```

Any new console error fails the run even when the visuals look right. Suppress
only pre-existing noise, and list what you suppressed in the verdict. An
expected 4xx that the app already tolerates is noise; a new one is the bug.

A screenshot is evidence only if you looked at it. Read every capture before
declaring PASS; a blank page passes a lazy gate.

## 5. Verdict format

```
E2E: PASS|FAIL
Flows: <what was driven>
Script: <path, re-runnable command>
Screenshots: <paths>
Console errors: <none | list>
Suppressed: <none | the pre-existing noise you filtered>
```

On FAIL: the failing assertion, the last screenshot path, and the trace
(`npx playwright show-trace <path>`). Fix product code, adjust selectors freely
when the UI intentionally changed, re-run max 3 times, then `escalate`.

## 6. Flake protocol

One automatic re-run for a transient failure (a timeout with no assertion
mismatch). A step that fails twice is a real bug or a bad selector: open the
trace and diagnose. Never retry a third time, and never mark a flaky pass as
PASS.

## 7. Cleanup

Kill any dev server or browser you started. Leave `artifacts/` and the trace for
the caller to inspect, gitignored, never committed. Leave `state.json` in place
so the next run skips the login.
