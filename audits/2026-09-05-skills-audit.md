# Ostack skills audit — 5 September 2026

Ostack has useful workflow knowledge, but several skills turn ordinary work into mandatory research, design, review, or permission loops. The highest-value change is to make those workflows conditional and composable, while preserving concrete verification, evidence, and authorization requirements. Some executable examples also need correction before they can support reliable automation.

The findings below describe the original snapshot at `2b2c02e`. The first
implementation left several findings incompletely fixed. A second review
corrected those gaps and reconciled the branch with `main` at `689da91`.
The implementation and observed validation are recorded at the end.

**Scope and basis**

Read Eric Provencher’s full [“Rethinking skills and prompts for GPT-6 Astra”](https://x.com/pvncher/status/2095991462416490862) in the browser. Its recommendations are the audit rubric: precise descriptions, conditional loading, less prescriptive procedure, clear completion criteria, and boundaries that preserve already authorized work. It also cautions that contributors using other models may still benefit from more guidance. That supports selective simplification rather than deleting every workflow.

The review covered all **26 production skills and all 78 files under `skills/`**, including playbooks, references, scripts, and agent metadata. It also inspected the installer, README, lint/validation machinery, and relevant evaluation material. The additional `SKILL.md` under `evals/fixtures/ostack-mode-validator/valid-root/` is a six-line test fixture, not a 27th production skill.

A filesystem walk including hidden and ignored paths, excluding Git internals, found **zero AGENTS.md, AGENTS.override.md, or CLAUDE.md files inside ostack**, and no symlinked directories hiding another instruction tree. Installed skills outside this checkout and other repositories are outside this audit.

The 26 root skill files contain 25,939 whitespace-delimited words. Their description lines alone contain 7,287 characters, before names and paths. These are inventory measurements, not tokenizer counts or evidence that this session’s index was truncated. The largest root files are `why` (23,122 bytes), `technical-writing` (11,614), and `deploy-watch` (9,847). File size matters most when broad triggers or unconditional calls load the contents unnecessarily.

**Changes with the greatest effect on agent behavior**

1. **Replace blanket stop rules with action-specific boundaries.** [escalate/SKILL.md:11](https://github.com/orisilber/ostack/blob/2b2c02e/skills/escalate/SKILL.md#L11) halts on all auth, billing, migration, infrastructure, and CI code, and defaults to stopping after 30 minutes. This includes reversible edits the user may have directly requested. The same file calls reversible work non-escalation material, then makes the hard stops win. Its silence-default instruction at line 58 also leaves unclear whether a permission question can time out into action. Keep actual access limits, destructive operations, explicit user constraints, and user-set budgets. Separate editing sensitive-area source from executing consequential operations. Preserve previous authorization; continue independent safe work while a required answer is pending; silence must not grant missing authority. These constraints belong in a small shared policy or relevant repository instructions, with a detailed escalation template loaded only when needed.

2. **Make architecture comparison conditional and give callers control of implementation.** [refactoring.md:6](https://github.com/orisilber/ostack/blob/2b2c02e/skills/ostack-mode/playbooks/refactoring.md#L6) requires `how` and characterization evidence even for a rename or move, then invokes `architect` whenever a function or module boundary is crossed. [architect/SKILL.md:38](https://github.com/orisilber/ostack/blob/2b2c02e/skills/architect/SKILL.md#L38) repeats the grounding, requires arena and two different designs at lines 46–50, then defaults to implementation at lines 60–70. Yet [large-feature.md:8](https://github.com/orisilber/ostack/blob/2b2c02e/skills/ostack-mode/playbooks/large-feature.md#L8) calls architect before decomposition and worker ownership are established. This both overburdens mechanical work and creates an implementation-ownership conflict. Return a design to an orchestrating caller; implement directly only when that invocation owns implementation. Trigger alternatives on consequential unresolved choices, reuse existing grounding, and reuse sufficient existing tests.

3. **Stop ordinary historical questions from becoming exhaustive investigations.** [why/SKILL.md:114](https://github.com/orisilber/ostack/blob/2b2c02e/skills/why/SKILL.md#L114) defaults to every available evidence category and one investigator per category. [recall/SKILL.md:25](https://github.com/orisilber/ostack/blob/2b2c02e/skills/recall/SKILL.md#L25) inherits that sweep whenever a topic names a feature or subsystem, explicitly removing judgment. Start with the named task, code, and directly linked history. Broaden when the first evidence leaves a material gap or conflict. Keep comprehensive coverage as an explicit deep-investigation option. Make `why` a short router into its already useful source playbooks, confidence guidance, and synthesis instructions.

4. **Make logging help completion instead of adding an unavailable reviewer gate.** [show-me-your-work/SKILL.md:56](https://github.com/orisilber/ostack/blob/2b2c02e/skills/show-me-your-work/SKILL.md#L56) requires a transcript audit using Cursor/Claude locations, then line 67 requires another model family before handing back, without a fallback. This can stall an otherwise finished task on a host without those transcripts or models. Require truthful, resolvable evidence in the log; make the extra audit conditional on available tools and task value. Also reconcile append-only history at line 51 with instructions to cut or rewrite rows at lines 58–63. Appending a correction is a simple consistent default.

5. **Encode manual invocation using the current host’s setting.** Twelve skills declare `disable-model-invocation: true`, but only `create-verification-skill` and `maintain-verification-skill` include the documented Codex policy in `agents/openai.yaml`. The ten missing it are `architect`, `arena`, `blast-radius`, `interrogate`, `ostack-mode`, `recall`, `setup-ostack-mode`, `show-me-your-work`, `swarm`, and `technical-writing`. The [README’s explicit-invocation claim](https://github.com/orisilber/ostack/blob/2b2c02e/README.md#L107) therefore lacks the documented Codex configuration for those ten. Codex documents `policy.allow_implicit_invocation: false` in `agents/openai.yaml`, with implicit invocation enabled by default. Add the host-specific metadata where manual invocation is intended and test both positive and negative trigger prompts. This is a configuration finding, not a claim that all ten actually fired in a live session. [Official skill documentation](https://learn.chatgpt.com/docs/build-skills).

6. **Narrow broad triggers and reduce general advice in the public skill catalog.** [principles/SKILL.md:3](https://github.com/orisilber/ostack/blob/2b2c02e/skills/principles/SKILL.md#L3) applies to essentially every substantial engineering task; [typescript-best-practices/SKILL.md:3](https://github.com/orisilber/ostack/blob/2b2c02e/skills/typescript-best-practices/SKILL.md#L3) triggers on merely reading any TypeScript file. Much of both is general judgment or house style. Keep the unusual, useful conventions as short contextual rules with reference links; retain an explicit design-review skill only if it provides a distinct requested workflow. Consolidate the writing standards and optional `unslop` pass behind one writing workflow. Shorten descriptions around the actual task, not the technique inventory or a list of overlapping phrases. Codex loads metadata initially and may shorten descriptions or omit entries when the catalog exceeds its budget. [Official skill documentation](https://learn.chatgpt.com/docs/build-skills).

7. **Reuse verification evidence and avoid turning stale instructions into a product blocker.** [verify-changes/SKILL.md:35](https://github.com/orisilber/ostack/blob/2b2c02e/skills/verify-changes/SKILL.md#L35) requires FAIL when a project verifier has drifted even when current repository declarations are available. Line 85 assumes full-repository lint/typecheck are always cheap. [refactoring.md:15](https://github.com/orisilber/ostack/blob/2b2c02e/skills/ostack-mode/playbooks/refactoring.md#L15) can run the characterization check, neighboring checks, and a gate that runs them again. [principles/references/verification.md:61](https://github.com/orisilber/ostack/blob/2b2c02e/skills/principles/references/verification.md#L61) forbids batching edits and demands a rebase first; [core.md:138](https://github.com/orisilber/ostack/blob/2b2c02e/skills/principles/references/core.md#L138) requires a new tool artifact for almost all nontrivial work. Preserve declared required checks, but reuse results for unchanged code and environment; scope where valid and rerun when new evidence warrants it. Build helpers when they materially improve repetition or proof, rather than to satisfy a ritual. Distinguish stale documentation from unverified behavior. If an authoritative current check proves the affected behavior, report the documentation defect separately instead of insisting the product is unverified.

8. **Collapse setup questions after the user has already authorized setup and watching.** [deploy-watch/SKILL.md:36](https://github.com/orisilber/ostack/blob/2b2c02e/skills/deploy-watch/SKILL.md#L36) asks permission to start setup, line 52 asks five questions, and line 133 asks whether to run the watch afterward. An explicit setup-and-watch request should progress through discovery, one necessary question batch, contract validation, and the authorized watch. Keep explicit rollback authority and material environment/threshold decisions. Never infer rollback permission from a watch request. Read-only discovery and preparing a reviewable contract can happen before asking.

**Correctness findings to fix before relying on these workflows**

Severity here describes likely workflow impact. Executable demonstrations use disposable local fixtures; external services and live model workflows were not exercised.

| Priority | Finding and evidence | Recommended correction |
|---|---|---|
| P1 | [verify-changes:92](https://github.com/orisilber/ostack/blob/2b2c02e/skills/verify-changes/SKILL.md#L92) pipes checks through `tail` without preserving the check’s status. Demonstrated: a failing command followed by `tail -30` returns exit 0 in both Bash and zsh. An agent using that status can report a false PASS. | Preserve the original process status while saving a bounded log excerpt; put repeatable shell mechanics in a tested helper. Do not infer check success from the last log command. |
| P1 | [pick-next-task:112](https://github.com/orisilber/ostack/blob/2b2c02e/skills/pick-next-task/SKILL.md#L112) calls assign-then-readback atomic, but the documented last-writer-wins sequence permits A assign/read A, followed by B assign/read B: both proceed. | Serialize claims through a real shared mechanism or a supported conditional operation. Otherwise describe this as best-effort assignment and enforce a single claimant; another ordinary read cannot prove exclusivity. |
| P2 | [babysit-gitlab-mr:19](https://github.com/orisilber/ostack/blob/2b2c02e/skills/babysit-gitlab-mr/SKILL.md#L19) and [show-me-your-work:44](https://github.com/orisilber/ostack/blob/2b2c02e/skills/show-me-your-work/SKILL.md#L44) write beneath literal `.git/`. A linked worktree’s `.git` is a file; a fixture reproduced `NotADirectoryError`. | Resolve a worktree-specific Git path or use a dedicated ignored artifact directory; scope state by repository and MR/task so concurrent runs do not overwrite it. |
| P2 | The exact [babysit discussion query at line 72](https://github.com/orisilber/ostack/blob/2b2c02e/skills/babysit-gitlab-mr/SKILL.md#L72) filters system status and new authors in separate discussion-level predicates. A fixture with an old human comment plus a new system note is incorrectly returned as fresh feedback. Lines 71 and 118 also fetch only one page; the approval text at line 103 has no explicit binding to the reviewed commit. | Filter all predicates on each note, paginate, and persist the commit associated with each review request/approval. Revalidate review and pipeline against the same current commit. The note-filter failure was executed; pagination and review binding are static contract gaps. |
| P2 | [deploy-watch:123](https://github.com/orisilber/ostack/blob/2b2c02e/skills/deploy-watch/SKILL.md#L123) builds the ignore entry from the invocation directory instead of the actual contract path. From `services/one`, a root contract remains addable even though the command exits 0. | Compute the path from the actual written file and verify it with `git check-ignore`. An exclude entry also does not untrack an already tracked file. |
| P2 | [swarm:41](https://github.com/orisilber/ostack/blob/2b2c02e/skills/swarm/SKILL.md#L41) treats a branch as interchangeable with a separate worktree/output directory. A branch name does not isolate files in a shared checkout. | Use distinct directories/worktrees for overlapping writes, or explicitly disjoint file ownership in a shared workspace. Document the host’s actual storage behavior. |
| P2 | [models.example.json:9](https://github.com/orisilber/ostack/blob/2b2c02e/skills/ostack-mode/references/models.example.json#L9) sets all ten exact overrides to `inherit`. Exact overrides win, so editing a generic role in the copied example changes no covered skill. Resolution was evaluated with a changed judgment role and still returned `inherit`. | Make the default example contain generic roles only; show advanced overrides separately. Define candidate count separately from model count. |
| P2 | [clarify-requirements:42](https://github.com/orisilber/ostack/blob/2b2c02e/skills/clarify-requirements/SKILL.md#L42) persists decisions through GitLab even though its caller claims a Jira work item. [pick-next-task:78](https://github.com/orisilber/ostack/blob/2b2c02e/skills/pick-next-task/SKILL.md#L78) also hardcodes `project = DMI` despite earlier project discovery, and line 43 hardcodes seven team names. | Carry the ticket’s provider and resolved project/team through the workflow. Put organization-specific conventions in configuration; update the actual originating ticket only within the authorized task. |
| P2 | [why:134](https://github.com/orisilber/ostack/blob/2b2c02e/skills/why/SKILL.md#L134) and [its Jira playbook:80](https://github.com/orisilber/ostack/blob/2b2c02e/skills/why/references/sources/jira.md#L80) treat a null search as evidence the change was never ticketed, contradicting [epistemics.md:104](https://github.com/orisilber/ostack/blob/2b2c02e/skills/why/references/epistemics.md#L104). | Report “no matching ticket found in the searched scope.” Missing permissions, indexing, renamed keys, and incomplete search prevent the stronger conclusion. |
| P2 | [TypeScript examples:80](https://github.com/orisilber/ostack/blob/2b2c02e/skills/typescript-best-practices/references/patterns.md#L80) claim `durationMs: number` prevents a negative range. A negative duration typechecks. The random-index `NonEmpty` example at line 57 fails with `noUncheckedIndexedAccess`, and its mutable tuple can be emptied. | Correct the claims and use appropriate validation and immutable/controlled representations. Compile instructional examples under the intended strict settings. Demonstrations used TypeScript 5.9.3. |
| P2 | [deploy-watch:180](https://github.com/orisilber/ostack/blob/2b2c02e/skills/deploy-watch/SKILL.md#L180) requires a long Bash polling loop after allowing MCP-only sources. A model-callable MCP does not by itself supply a shell command. | Separate shell/API polling from host-tool polling and use the host’s scheduling/waiting capability when appropriate. Preserve wake-on-meaningful-change behavior and the existing authorized duration. |
| P2 | [decompose-epic:19](https://github.com/orisilber/ostack/blob/2b2c02e/skills/decompose-epic/SKILL.md#L19) lists at most 50 existing children, then requires avoiding all already-ticketed scope without checking completeness. | Enumerate all existing children before creating new tickets, or explicitly report an incomplete inventory and finish it. |
| P2 | [create-verification-skill:95](https://github.com/orisilber/ostack/blob/2b2c02e/skills/create-verification-skill/SKILL.md#L95) seeds three to five feature recipes, but its proof at line 118 drives only one. | Exercise each recipe claimed as verified, or mark unexecuted recipes as drafts. Do not imply the entire generated feature map was observed working. |

Two smaller defects belong with those fixes: the [branch discovery example in pick-next-task:142](https://github.com/orisilber/ostack/blob/2b2c02e/skills/pick-next-task/SKILL.md#L142) uses `git log --format='%(refname:short)'`, which prints that literal string instead of branch names; and the [verification secret-pattern scan:139](https://github.com/orisilber/ostack/blob/2b2c02e/skills/verify-changes/SKILL.md#L139) matches removed lines, so deleting a credential-shaped placeholder can trigger a hard stop. The former needs a ref enumeration command; the latter needs to distinguish newly exposed content from removal and actual findings from harmless examples. Ticket claiming also uses `$MY_EMAIL` without resolving it and posts `$BRANCH` before its later discovery; resolve stable account identity and branch before those steps.

**Disposition of every production skill**

“Keep” preserves the callable workflow, not every current sentence. “Move” means keeping useful information in a contextual rule/reference, without automatically creating a large AGENTS.md. “Fold” means combining entry points while retaining the distinct operation when useful.

| Skill | Disposition | Main change |
|---|---|---|
| [architect](../skills/architect/SKILL.md) | Keep, redesign contract | Return design to callers; compare alternatives only when the choice warrants it. |
| [arena](../skills/arena/SKILL.md) | Keep, narrow | Reserve for consequential comparisons; separate candidate count from model count and trim mandatory report phases. |
| [babysit-gitlab-mr](../skills/babysit-gitlab-mr/SKILL.md) | Keep, repair | Preserve the MR workflow; fix state paths, note filtering, pagination, and commit-bound review evidence. |
| [blast-radius](../skills/blast-radius/SKILL.md) | Keep, trim | Clear distinct task; scale required proof and output to the change, shorten its long description. |
| [clarify-requirements](../skills/clarify-requirements/SKILL.md) | Fold into ticket workflow | Ask only material missing questions; carry provider identity and allow new information to justify a later question. |
| [create-verification-skill](../skills/create-verification-skill/SKILL.md) | Keep, clarify proof | Useful explicit authoring task with feature-map examples and actual Codex invocation policy. Verify each seeded recipe or label the unexecuted ones. |
| [decompose-epic](../skills/decompose-epic/SKILL.md) | Keep, simplify | Enumerate existing children completely; prefer meaningful acceptance units and explicit ownership to rigid ticket-size/file-count heuristics. |
| [deploy-watch](../skills/deploy-watch/SKILL.md) | Keep, split details | Short router for setup/watch/trigger handling; preserve rollback authority, remove redundant questions, repair execution adapters. |
| [e2e-verify](../skills/e2e-verify/SKILL.md) | Keep, trim | Preserve real-interface assertions; keep fallback setup conditional and avoid requiring new product selectors or a permanent script for every verification. |
| [escalate](../skills/escalate/SKILL.md) | Move/reduce | Small shared authority policy; optional template for real blockers instead of a universal task-stopping workflow. |
| [how](../skills/how/SKILL.md) | Keep, make a router | Direct answer for small questions; load delegation and critique material only for those modes. |
| [interrogate](../skills/interrogate/SKILL.md) | Keep, consolidate | Explicit adversarial review is valuable; unify duplicated rubrics around demonstrated impact and remove size-based presumptive blockers. |
| [maintain-verification-skill](../skills/maintain-verification-skill/SKILL.md) | Keep | Distinct explicit verifier audit; retain source/live-behavior comparisons and avoid unnecessary full sweeps for a targeted update. |
| [ostack-mode](../skills/blahaj-mode/SKILL.md) | Keep | Good router and explicit outcome tails; simplify routine routes and align leaf completion/ownership contracts. |
| [pick-next-task](../skills/pick-next-task/SKILL.md) | Keep, repair | Valuable selection/claim procedure; correct concurrency claims, branch lookup, and organization-specific assumptions. |
| [principles](../skills/principles/SKILL.md) | Move core, retain optional reference | Preserve distinctive engineering preferences; remove the near-universal trigger and requirement to name principles aloud. |
| [recall](../skills/recall/SKILL.md) | Keep, narrow | Use available task-history tools and current workspace scope; consult shared systems when the evidence calls for it. |
| [reproduce-first](../skills/reproduce-first/SKILL.md) | Keep, reconcile | Preserve failing evidence and practical exceptions; distinguish correcting a mistaken repro from weakening a valid assertion, and make two-commit choreography optional. |
| [setup-ostack-mode](../skills/setup-blahaj-mode/SKILL.md) | Keep | Fix shadowing defaults; update only requested roles without re-asking supplied choices. |
| [show-me-your-work](../skills/show-me-your-work/SKILL.md) | Keep, reduce | Keep the TSV helper and evidence contract; make extra audits conditional and fix worktree state placement. |
| [swarm](../skills/swarm/SKILL.md) | Keep | Preserve bounded ownership and completion criteria; correct branch-isolation language and host assumptions. |
| [technical-writing](../skills/technical-writing/SKILL.md) | Keep, split references | Route by document type; move extensive standards/examples out of the root and load only applicable guidance. |
| [typescript-best-practices](../skills/typescript-best-practices/SKILL.md) | Move rules, repair examples | Scope house conventions to actual type changes; use compiler/linter enforcement where appropriate and correct false invariants. |
| [unslop](../skills/unslop/SKILL.md) | Fold into writing workflow | Retain an optional editing pass; avoid a second general writing trigger and treating every discouraged word as an error. |
| [verify-changes](../skills/verify-changes/SKILL.md) | Keep, repair | Preserve exit status, required checks, and real behavior proof; reuse evidence and distinguish documentation drift from product failure. |
| [why](../skills/why/SKILL.md) | Keep, make a router | Progressive investigation from direct evidence; retain deeper source playbooks and correct null-result claims. |

The installer currently installs every production skill to every supported host. After the behavior changes, optional subsets would make catalog curation easier; changing directory structure alone will not reduce the installed catalog. Preserve attribution and license notices when moving reference material.

**AGENTS.md recommendation**

There is no existing file to shorten. Its absence is not itself a defect: the repository is a skill library. Do not create one just to relocate thousands of words. If repository-specific instructions are added, keep them to facts that alter work here: the source-versus-installed-copy distinction, the real validation command and runtime requirement, the disposable nature of fixture checks, and contextual pointers for route/schema changes. Do not require reading every skill before a routine edit. Do not treat changing an in-repository audit or skill as authorization to reinstall the user’s global skills.

**Review corrections and current implementation**

The current tree has 28 production skills. The original 26 remain represented;
`ostack-mode` and its setup skill are now `blahaj-mode` and
`setup-blahaj-mode`. The merged base adds `feature-retention-tests` and
`no-comments`; their existing workflow and installer contracts are preserved.
The latter also now uses the consolidated principles reference, explicit
architect design-only ownership, and Codex manual-invocation metadata.

| Audit area | Final correction and evidence |
|---|---|
| Authorization and completion | `escalate`, ticket clarification, deployment setup, and their callers preserve prior authority and continue independent work. No implicit 30-minute task deadline or silence-as-permission rule remains. |
| Conditional architecture and verification | Feature, bug, and refactoring routes reuse grounding and completed checks. Architect returns a design to implementation-owning callers; comparison depends on unresolved decisions. Arena preserves the caller's scope and test sequencing. A stale verifier can be replaced by an equivalent current check, with the documentation defect reported separately. |
| Conditional loading | `why`, `how`, deployment setup, and writing standards now have short entry points and conditional references. Direct history can stop at one cited decision; a source search returning nothing is scoped absence of evidence. Logging uses available evidence without a required second-model gate. |
| Check results and secrets | `run-check.sh` preserves failure status in Bash and zsh and keeps the full log. The scanner checks outgoing commit history, the index, unstaged additions, and untracked files; it redacts matches and reports read errors. Later removals cannot hide an outgoing or staged secret. |
| Ticket intake and decomposition | Claiming requires a conditional operation or known shared serialization policy; assign/read-back is never called atomic. Ownership uses the stable provider account ID. Branch discovery, queue/team configuration, provider continuity, and complete epic-child enumeration are corrected. |
| GitLab review | State is scoped by project/MR and resolved through Git. List helpers fail on incomplete pagination, and every feedback predicate applies to the same note. Full bodies retain authorship and qualifiers. Approval needs evidence associating the bot response with the current remote MR SHA and request; every push invalidates older approval. Pipeline, review, and final remote head must agree. |
| Deployment contracts and workers | The ignore helper resolves the actual contract path, escapes literal names, works in linked worktrees, and rejects already tracked contracts without changing the index. MCP-only watching uses host tools. Overlapping worker writes require separate directories/worktrees or disjoint ownership. |
| Models and invocation | All manual skills have parsed Codex policy metadata. The current Cursor-rule model source is preserved. Its default example contains only generic roles so optional exact overrides cannot mask them; candidate count is separate from available models. |
| Examples and validation | Non-negative durations use a validated number brand; nonempty snapshots copy and freeze array membership. The validator supports stock macOS Bash, including the new model-rule format. Lint parses YAML, checks formatted skill dependency mentions (including reference files and plural lists), and uses an explicit external-provider allowlist. |

The second review found the first PR's zsh `status` variable was still invalid,
tracked contracts could pass `check-ignore --no-index`, duration wrappers could
be forged structurally, and review state could follow local HEAD or the first
review round. These are corrected, including both findings on the PR's initial
automated review. The report no longer equates a passing structural lint with
completed behavioral validation.

The current root skill files contain 19,623 whitespace-delimited words despite
the two added skills. The largest is `verify-changes` at 8,786 bytes.
The revised entry points are `why` 2,267 bytes, `how` 1,413,
`deploy-watch` 2,911, and `technical-writing` 1,544.
These are source-size measurements, not measured token savings or evidence of
better model behavior. No AGENTS.md, AGENTS.override.md, or CLAUDE.md files are
present in the repository tree; fixture prompt text is not a live instruction file.

**Validation and limits**

Executed on the reconciled branch:

- `TYPESCRIPT_PATH=<installed TypeScript package> /bin/bash evals/lint.sh`:
  **PASS, zero warnings**, with installed CLI help probes enabled.
- A final run with `OSTACK_LINT_SKIP_CLI_CHECKS=1` also passed with zero
  warnings after tightening secret-pattern boundaries. The prior installed-CLI
  results were reused because no CLI examples or probing logic changed.
- The final lint run includes **22 deterministic regression tests**, all passing:
  Bash/zsh status and log retention; outgoing/staged/unstaged/untracked secret
  handling, redaction, and rejection of prose/regex false positives; literal deployment paths and tracked-file rejection;
  linked worktrees; multi-page and failed GitLab reads; per-note filtering;
  YAML invocation policy; missing dependencies; and CLI pipeline parsing.
- The lint run also includes installer-upgrade fixtures, route/model validation,
  and validator fixtures. The validator and its fixtures also passed when
  invoked directly with stock macOS `/bin/bash`.
- The audited TypeScript examples are extracted from the Markdown, compiled
  under TypeScript **5.9.3** with `strict` and `noUncheckedIndexedAccess`, and
  exercised at runtime. Negative/non-finite durations, fabricated wrappers,
  empty tuples, mutation, and mutable aliases are covered.
- All **31** behavioral scenario files parse as YAML and their embedded shell
  blocks pass syntax checks. Older scenarios were corrected to permit an
  authorized local auth edit and avoid a mandatory design panel for a specified
  shape. Ticket scenarios now state the claim policy, verify provider identity,
  and cover absence of serialization.
- `git diff --check`: **PASS**. The final added-secret scan is clean; its initial
  matches were task-word suffixes and documented regex syntax, verified as false
  positives and covered by the new boundary tests.

Commands and dependencies are documented in [tests/README.md](../tests/README.md).
The CLI-help checks verify documented command shapes and flags, not production
API behavior. No production service or global skill installation was changed.
Live Jira/GitLab/deployment operations and paid/headless model scenarios were
not run. The existing Cursor acceptance matrices remain unrun.

A live comparison is still needed to measure completion, unwanted pauses,
irrelevant skill loads, repeated checks, and authority boundaries across the
models intended for this library. In particular, validate a one-commit history
answer, logging without a second model, an existing-policy deployment watch,
and the composed large-feature handoff. Those are remaining validation limits,
not passing results claimed by this PR.
