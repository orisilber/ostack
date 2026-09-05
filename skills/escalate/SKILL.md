---
name: escalate
description: Resolve a concrete blocker involving missing authority, access, conflicting requirements, or exhausted attempts. Preserve prior authorization and continue independent work.
---

# Escalate

Pause the blocked action when it requires a decision or authority you do not
have. Continue independent authorized work. A skill does not override the user's
instructions, host permissions, or an approval already given for the same scope.

## When to pause

- Consequential operations need specific authority: permission changes, money
  movement, production migrations, live infrastructure changes, destructive data
  operations, and shared-branch force pushes. Check the existing request and
  policy first; do not ask again for an already authorized operation.
- Missing access or a host approval block is a real boundary. Do not route around
  it through another tool.
- A suspected secret or vulnerability needs investigation and contained repair.
  Stop publication of a confirmed secret; do not freeze an authorized source fix
  merely because it touches auth, billing, migrations, CI, or infrastructure.
  Never print secret values in an escalation.
- Respect a declared budget from the user or calling workflow. There is no
  implicit 30-minute session limit. A bounded poll window is not a task deadline.

For an unresolved implementation or environment failure, use a soft-stop
default N=3 materially different attempts, then ask with the evidence. Do not
delay a required authority question for three attempts. Merge conflicts require
input only when the conflicting intent cannot be resolved from the record.

## Ask once for the missing decision

Name the blocked action, what you tried, the best supported option and its
consequence, and the independent work you can continue. Batch related questions.
Use a concise plain-language question; a rigid template is not required.

A default may cover a reversible implementation assumption. Silence never
grants missing permission or access. Check prior answers before asking again.

## Resume

Resume from the current artifacts and task history. Use persisted state when
the workflow supplies it; do not make a state file a prerequisite for resuming.
For Git-local state, use `git rev-parse --git-path <task>-state.json` so linked
worktrees work too.
