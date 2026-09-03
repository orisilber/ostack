# Investigation playbook

Use this route for read-only questions about behavior, ownership, architecture,
or design history.

1. State `Route: investigation -> answer` and keep the run read-only.
2. Route through the `how` skill for runtime behavior, control flow, ownership,
   and layering. Follow `how` completely; do not perform its exploration in the
   coordinator.
3. For motivation, history, or prior-decision questions, also route through the
   `why` skill and follow its contract completely.
4. Gather evidence from the repository and its reachable records through those
   routed skills.
5. Answer with the relevant structure, evidence, uncertainty, and gotchas.
6. Invoke `unslop` on the final explanation.

Do not edit files, open an MR, post comments, or run a write-capable tail.
