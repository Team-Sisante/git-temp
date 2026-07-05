# Git Workflow: Creating Feature Branches and Rebasing

## Objective
Maintain a clean, linear Git history and avoid merge conflicts when
working as the sole developer.

## Key Principles
1. Always branch from master (or main).
2. Rebase instead of merge for feature branches.
3. Update your branch with the latest master regularly.
4. Resolve conflicts locally, not on GitHub.

---

## Step-by-Step Procedure

### 1. Update your local master
    git checkout master
    git pull origin master
Ensures your local master is identical to the remote master.

### 2. Create a new feature branch from the updated master
    git checkout -b feature/your-feature-name
Or use `git switch -c feature/your-feature-name` (both do the same).

### 3. Work on your feature
- Make commits as usual.
- Keep commits focused and logical.

### 4. Regularly rebase onto the latest master
Before opening a PR, and occasionally during development, rebase your
branch onto master to incorporate recent changes.
    git fetch origin
    git rebase origin/master
If conflicts occur:
- Resolve them manually in the files.
- Mark as resolved: `git add <file>`
- Continue: `git rebase --continue`
- If stuck, abort: `git rebase --abort`

### 5. Push the branch to remote
After rebasing, force-push because history is rewritten.
    git push origin feature/your-feature-name --force-with-lease
`--force-with-lease` is safer than `--force` – it rejects if someone
else pushed to the same branch.

### 6. Open a Pull Request
- PR will have a clean, linear history with no merge commits.
- Conflicts should be minimal or non‑existent.

---

## Handling Conflicts During Rebase

1. Check conflicted files:
       git status

2. Resolve conflicts manually in your editor.
   - Look for `<<<<<<<`, `=======`, `>>>>>>>` markers.
   - Keep the correct changes, remove the markers.

3. Mark as resolved:
       git add <file>

4. Continue the rebase:
       git rebase --continue

5. If stuck, abort:
       git rebase --abort

---

## Handling Binary File Conflicts (e.g., encrypted .env files)

Binary files cannot be merged automatically. When conflicts occur:

1. Choose your version:
       git checkout --ours <file>

2. Or choose the incoming version:
       git checkout --theirs <file>

3. Mark as resolved and continue:
       git add <file>
       git rebase --continue

---

## Common Mistakes to Avoid

- Branching from another feature branch (always branch from master).
- Using `git merge` instead of `git rebase` (merge creates unnecessary
  merge commits).
- Pushing without rebasing first (may create conflicts on GitHub).
- Forgetting to update master before branching (leads to outdated
  branches).

---

## Quick Reference

| Action | Command |
|--------|---------|
| Update master | `git checkout master && git pull origin master` |
| Create feature branch | `git checkout -b feature/name` |
| Rebase onto master | `git rebase origin/master` |
| Push after rebase | `git push origin feature/name --force-with-lease` |
| Abort rebase | `git rebase --abort` |
| Continue rebase | `git rebase --continue` |

---

## Summary
Always start from the latest master, rebase regularly, and force-push
only after rebasing. This keeps history clean and prevents merge
conflicts.