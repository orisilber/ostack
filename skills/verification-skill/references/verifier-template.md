# Verifier template

Copy this into `verify-{{app}}/SKILL.md` and replace every `{{...}}` marker
with repository evidence. `scripts/lint-verifier.py` fails while any marker
remains.

```markdown
---
name: verify-{{app}}
description: Verify {{app}} through its {{interface}}. Use after changing {{user-facing areas}} or when a task needs proof that {{app}} still works for a user.
---

# Verify {{app}}

Last verified: {{commit sha, or `never` for a draft}}

## Source anchors

| Path | Defines | Features |
|---|---|---|
| `{{path}}` | {{checks, launch, auth, harness, or routes}} | {{feature IDs, `unmapped`, or blank}} |

## Repository checks

- `{{command}}` in `{{working directory}}`, declared in `{{file}}`. Focused form: `{{command}}`.

## Launch

{{Exact start command, readiness signal, isolation rule, and teardown.}}

## Doctor

{{One read-only command that checks the process, build, port, data directory, and authentication.}}

## Drive

{{Harness, stable handles, and how to run a feature recipe from `features/`.}}

## Evidence

{{Artifact location and proof standard: user action, result, and a second read-only view of stored side effects.}}

## Cleanup

{{Stop only processes this run started. Remove disposable state; keep evidence.}}
```

## Rules the linter enforces

- The sections above exist as H2 headings.
- `Last verified:` is followed by a commit SHA or `never`.
- Every path in the anchors table exists in the repository.
- Every feature ID in the anchors table has `features/<id>.md`, and every
  feature file is named by at least one anchor row.
- `features/README.md` links every feature file, every link resolves, and each
  linked entry ends with a status of `verified`, `draft`, or `verified-unreachable`.
- Each feature file has the H2 sections `Sub-features`,
  `How to get to it (user POV)`, `Driving it with <harness>`, and `Gotchas`,
  in that order.
