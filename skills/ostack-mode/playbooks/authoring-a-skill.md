# Skill-authoring playbook

Use this route when the user asks to create or update a repository skill.

1. Read `principles` and name the smallest contract and boundary for the skill.
2. Draft the frontmatter and task flow with `technical-writing`.
3. Add focused references or scripts only when they lower reader load.
4. Add deterministic repository eval scenarios for trigger, safety, and the
   expected observable result.
5. Apply `unslop` to published prose and inspect the diff for invented tools or
   hidden external writes.
6. Run `evals/lint.sh` and the relevant YAML scenarios.
7. Report what the skill owns, what it delegates, and the evidence for its
   acceptance criteria.

Do not copy another skill wholesale. Reuse its contract by reference and keep
the new skill's scope explicit.
