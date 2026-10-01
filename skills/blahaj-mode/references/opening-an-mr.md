# Opening or updating a PR/MR

Use this for an authorized `mr-open` or `merge-ready` outcome. Reuse the task
contract, including deliver mode's delivery scope, subject to host permissions.

1. Confirm that the work is complete and `verify-changes` passed on the current
   files. Rerun it after any later edit.
2. Review the diff and ordered commits for scope, secrets, and accidental
   generated files.
3. Resolve the hosting provider, repository, base, and head branch from the
   configured remote or the supplied change-request URL. Use `gh` for GitHub
   (including its configured enterprise host) and `glab` for GitLab. Do not
   guess a provider from the CLI installed on the machine.
4. Look up the existing request for that exact repository and head: `gh pr list`
   or `glab mr list`, filtered to the branch. Verify its base and URL. A failed
   lookup is not proof of absence. Reuse the existing request; if a create call
   times out, reconcile remotely before retrying it.
5. Commit the scoped, verified changes and push the intended head branch using
   the existing repository workflow. Update the existing request's description
   if needed. If none exists, create one with `gh pr create` or `glab mr create`,
   explicitly selecting the repository, head, and base. Describe the problem,
   resulting behavior, and actual verification. Preserve draft status on an
   existing request unless publishing it is authorized.
6. Save the returned request URL and remote head in the continuation checkpoint.
   Report the URL and stop unless the selected outcome is `merge-ready`.

If verification is not green, do not open the MR. Explain the blocking check
and leave the branch in its current state.
