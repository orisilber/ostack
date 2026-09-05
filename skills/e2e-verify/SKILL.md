---
name: e2e-verify
description: "Verify UI changes through a repository's project-local verifier or a Playwright fallback, with web-first assertions, console-error capture, screenshots, and traces. Triggers \"e2e check\", \"verify in browser\", or \"test the UI\". Not static code review."
---

# E2E verify

Static checks can't see a broken UI. For user-facing changes, drive the real
thing before pushing. Prefer a script a reviewer can re-run when the flow is
likely to regress; for a one-off visual check, the captured evidence and exact
steps are enough.

## 0. Prefer the project-local verifier

From the repository root, search `.agents/skills/verify-*`,
`.cursor/skills/verify-*`, and `.claude/skills/verify-*`. If a verifier maps the
changed UI, read its `SKILL.md`, feature index, and affected feature files.

The project-local verifier owns the launch command, doctor check,
authentication, stable handles, feature recipe, evidence location, and
cleanup. This skill owns browser assertions, console-error capture, traces,
and the flake protocol. Do not install or create a second browser tool when the
local verifier provides one.

If a local instruction drifts, report it and use a current repository command
or observed path that exercises the same affected behavior. Point to
`maintain-verification-skill`; fail only when the behavior fails or remains
unverified. An unrelated passing flow does not substitute for that evidence.

## 1. Choose browser control

If the project-local verifier supplies a rerunnable browser command, use it. If
not, use a browser MCP to explore real selectors and confirm that the flow is
reachable. Encode what you learned as a script when the flow merits durable
coverage; otherwise record the observed path and run the focused check. An
interactive browser session is not rerunnable evidence, but it can be the right
scope for a one-off change.

## 2. Reuse the repository setup

- A project-local verifier comes first. Follow its commands and feature recipe.
- Existing `playwright.config.*` or e2e directory: follow its conventions
  exactly
  (fixtures, auth helpers, base URL, projects) and run through its own command:
  `npx playwright test <path> --reporter=line`.
- Cypress-only repository: use Cypress instead of adding a second framework.
- No local verifier or browser tool: run Playwright out of tree so the
  repository stays clean:

```bash
E2E=~/.cache/ostack-e2e; mkdir -p "$E2E" && cd "$E2E"
[ -d node_modules/@playwright/test ] || npm i -D @playwright/test@latest
npx playwright install chromium          # first run only
```

Write specs to `$E2E/<ticket>.spec.ts` and run
`npx playwright test <ticket>.spec.ts --reporter=line --trace on`.

Keep the script. Mention its path in the verdict, and offer to land it in the
repo's e2e dir when the flow is worth regression coverage.

## 3. Get the base URL and authentication from the repository

Use the project-local verifier first. Otherwise, read the repository's run or
development instructions. Do not assume `localhost:3000`.

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

## 4. Make the run deterministic

- Fixed viewport (`{ width: 1280, height: 800 }` default).
- UI shows time or relative dates → freeze it: `await page.clock.install({ time: new Date('2026-01-15T10:00:00Z') })`. `page.clock` needs Playwright 1.45+; on an older pin (check `npx playwright --version`) stub `Date` yourself with `page.addInitScript` and say which you used.
- Third-party or flaky endpoint in the flow → `page.route()` it to a fixture.
  Never mock the endpoint the change itself touches; that's how a green run
  proves nothing.
- Wait on signals, never `sleep`: web-first assertions (`await expect(locator).toBeVisible()`),
  `page.waitForResponse`, `locator.waitFor()`. A `waitForTimeout` in the final
  script is a bug.
- Prefer role/label/test-id locators over CSS paths. If the only stable handle is
  a CSS chain and the flow merits durable coverage, add a stable accessible
  handle or `data-testid` with the product change. Do not expand a one-off UI
  change solely to manufacture a selector.

## 5. Run the pass

Exercise the ticket's acceptance criteria as one user journey, using a script
when durable coverage is warranted and direct browser control otherwise:

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

If an intentional change alters a mapped UI route, entry point, or result,
update only the affected feature-map file before the final run. Leave a full
map audit to `maintain-verification-skill`.

## 6. Verdict format

```
E2E: PASS|FAIL
Verifier: <project-local path | fallback>
Flows: <what was driven>
Script or steps: <path and command | exact interactive path>
Screenshots: <paths>
Console errors: <none | list>
Suppressed: <none | the pre-existing noise you filtered>
```

On FAIL: the failing assertion, the last screenshot path, and the trace
(`npx playwright show-trace <path>`). Fix product code, adjust selectors freely
when the UI intentionally changed, and rerun the affected check. After three
failed fix-and-rerun cycles, `escalate`. Two unchanged transient failures require
diagnosis before any further retry.

## 7. Flake protocol

Allow one automatic re-run for a transient failure (a timeout with no assertion
mismatch). A step that fails twice without a change is a real bug or a bad
selector: open the trace and diagnose. Fix-and-rerun cycles are separate from
that transient retry budget. Never mark a flaky pass as PASS.

## 8. Cleanup

Kill any dev server or browser you started. Leave `artifacts/` and the trace for
the caller to inspect, gitignored, never committed. Leave `state.json` in place
so the next run skips the login.
