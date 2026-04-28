---
name: merge-sprint
description: "Merge a batch of related PRs into the target branch in dependency order, resolve conflicts, verify the build after each merge, and clean up leftover worktrees."
---

# Merge Sprint

Merge a batch of PRs (from a sprint, a feature rollout, or a set of parallel agent branches) cleanly and safely, one at a time, with a build check between each.

## Input

The user will provide one of:
- A list of PR numbers: `#251 #252 #253`
- "all open PRs targeting `<branch>`"
- A range or label

## Steps

### 1. Inventory the PRs

```bash
gh pr list --base <target-branch> --state open \
  --json number,title,headRefName,mergeable,additions,deletions
```

For each PR note: branch name, +/- lines, and whether GitHub considers it mergeable. Flag any marked conflicted upfront.

### 2. Determine merge order

PRs that touch overlapping files must be merged sequentially. To detect overlap:

```bash
gh pr diff <number> --name-only
```

Group PRs into independent sets (can merge in any order) and dependent chains (must merge in sequence). When in doubt, merge in PR-number order — lower numbers were created first.

### 3. Verify local branch is up to date

```bash
git fetch origin
git status          # must be clean
git log --oneline HEAD..origin/<target-branch>   # should be empty
```

If behind: `git rebase origin/<target-branch>` before proceeding.

### 4. Merge each PR

For each PR in order:

```bash
gh pr merge <number> --merge
```

If GitHub reports "not mergeable" (conflict), resolve manually:

```bash
git fetch origin <head-branch>
git checkout -b temp/merge-<number> origin/<target-branch>
git merge origin/<head-branch>
# Resolve conflicts — keep BOTH sets of changes unless logically incompatible:
#   - Match arms / enum variants: merge all arms
#   - Imports: keep all from both sides
#   - Test modules: keep all tests
#   - When in doubt: read both sides carefully before discarding either
git add <resolved-files>
git commit -m "merge: resolve conflict between PR #<n> and prior work"
git checkout <target-branch>
git merge --no-ff temp/merge-<number> -m "merge PR #<number>: <title>"
git branch -D temp/merge-<number>
gh pr close <number> --comment "Merged manually after conflict resolution."
```

### 5. After each merge — run preflight for each detected toolchain

Run `/preflight` after every merge — do not skip, and do not batch multiple merges before checking.

Quick version for between-merge checks (full `/preflight` at the end):

**Rust:** `cargo check && cargo clippy -- -D warnings`
**TypeScript:** `npm run build && npm run lint`
**Python:** `ruff check . && python -m pytest -q --tb=short`
**Swift:** `xcodebuild build-for-testing 2>&1 | grep -c "error:"`
**Java/Kotlin:** `./gradlew check -q` or `mvn verify -q`

Fix any failures before moving to the next PR.

### 6. After all PRs merged — full preflight

Run the complete `/preflight` skill across all detected toolchains. This includes the full test suite, not just the fast checks.

### 7. Clean up worktrees

For each worktree tied to a now-merged branch (skip this step entirely if the repo doesn't use `git worktree`):

```bash
git worktree list                                   # identify leftovers
git worktree remove --force "../<worktree-dir>"     # remove each
git remote prune origin                             # prune stale remote refs
```

### 8. Push and report

```bash
git push origin <target-branch>
```

Report: how many PRs merged, any conflicts resolved, build status, worktrees cleaned.

## What NOT to do

- Do not merge PRs targeting the wrong base branch without confirming with the user
- Do not skip the between-merge preflight check — conflicts can cascade
- Do not force-push the target branch unless explicitly asked
- Do not close PRs without merging their content — either merge or explicitly ask the user to abandon
