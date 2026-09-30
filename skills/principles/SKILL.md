---
name: principles
description: Engineering judgment for an explicit design review or request to apply ostack's principles. Provides a short index with deeper references; do not trigger for routine implementation unless a workflow selects it.
---

# Principles

Use the relevant rules from this index and read their references when more
detail would change a decision. Explain consequential choices in ordinary
language; naming principles aloud is optional.

The rest of ostack is procedure: how to claim work, gate it, ship it. This is the
judgment layer that decides whether what you shipped was any good.

Adapted from [pstack](https://github.com/poteto/pstack) (MIT, Lauren Tan). Full
text per group in `references/`: [core](references/core.md),
[architecture](references/architecture.md),
[design red flags](references/design-red-flags.md),
[verification](references/verification.md),
[delegation and meta](references/delegation.md).

## Core

| Rule | Apply when |
|---|---|
| **Laziness protocol** | Refactoring, judging diff size, tempted to add a layer. Bias to deletion and the smallest change that solves it. |
| **Foundational thinking** | Before writing logic. Get the data structures right and the downstream code becomes obvious. |
| **Redesign from first principles** | Integrating a new requirement. Design as if it had been a day-one assumption instead of bolting it on. |
| **Subtract before you add** | Sequencing an addition or rewrite. Remove dead weight first, then build on the simpler base. |
| **Minimize reader load** | Code that's hard to trace. Count the layers between question and answer; collapse one-caller wrappers. |

## Architecture

| Rule | Apply when |
|---|---|
| **Model the domain** | Stateful logic, or a shape assumption repeated across files. Encode the domain in a structure, not scattered conditionals. |
| **Boundary discipline** | Wiring validation, error handling, adapters. Guards at the boundary; pure functions and trusted types inside. |
| **Type system discipline** | Designing types or reading a signature. Make illegal states unrepresentable; parse at the edge; never lie to the compiler. |
| **Make operations idempotent** | Commands and loops that run amid crashes, retries, restarts. Converge to the same end state regardless of partial prior runs. |
| **Migrate callers, then delete legacy APIs** | Introducing a new internal API. Migrate every caller and delete the old one in the same wave. |
| **Separate before serializing shared state** | Concurrent actors writing the same file, branch, or key. Eliminate the sharing first; serialize only for a real invariant. |
| **Design red flags** | Before adding a public boundary. Reject shallow modules, information leakage, temporal decomposition, and pass-through methods. |

## Verification

| Rule | Apply when |
|---|---|
| **Prove it works** | Before declaring done. Verify against the real artifact, not a proxy, not a self-report, not "it compiles." |
| **Fix root causes** | Debugging. Trace each symptom to its cause and fix it there; resist the guard that silences the crash. |
| **Sequence verifiable units** | Multi-step work, and how you stack commits. Each unit ends in a checkable state, and the order proves itself to a reviewer. |

## Delegation and meta

| Rule | Apply when |
|---|---|
| **Guard the context window** | Large outputs and long files. Read selectively; delegate only for isolation, real parallelism, or a fresh reviewer. |
| **Decide, then present** | Tempted to ask "should I do X?" on reversible work. Do it and explain; `escalate` owns the exceptions. |
| **Encode lessons in structure** | You're writing the same instruction a second time. Make it a lint, a check, or a script instead of more prose. |

## How these back the rest of ostack

`verify-changes` is **prove-it-works** with commands attached. `reproduce-first`
is **fix-root-causes**. `decompose-epic` is **sequence-verifiable-units**.
`escalate` owns the exceptions to **decide, then present**. When a procedure
skill and a principle seem to disagree, the procedure skill wins on mechanics and
the principle wins on shape.
