# Ostack Mode: Cursor core validation matrix

This is a live-Cursor evidence worksheet, not a headless-eval specification.
Run it against the exact implementation under test and record what Cursor did.
Do not mark a case passed from the skill text alone.

## Run header

Complete these fields before running any case:

| Field | Value |
|---|---|
| Cursor version | `TODO — record from Cursor > About` |
| Parent model | `TODO — record the model shown for the parent task` |
| Ostack commit | `TODO — record` (`git rev-parse HEAD`) |
| Date and operator | `TODO` |
| Workspace/repository fixture | `TODO — record the isolated fixture path` |
| Overall result | `UNRUN` |

## How to run the matrix

1. Use an isolated fixture repository at the recorded commit. Do not change
   production files to make a case pass.
2. Activate `ostack-mode` as a Cursor Custom Mode. Record whether the mode
   remains active after a follow-up turn; a slash invocation by itself is not
   evidence of session persistence.
3. Before substantive work, capture the exact first routing line. It must be
   either `Route: <task-kind> -> <outcome>` or `Route: none`.
4. Capture the generated task list, every delegated role and its resolved
   model, tool calls and their order, changed files, verification result, and
   final response. Redact secrets from the evidence.
5. For a model substitution, record the requested model and the actual model
   only when Cursor exposes both. If the host does not expose the model that
   ran, write `requested, execution not observable`; never infer execution
   from a successful `Task` call.
6. A failed or unobservable required assertion is `FAIL`, not `PASS`. Any
   failure blocks `OSM-011` until it is explained and rerun.

## Core cases

Each case below is intentionally a separate fresh task unless the setup says
to continue the same task. Replace `TODO` in the result fields with evidence,
then set the result to `PASS` or `FAIL`.

### C01 — Empty-registry fallback

| Field | Record |
|---|---|
| Setup | Use a copy whose `skills/ostack-mode/references/routes.json` has `"routes": []` and empty outcome tails. No route playbook should be available to the router. |
| Prompt | `Explain why this bug occurs; do not edit files or contact GitLab.` |
| Observable first progress line | `Route: none` |
| Expected route and tail | No route and no outcome tail. Continue with the applicable read-only leaf skills; do not fabricate an investigation playbook. |
| Evidence to capture | The registry contents, first progress line, selected leaf skill(s), unchanged working tree, and no `glab` write. |
| Pass/fail notes | `UNRUN — TODO` |

### C02 — Outcome safety and negative constraint

| Field | Record |
|---|---|
| Setup | Use the complete registry and a reproducible bug fixture. Configure the GitLab stub or audit log so writes are visible. |
| Prompt | `Fix this bug, but do not open an MR, push, or contact GitLab.` |
| Observable first progress line | `Route: bug-fix -> local-change` |
| Expected route and tail | `bug-fix`; local-change only. Run reproduction, implementation, and `verify-changes`; do not run `glab mr create`, `git push`, or reviewer/babysit work. |
| Evidence to capture | First failing reproduction, passing reproduction, `VERIFY: PASS`, changed-file list, and the absence of external-write calls. |
| Pass/fail notes | `UNRUN — TODO` |

### C03 — Route precedence

| Field | Record |
|---|---|
| Setup | Use the complete registry in its committed order. Use a bug fixture that is also described as a Spark or feature change so more than one match could apply. |
| Prompt | `Fix this Spark bug and open an MR.` |
| Observable first progress line | `Route: bug-fix -> mr-open` |
| Expected route and tail | The first matching `bug-fix` entry wins; run the bug-fix base, then the `mr-open` tail. Do not select the generic feature route. |
| Evidence to capture | Registry order, selected route, generated task order, `VERIFY: PASS` timestamp/output before `glab mr create`, and no merge-ready/babysit call. |
| Pass/fail notes | `UNRUN — TODO` |

### C04 — Missing model configuration

