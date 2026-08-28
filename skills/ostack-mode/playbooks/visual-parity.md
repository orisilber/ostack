# Visual-parity playbook

Use this route when one UI must match a baseline or another implementation.

1. Confirm that the repository has a UI surface and establish an untouched
   baseline harness before editing the target.
2. Start with labeled side-by-side screenshots across the relevant states.
3. Migrate one component at a time. Keep the baseline and harness unchanged.
4. Invoke `e2e-verify` on the matching surface and record the screenshot paths.
5. Treat any unexplained visual delta as a failure. Pixel diffing needs a
   numeric threshold supplied by the task; do not invent one.

If the repository has no UI, report that visual parity is not applicable and do
not invoke `e2e-verify`. This route does not create a general image-diff
framework.
