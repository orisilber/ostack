---
name: release
description: Cut a release end-to-end — version bump, build, tag, publish a GitHub or GitLab release, update package-manager manifests (homebrew formula/cask, registries). Triggers "cut a release", "release version", "bump and publish", "new homebrew version". Use ONLY for release mechanics; ask when the bump type is genuinely ambiguous rather than guessing.
---

# Release

Generalized from scripts/release.sh (greg). Works on GitHub (gh) and GitLab
(glab) — detect forge from `git remote -v`.

## Inputs (required, non-interactive)

- **Bump type**: patch|minor|major|explicit version. If the user didn't say,
  infer: new user-facing capability → minor; pure fixes → patch; ask ONLY if
  both are plausible AND no conventional-commits history exists to read.
- **Dry-run**: if invoked as "dry run" / "what would release", print the plan
  and stop.

## Preconditions (hard)

1. Clean worktree (`git status --porcelain` empty)
2. On default branch, in sync with origin
3. CI green on HEAD (`glab ci list` / `gh run list`, latest run success) — red
   HEAD means stop, fixing it is not this skill's job

## Flow

1. Bump version in manifest(s): `package.json`, `pyproject.toml`, `Cargo.toml`,
   `Formula/*.rb`, `Casks/*.rb` — whichever exist.
2. Build artifacts per repo convention (AGENTS.md / existing release script —
   prefer the repo's own script if present, e.g. `scripts/release.sh`; this
   skill orchestrates it rather than duplicating it).
3. Commit `Release v<version>`, tag `v<version>`, push branch + tags.
4. Create the release with artifacts:
   - GitHub: `gh release create v<ver> <files...> --title --notes`
   - GitLab: `glab release create v<ver> <assets...> --notes`
5. Manifest SHA updates: download each published artifact + source tarball,
   compute `shasum -a 256`, rewrite formula/cask/lockfile references, commit
   `Update manifests to v<version>`, push.

## Token rules

Build/test output → `tail -20`. Never cat SHAs lists or full logs; one line per
step: `v0.4.0: built, tagged, released, manifests updated`.

## Failure mid-flight

Releases are half-mutating states — resume, don't restart: check what already
exists remotely (tag? release? assets?) before redoing any step. Unrecoverable
→ `escalate` with exact remote state so nothing is double-published.