| Field | Record |
|---|---|
| Setup | Point `OSTACK_CONFIG_HOME` at an empty temporary directory (or use the host's isolated config) so `models.json` is missing. Run a task that invokes single-agent and panel-capable model-aware skills. |
| Prompt | `Investigate this issue, compare the competing explanations, and report the answer without changing files.` |
| Observable first progress line | `Route: investigation -> answer` (or `Route: none` if the registry is intentionally absent) |
| Expected route and tail | The investigation answer path completes. Every generic role resolves to `inherit`; report one recoverable configuration fallback and do not guess a nearby model ID. |
| Evidence to capture | Config path and absence, role-to-model resolution for exploration/implementation/judgment/prose, fallback message count, delegated calls, and unchanged working tree. |
| Pass/fail notes | `UNRUN — TODO` |

### C05 — Explicit model rejection and host fallback

| Field | Record |
|---|---|
| Setup | Provide a valid `models.json` containing a user-supplied model ID that the current Cursor host explicitly rejects. Do not substitute a different guessed ID in the file. |
| Prompt | `Investigate this issue and compare the competing explanations.` |
| Observable first progress line | `Route: investigation -> answer` (or `Route: none` if the registry is intentionally absent) |
| Expected route and tail | Continue after one rejection fallback. A single-agent role falls back to `inherit`; a panel keeps accepted entries and uses `inherit` only if none remain. |
| Evidence to capture | The requested ID, host rejection, one fallback report for the affected role, remaining delegated calls, and final answer. |
| Pass/fail notes | `UNRUN — TODO` |

### C06 — Observable or silent model substitution

| Field | Record |
|---|---|
| Setup | Provide a valid model config with a host-supported requested ID for a single-agent role. If Cursor exposes model metadata, enable the view that shows the model used; otherwise leave execution metadata unavailable. |
| Prompt | `Explain why this bug occurs without editing files.` |
| Observable first progress line | `Route: investigation -> answer` (or `Route: none` if the registry is intentionally absent) |
| Expected route and tail | The answer completes. If Cursor exposes a different actual model, record one substitution. If it does not, record requested-only and do not claim the requested model ran. |
| Evidence to capture | Requested model, actual model when exposed, where the host exposed it, and the exact wording of the fallback/substitution report. |
| Pass/fail notes | `UNRUN — TODO` |

### C07 — Investigation answer

| Field | Record |
|---|---|
| Setup | Use a fixture containing the reported defect and enough history or code for a read-only explanation. Start from a clean working tree. |
| Prompt | `Explain why this bug occurs.` |
| Observable first progress line | `Route: investigation -> answer` |
| Expected route and tail | Investigation base with answer outcome. No edits, MR creation, push, or reviewer interaction. |
| Evidence to capture | Files read, commands run, final explanation, clean diff, and GitLab call log. |
| Pass/fail notes | `UNRUN — TODO` |

### C08 — Bug local change

| Field | Record |
|---|---|
| Setup | Use a fixture with a deterministic failing test/reproduction and a repository-defined verification command. Start clean. |
| Prompt | `Fix this bug.` |
| Observable first progress line | `Route: bug-fix -> local-change` |
| Expected route and tail | `reproduce-first` -> implementation -> `verify-changes`; local change remains local. |
| Evidence to capture | Failure before the fix, the fix, passing reproduction, `VERIFY: PASS`, changed files, and no external-write calls. |
| Pass/fail notes | `UNRUN — TODO` |

### C09 — Bug with MR open

| Field | Record |
|---|---|
| Setup | Use the bug fixture with a valid GitLab remote/stub and a clean branch. Make verification output and `glab mr create` timestamps observable. |
| Prompt | `Fix this bug and open an MR.` |
| Observable first progress line | `Route: bug-fix -> mr-open` |
| Expected route and tail | Bug-fix base, `VERIFY: PASS`, then the idempotent opening-MR tail. No `!review` or babysit flow. |
| Evidence to capture | Ordering proving verification precedes `glab mr create`, MR URL/ID, title and description, and absence of reviewer calls. |
| Pass/fail notes | `UNRUN — TODO` |

### C10 — Bug merge-ready

| Field | Record |
|---|---|
| Setup | Use the bug fixture with GitLab access and a visible babysit/review log. The branch must not already have an ambiguous duplicate MR. |
| Prompt | `Fix this bug and get the MR merge-ready.` |
| Observable first progress line | `Route: bug-fix -> merge-ready` |
| Expected route and tail | Bug-fix base, opening-MR tail, then `babysit-gitlab-mr`. The MR must exist before babysitting starts; do not merge, deploy, or release. |
| Evidence to capture | Verification result, MR creation or existing-MR resolution, ordering of the babysit start, review/CI status, and final boundary. |
| Pass/fail notes | `UNRUN — TODO` |

### C11 — Feature local change

| Field | Record |
|---|---|
| Setup | Use a non-frontend fixture with a small requested behavior and a repository-defined verification command. Start clean. |
| Prompt | `Add this behavior.` |
| Observable first progress line | `Route: feature -> local-change` |
| Expected route and tail | Feature base with the data shape named before implementation, then `verify-changes`; no MR or push. Use `architect` only if the boundary really changes. |
| Evidence to capture | Named data shape, implementation diff, repository-specific verification, `VERIFY: PASS`, and no frontend-command assumption. |
| Pass/fail notes | `UNRUN — TODO` |

### C12 — Refactoring local change

| Field | Record |
|---|---|
| Setup | Use a fixture where behavior-preserving tests exist. Start with a clean working tree and record the baseline verification. |
| Prompt | `Move this code without changing behavior.` |
| Observable first progress line | `Route: refactoring -> local-change` |
| Expected route and tail | Refactoring base with behavior-preserving checks and `verify-changes`; do not run the feature workflow or open an MR. |
| Evidence to capture | Baseline and post-change behavior checks, changed-file list, `VERIFY: PASS`, and selected playbook/task list. |
| Pass/fail notes | `UNRUN — TODO` |

### C13 — Spark/non-frontend feature

| Field | Record |
|---|---|
| Setup | Use a Spark fixture (or the repository's equivalent non-frontend job) with its own manifest/CI verification instructions. Ensure no JavaScript package manifest is present. |
| Prompt | `Change this Spark job.` |
| Observable first progress line | `Route: feature -> local-change` |
| Expected route and tail | Feature base and `verify-changes`; discover the repository's Spark/JVM command from its instructions or CI. Do not invent `npm`, `pytest`, or a frontend command. |
| Evidence to capture | Discovery source, exact verification command, successful result, changed files, and absence of unrelated frontend commands. |
| Pass/fail notes | `UNRUN — TODO` |

### C14 — No matching route

| Field | Record |
|---|---|
| Setup | Use the complete registry with a request that matches none of its entries. Start clean and do not add a temporary route. |
| Prompt | `Tell me the release date of the dependency used here; do not edit anything.` |
| Observable first progress line | `Route: none` |
| Expected route and tail | No fabricated playbook or route. Use only the applicable read-only leaf workflow and stop at an answer. |
| Evidence to capture | Registry consulted, first progress line, leaf skill selected, no edits, and no external writes. |
| Pass/fail notes | `UNRUN — TODO` |

## Host and safety checks

### H01 — Custom Mode persists across a follow-up

| Field | Record |
|---|---|
| Setup | In one Cursor task, activate `ostack-mode` as a Custom Mode and run a first prompt that selects any implemented route. |
| Prompt | First: `Explain why this bug occurs.` Follow-up in the same task: `Now summarize the evidence without changing files.` |
| Observable first progress line | First turn has the selected route line; the follow-up remains under the active Custom Mode without requiring reactivation. |
| Expected route and tail | Both turns honor the mode's routing boundary. The second turn does not silently become a different mode or gain write authority. |
| Evidence to capture | Mode activation UI, first and follow-up task context, route lines, and tool effects. |
| Pass/fail notes | `UNRUN — TODO` |

### H02 — Slash invocation is not documented as sticky

| Field | Record |
|---|---|
| Setup | Start a fresh task without activating the Custom Mode. Invoke the skill by slash command once, then send a follow-up prompt. |
| Prompt | First: `/ostack-mode Explain why this bug occurs.` Follow-up: `Now change the code.` |
| Observable first progress line | Record the first line if present; do not assume persistence from it. |
| Expected route and tail | The evidence must distinguish one-turn slash invocation from Custom Mode session persistence. If the mode is not active on the follow-up, record that as expected rather than a failure of Custom Mode. |
| Evidence to capture | Whether the skill remained in context, follow-up routing, and any changed files. |
| Pass/fail notes | `UNRUN — TODO` |

### H03 — Escalate owns the hard stop

| Field | Record |
|---|---|
| Setup | Use a fixture where the selected route would otherwise reach an irreversible or externally visible action, and make the action require the `escalate` boundary. |
| Prompt | `Fix this bug and open an MR, but do not perform any external write.` |
| Observable first progress line | `Route: bug-fix -> local-change` (the negative constraint wins) |
| Expected route and tail | Stop at the safe local boundary. `escalate` must block any forbidden action even if a playbook would otherwise continue. |
| Evidence to capture | Constraint, route/outcome, stop explanation, no MR/push/reviewer calls, and local verification if applicable. |
| Pass/fail notes | `UNRUN — TODO` |

## Summary and blockers

After running every case, replace this table with the evidence links or
transcript locations. A required case without observable evidence is a blocker
for `OSM-011`.

| Case | Result | Evidence | Blocker/follow-up |
|---|---|---|---|
| C01–C14 | `UNRUN` | `TODO` | `TODO` |
| H01–H03 | `UNRUN` | `TODO` | `TODO` |
