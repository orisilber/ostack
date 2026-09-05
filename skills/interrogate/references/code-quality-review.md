# Code Quality Review

Each reviewer applies this code-quality lens in addition to the rubric. Tie
findings to the diff and a concrete impact on implementation quality,
maintainability, abstraction quality, or codebase health.

Look for structural simplifications that preserve behavior and remove moving
parts, but do not demand a redesign when the current shape is coherent.

## Core Prompt

Start from this baseline:

> Review the current branch's changes for concrete code-quality regressions.
> Identify structural improvements that materially improve maintainability without
> changing behavior, and explain the execution path or evidence behind each one.

## Dimensions

Each dimension is stated once. Apply the ones that are relevant.

0. **Structural simplification.** Look for reframings that make branches,
   helpers, modes, conditionals, or layers disappear. Raise the finding when the
   diff leaves concrete incidental complexity that a smaller shape would remove.

1. **Use file size as a signal, not a gate.** A file that becomes hard to
   navigate or mixes ownership may need helpers, subcomponents, or modules.
   Line count alone is not a defect; tie the finding to a concrete loss of
   cohesion or maintainability.

2. **Do not allow spaghetti growth in existing code.** Be suspicious of new ad-hoc conditionals, scattered special cases, or one-off branches inserted into unrelated flows. Treat "weird if statements in random places" as a design problem, not a style nit. Prefer pushing the logic into a dedicated helper, state machine, or module instead of tangling an existing path.

3. **Bias toward cleaning the design, not just accepting working code.** If behavior can stay the same while the structure becomes meaningfully cleaner, push for the cleaner version. Prefer simplifications that remove moving pieces over refactors that spread the same complexity around.

4. **Prefer direct, boring, maintainable code over hacky or magical code.** Treat brittle, ad-hoc, or "magic" behavior as a problem. Be skeptical of generic mechanisms that hide simple data-shape assumptions. Flag thin abstractions, identity wrappers, or pass-through helpers that add indirection without buying clarity.

5. **Push on type and boundary cleanliness when it affects maintainability.** Question unnecessary optionality, `unknown`, `any`, or cast-heavy code when a clearer type boundary could exist. Prefer explicit typed models over loosely-shaped ad-hoc objects. If a branch leans on a silent fallback to paper over an unclear invariant, ask whether the boundary should be made explicit.

6. **Keep logic in the canonical layer and reuse existing helpers.** Call out feature logic leaking into shared paths or implementation details leaking through APIs. Prefer existing canonical utilities over bespoke one-offs. Push code toward the right package, service, or module instead of normalizing drift.

7. **Treat unnecessary sequential orchestration and non-atomic updates as design smells when the cleaner structure is obvious.** If independent work is serialized for no reason, ask whether it should run in parallel. If related updates can leave state half-applied, push for a more atomic structure. Do not over-index on micro-optimizations, but do flag avoidable orchestration complexity that makes the code more brittle.

## Output Expectations

Prioritize structural code-quality regressions and missed simplifications first, then spaghetti and branching complexity, then boundary, type, and file-size concerns, then smaller modularity and legibility issues. Do not flood the review with low-value nits when larger structural issues exist. Prefer a few high-conviction comments over a long list of cosmetic notes.

## Approval Bar

Do not approve merely because behavior seems correct. Raise a blocking finding
when the diff shows a concrete structural regression: incidental complexity a
small redesign would remove, ad-hoc branching that tangles an existing flow,
feature checks scattered across shared code, an unnecessary abstraction or
cast-heavy contract, or duplicated logic with a clear canonical home. A file's
line count can support that case, but it cannot establish it by itself. Keep
the feedback actionable and proportional to the change.

## Review Tone

Be direct, serious, and demanding about quality. Do not be rude, but do not soften major maintainability issues into mild suggestions. If the code is making the codebase messier, say so. If the implementation missed an obvious dramatic simplification, say that too. Do not be satisfied with "maybe rename this" when the real issue is structural.
