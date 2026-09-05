# Drive the existing change request merge-ready

Use only for the authorized `merge-ready` outcome after the opening tail.

1. Reuse the resolved provider and request URL. For GitLab invoke
   `babysit-gitlab-mr` with the task contract and its `merge-ready` outcome.
   For GitHub follow [the GitHub review loop](../references/github-review.md).
   An unsupported provider blocks this tail, not the completed local work.
2. Continue authorized fixes for actionable review findings and required CI
   failures. Every push invalidates prior review and CI evidence.
3. Report readiness only with passing checks and required review for the current
   remote head, no unresolved actionable feedback, and no merge conflict.
4. Stop at readiness. Do not merge, enable auto-merge, release, deploy, or begin
   an indefinite watch. A requested later continuation follows
   [the continuation contract](../references/continuation.md).
