---
name: technical-writing
description: Write or revise documentation, RFCs, readmes, PR descriptions, and commit messages with accurate structure and plain prose. Load document-mode or sentence-style detail only when needed.
disable-model-invocation: true
---

# Technical writing

Write for the reader's task and level of knowledge. Lead with the point, use
concrete names and verbs, and keep claims traceable to the actual code or source.
Cut words that do no work. A rule that makes a sentence harder to read should
not be applied mechanically.

For tutorials, how-to guides, reference pages, and explanations, choose the
relevant mode using [references/document-modes.md](references/document-modes.md).
Keep substantial modes separate and linked. A commit message or short PR
description does not need a document taxonomy exercise.

For substantial prose editing, ambiguous sentences, or global audiences, consult
[references/sentence-style.md](references/sentence-style.md). It contains the
attributed style guidance and worked example; do not load it for every short edit.

Use repository conventions for code snippets and product conventions for UI
copy. Verify real symbols, paths, commands, and counts. Explain the change,
its reason, and validation in PR descriptions.

Use the **unslop** skill only when requested or the draft has obvious formulaic
language. Preserve evidence and the intended tone; do not add opinions to dry
reference or incident records. Finish once the prose is accurate, clear, and
appropriate to the reader.
