---
name: maintain-verification-skill
description: "Audit a project's verification skill, repository checks, control instructions, and feature map against current source and live behavior. Use for /maintain-verification-skill or \"audit the verify skill\"."
disable-model-invocation: true
---

# Maintain a verification skill

A project-local verification skill becomes stale as the application changes.
Audit every mapped feature from source and exercise every feature live. Keep the
run focused on the verification skill. Do not turn each feature bullet into a
separate terminal session.

## Outcomes

Report one outcome:

- **clean** means every feature received source and live coverage, and no
  correction was needed. Do not create a commit or an MR.
- **changed** means the local change contains proven corrections. Commit, push,
  or open one MR only when the user requested that outcome.
- **blocked** means coverage could not finish or a correction could not be made
  safely. Name the exact blocker.

## Edit scope

Edit only the project-local verification skill directory. This includes its
`SKILL.md`, `features/`, and owned control scripts. Do not edit product code. A
mapped behavior that no longer works is either documentation drift or a product
regression. Correct documentation drift. Report a product regression without
changing the product or hiding the failure in the map.

## Audit the skill

0. **Locate the target.** Search `.agents/skills/verify-*`,
   `.cursor/skills/verify-*`, and `.claude/skills/verify-*` from the repository
   root. A target has launch and drive instructions plus a feature map. If
   several candidates describe different applications, ask which one to audit.
   If none exists, stop and point to `create-verification-skill`.

1. **Check the index and sources.** Read the feature index, its sibling files,
   and the generated skill's source anchors. Fix missing, extra, duplicate, or
   dead index entries. Compare each repository check against the file that
   declares it. Do not generate an inventory file.

2. **Read each feature from source.** Launch one read-only worker per feature
   when parallel agents are available. Each worker returns the feature summary,
   source entry points, likely drift with file citations, and one concise live
   recipe. Workers do not drive the app or edit files. Without parallel agents,
   inspect the features in sequence and keep the same return shape.

3. **Reconcile the results.** Require a result for every feature file. Merge
   overlapping recipes into as few app states as practical. Check cited drift.
   Sweep recent changes for a missing user-facing feature. Require a concrete
   source path before adding one.

4. **Run the live pass.** Drive every feature at least once. The coordinator
   owns the live app. Use one long-lived instance for servers and UIs, or one
   isolated session per short-lived CLI drive, as the target skill specifies.

   Keep these invariants throughout the pass:

   - Run the doctor check before the first drive, on each fresh session, and
     after a surprising failure. Reset or relaunch a wedged UI even when the
     process remains healthy.
   - Preserve collected evidence across cleanup and check its named location.
   - Clean residue after each drive. Keep a shared instance only while another
     drive still needs it.

   If skill drift breaks the doctor check, fix it within the edit scope and
   retry once. Restart only what the correction invalidated. Mark a feature
   `verified-unreachable` only when you name the prerequisite and attempted
   route. Re-drive every control-script correction. Tear down the final
   instance after the last drive and keep the evidence.

5. **Triage each mismatch.** Correct a wrong user description as documentation
   drift. Correct a control script that cannot drive working behavior as a
   control gap. Make each owned script executable and document its invocation.
   Report broken application behavior as a product gap.

6. **Verify and stop at the authorized boundary.** Run `verify-changes` after a
   correction and re-read every changed file. For `changed`, leave a proven
   local change by default. Commit, push, or open one MR only when the user
   authorized it. For `clean` or `blocked`, do not create an MR.

Keep concise run notes in a scratch location. Record covered features,
unreachable prerequisites, confirmed drift, and the outcome. Do not commit the
notes.
