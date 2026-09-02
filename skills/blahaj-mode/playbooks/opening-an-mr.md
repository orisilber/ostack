# Opening an MR

Use this tail only when the user explicitly asks to open or create a merge
request, or when the selected outcome is `merge-ready`.

1. Confirm that the base playbook completed and `verify-changes` passed.
2. Confirm that the preceding `no-comments` outcome-tail step reviewed the
   current branch diff and the parent applied every accepted finding. If that
   cleanup changed files after the last successful verification, rerun
   `verify-changes`. Stop if it does not pass.
3. Review the diff and ordered commits for scope, secrets, and accidental
   generated files.
4. Run `glab mr view` for the current branch. If an MR exists, return its URL
   and do not create another one.
5. If no MR exists, write a concise MR title and description that state why,
   scope, tradeoffs, blast radius, and verification.
6. Open the MR through the repository's configured GitLab workflow.
7. Report the MR URL and stop unless the selected outcome is `merge-ready`.

If verification is not green, do not open the MR. Explain the blocking check
and leave the branch in its current state.
