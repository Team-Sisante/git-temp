# Revert to a specific commit state
## Source: Docs/Trouble-shooting/Revert to a specific commit state.md
## Troubleshooting the Humrine application

### Objective
You want to make your working directory **exactly match** a previous commit (e.g., `537b909`) while **preserving** all later commits in the Git history. This is useful when you've made changes that need to be undone, but you don't want to lose the record of what was attempted.

### Current state example
```bash
$ git log --pretty=format:"%h %s"
cc8ae11 feat: implement interactive environment loading for Docker compose in staging
61e842a Revert to exact state of 537b909       <-- the commit we will create
160d807 Revert "3.4 – Add fallback/error handling for API."
866c137 feat: add startup repair command to fix volume ownership for staging and production services
14609ec feat: add backup and restore functionality for affiliate database in admin panel
95ba7e0 feat: ensure persistent data directory exists with correct ownership in Dockerfile
6350078 feat: add data directory creation and update volume configuration in Docker setup
fd179cf fix: adjust volume definitions for staging and production services in docker-compose
b1b1496 feat: implement database backup and restore functionality in admin panel
537b909 3.4 – Add fallback/error handling for API.
```

### Steps to revert

1. **Inspect the history** – identify the target commit you want to return to (`537b909`).

2. **Revert all commits after that target**  
   This command calculates the inverse of every commit from after `537b909` up to the current branch tip (`HEAD`) and applies those changes to your working directory, but **does not commit** them yet.

   ```bash
   git revert --no-commit 537b909..HEAD
   ```

   - `537b909..HEAD` means “all commits after `537b909`”.  
   - The range includes the revert commit `160d807`, so its effect is also reversed, which restores the feature from `537b909`.
   - `--no-commit` ensures all reverse changes are applied at once and staged, without creating a commit.

   > **Important:** If the command succeeds without errors, your working directory now matches the exact state of `537b909`. No commit is made yet.

3. **Create the final commit**  
   ```bash
   git commit -m "Revert to exact state of 537b909"
   ```

   This records a single, clear commit that says “everything after `537b909` has been undone”. The history remains complete; only the code is rolled back.

### What if there are conflicts?

If any of the revert steps produce a conflict, you must resolve it manually. Then use:

```bash
git add <resolved-files>
git revert --continue
```

This will create a commit even if you originally used `--no-commit`. If you want to avoid an automatic commit, resolve conflicts, stage the files, and then **don't use `--continue`**. Instead, run:

```bash
git commit --no-edit
```

to finalize the revert yourself.

### Result

After the process, your history will look like:

```
cc8ae11 feat: implement interactive environment loading for Docker compose in staging
61e842a Revert to exact state of 537b909          <-- new commit
160d807 Revert "3.4 – Add fallback/error handling for API."
866c137 feat: add startup repair command ...
...
537b909 3.4 – Add fallback/error handling for API.
```

The files on disk are identical to `537b909`, but all the later commits are still visible in the log.

### Alternative (destructive)

If you are absolutely sure you want to **erase** the later commits from the branch entirely, use a hard reset instead:

```bash
git reset --hard 537b909
```

**Warning:** This discards all changes after `537b909` from the branch (though they remain in the reflog for a while). It does **not** preserve the history.

### When to use this technique

- You have published a series of commits and need to roll back to a known good state without force‑pushing or losing the trace of what was tried.
- You want to keep a “paper trail” of the reverted changes for future reference or audits.

Always communicate with your team before reverting a range of commits on a shared branch.