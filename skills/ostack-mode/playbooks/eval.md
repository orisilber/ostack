# Eval playbook

Use this route when the user asks to exercise the skill library or its
headless scenarios.

1. State `Route: eval -> local-change` (or the explicitly requested outcome).
2. Run the static gate with `bash evals/lint.sh`.
3. Run the relevant YAML scenarios with `bash evals/run.sh <scenario>`, or the
   complete scenario set when the user asks for a full eval.
4. Preserve failing output, identify the first failing layer, and do not claim
   a pass when setup, the agent, or an assertion failed.
5. Report the exact scenarios, durations, and results.

The eval route may write only local result artifacts. It never opens an MR or
changes external systems unless an explicit outcome tail authorizes that.
