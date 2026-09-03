# Feature playbook

Use this route when the user asks for new behavior.

1. Name the data shape, boundary, and acceptance behavior before editing.
2. Route through `how` over the affected subsystem.
3. Route through `architect` in `design-only` mode when a public function,
   class, type, or ownership boundary crosses modules. Record
   `architect skipped: <reason>` for a small change that follows an existing
   local pattern.
4. Route through `arena` when the user requests competing implementations, the
   task exposes incompatible boundaries or interactions, or one attempt would
   lock in a consequential choice between viable approaches. Give every arena
   candidate the complete acceptance scope and the same test-last constraint as
   this playbook: do not add or edit feature-specific tests; existing tests may
   run. If step 3 produced an Architect design package, pass it to every arena
   candidate as a hard constraint. Candidates may vary implementation details
   inside that design, but may not silently replace its public boundaries,
   ownership, or type shape. If implementation evidence shows that design must
   change, return to `architect` in `design-only` mode before continuing Arena.
   Treat the synthesized arena artifact as the implementation for step 5. Arena
   verification may use existing checks but does not replace step 6's
   real-interface acceptance gate. Otherwise record why arena was not needed.
5. If step 4 ran `arena`, review and integrate its synthesized implementation
   and fill only any acceptance-scope gaps; do not reimplement the feature from
   scratch. Otherwise implement the complete accepted feature. In either case,
   complete the accepted implementation without adding or editing
   feature-specific tests. Existing tests may run throughout. Keep working until
   the full acceptance scope exists, not merely a partial slice.
6. Prove every acceptance behavior through the real UI, API, CLI, or integration
   path. Run existing declared checks, but do not create a new automated
   script or spec as the proof. If an existing expectation is intentionally
   obsolete, record it for the retention phase. Fix the implementation until
   the real behavior passes.
7. Route through `feature-retention-tests`. Add the minimum durable coverage,
   if any, only after the feature is accepted.
8. Run the focused retention tests and then route through `verify-changes`.
   Report the real behavior proof, retained contracts, exact checks, and result.

MR creation and reviewer interaction remain outcome tails. Do not infer them
from a branch, ticket, or a completed local change.
