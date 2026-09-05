---
name: djungelskog-mode
description: Explicit autonomous entry point for blahaj-mode. Use when you want the agent to research, decide, implement, verify, open the change request, and drive it merge-ready without routine checkpoints.
disable-model-invocation: true
---

# djungelskog-mode

djungelskog-mode is the explicit autonomous entry point for `blahaj-mode`.
It does not define a second workflow. It enters Blahaj with execution mode
`autonomous` for the user's task and then follows Blahaj's route registry,
playbooks, routed skills, verification gates, and outcome tails exactly.

1. Preserve the user's task and constraints exactly. Explicit invocation opts an
   implementation task into delivery through `merge-ready`, including opening
   or updating its PR/MR and addressing review and CI. A question stays read-only.
2. Enter `blahaj-mode` with execution mode `autonomous` for the whole request.
3. Let Blahaj choose the task route and the strongest authorized non-merge
   outcome for that route.
4. Negative constraints always win. A request not to edit, open a PR/MR,
   contact reviewers, or perform another external write lowers the autonomous
   authority ceiling accordingly.
5. Do not ask for routine engineering preferences that repository evidence,
   existing patterns, `how`, `why`, `architect`, or `arena` can settle.
6. Never merge, release, deploy, or perform another irreversible external action
   unless the user separately and explicitly authorizes that action.
7. Save progress through Blahaj's continuation contract when needed. This skill
   does not keep a process alive. Scheduling later runs requires the user's
   request to continue later or monitor, an available host scheduler, and a
   confirmed scheduled operation. Report unavailable continuation honestly.

Do not copy Blahaj playbook steps into this skill. Keeping djungelskog-mode thin is
what makes autonomous behavior stay aligned with normal Blahaj behavior as the
playbooks evolve.
