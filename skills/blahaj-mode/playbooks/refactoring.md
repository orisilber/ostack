# Refactoring playbook

Use this route for behavior-preserving structural work such as rename,
extract, inline, move, or deduplication.

1. Route through `how` over the affected subsystem and pin the current behavior
   with a characterization test, snapshot, or equivalence harness.
2. Name the missing structure and the target shape before moving code.
3. When the target crosses a function or module boundary, route through
   `architect` in `design-only` mode.
4. Apply Subtract Before You Add: remove dead weight and redundant wrappers
   before introducing a new layer. Keep `principles` and its Laziness Protocol
   as the review lens.
5. Move callers with the API, delete the legacy shape in the same wave, and
   preserve the pinned behavior.
6. Run the pin, neighboring checks, and route through `verify-changes`; report
   the equivalence evidence.

The route must not smuggle in new behavior. Split a discovered feature or bug
into its own request before changing the contract.
