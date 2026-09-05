# Refactoring playbook

Use this route for behavior-preserving structural work such as rename,
extract, inline, move, or deduplication.

1. Inspect the affected subsystem and pin current behavior with a
   characterization test, snapshot, or equivalence harness when the behavior is
   unclear or the move could change an external contract. Reuse existing proof
   for a mechanical rename or move with a clear target.
2. Name the missing structure and the target shape before moving code.
3. Route through `architect` in `design-only` mode when the target crosses a function or
   module boundary and introduces a new shape. A boundary crossing alone does
   not require competing designs for an established pattern.
4. Apply Subtract Before You Add: remove dead weight and redundant wrappers
   before introducing a new layer. Keep `principles` and its Laziness Protocol
   as the review lens.
5. Move callers with the API, delete the legacy shape in the same wave, and
   preserve the pinned behavior.
6. Route through `verify-changes` with completed pin and neighboring-check evidence.
   Run missing or invalidated checks at the required scope and report the
   equivalence evidence.

The route must not smuggle in new behavior. Split a discovered feature or bug
into its own request before changing the contract.
