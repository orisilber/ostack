# Prototype playbook

Use this route to settle a design, interaction, timing, or empirical fork with
throwaway artifacts.

1. State the concrete decision the prototype must answer. If there is no
   decision, route to `feature` instead.
2. Build each candidate in an isolated scratch directory outside production
   source. Route through `arena` only when competing artifacts will inform the
   decision.
3. Label every candidate and keep a single switcher when the alternatives share
   a surface.
4. Drive the matching surface and record screenshots, output, or timing as
   evidence.
5. Return the tradeoffs, recommendation, evidence paths, and scratch path.
   Label every artifact disposable and hand the chosen direction to `feature`.

Do not polish or merge prototype code. Do not place candidates in production
source or add a general comparison framework.
