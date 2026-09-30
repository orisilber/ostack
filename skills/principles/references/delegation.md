# Delegation and meta principles

Adapted from pstack (MIT, Lauren Tan). One rule per section; the index lives in
`../SKILL.md`.


## Guard the Context Window

The context window is finite within a session. Every token that enters should earn its place.

**Why:** Context overflow degrades reasoning and forces lossy compression. Handing work to a subagent is not free either: the subagent starts without your context, and its summary loses detail you may need.

**Pattern:**
- **Read selectively.** Read the parts of a file or log that bear on the question. Search before reading.
- **Delegate for isolation, not by default.** Use a subagent when work needs an isolated write scope, when parallel slices save real time, when a very large payload would flood the main context, or when a review needs a reader who has not seen your reasoning.
- **Keep frequently used content inline.** Templates and references used on every invocation belong in the skill file, not in separate files that cost a read each time.
- **Size phases and cap scope.** Limit files per phase and account for mechanism costs.


## Decide, Then Present

Settle reversible engineering decisions yourself, do the work, and explain the choice afterward. Code is cheap to change; a blocked task costs the human's attention. The **escalate** skill owns the exceptions: missing authority or access, conflicting requirements, irreversible actions, and repeated attempts that stop producing progress.


## Encode Lessons in Structure

Encode recurring fixes in mechanisms (tools, code, metadata, automation) instead of textual instructions. Every error, human correction, and unexpected outcome is a learning signal. Capture it, route it, and close the loop.

**Why:** Textual instructions are easy to miss. They require the reader to notice, remember, and comply. Structural mechanisms (lint rules, metadata flags, runtime checks, automation scripts) enforce the rule without cooperation.

**Pattern:**
When you catch yourself writing the same instruction a second time:
1. Ask: can this be a lint rule, a metadata flag, a runtime check, or a script?
2. If yes, encode it. Delete the instruction
3. If no (genuinely requires judgment), make the instruction more prominent and add an example of the failure mode

**Pick the strongest rung.** When more than one mechanism would work, choose the strongest the situation allows (an unrepresentable state that cannot compile, then a lint or banned API that fails CI, then a canonical helper, then a runtime check), because agents copy whatever the surrounding code already does and a weaker guard becomes the next template.

**Corollary:** Don't paper over symptoms. If the fix is structural, ONLY use the structural fix. The instruction IS the symptom.

**Feedback loop:**
- **Capture every correction.** When the human intervenes or tests fail, decide if it's a one-off or a pattern.
- **Route to the right layer.** One-off -> brain note. Recurring fix -> skill or lint rule. Systemic issue -> principle.
- **Close the loop.** Don't just record. Apply now or create a concrete todo.

**Anti-patterns:**
- Acknowledging without recording ("I'll keep that in mind" does not persist)
- Recording without routing (a brain note about a lint rule that should exist is wasted unless the lint rule gets implemented)
- Fixing without generalizing (fixing one instance while leaving the recurring pattern intact)

