# Restoring Features Commit‑by‑Commit (Cherry‑Pick & Test)
## Source: Docs/Trouble-shooting/Restoring files from previous commit.md
## Troubleshooting the Humrine application

### Current state example
```bash
$ git log --pretty=format:"%h %s"
cc8ae11 feat: implement interactive environment loading for Docker compose in staging
61e842a Revert to exact state of 537b909
160d807 Revert "3.4 – Add fallback/error handling for API."
866c137 feat: add startup repair command to fix volume ownership for staging and production services
14609ec feat: add backup and restore functionality for affiliate database in admin panel
95ba7e0 feat: ensure persistent data directory exists with correct ownership in Dockerfile
6350078 feat: add data directory creation and update volume configuration in Docker setup
fd179cf fix: adjust volume definitions for staging and production services in docker-compose
b1b1496 feat: implement database backup and restore functionality in admin panel
537b909 3.4 – Add fallback/error handling for API.
```

### Objective

After reverting to a stable state (e.g., `537b909`), you want to **re‑apply only the good commits** that came after it, **one at a time**, testing each change before moving to the next. This prevents accidental regressions and allows immediate fixes if a commit introduces an issue.

### Prerequisites

- Your working directory is already at the desired base commit (the revert commit that matches `537b909`).
- You have a list of commits to re‑apply, in **chronological order** (oldest first).

From the history above, the commits to restore (after `537b909`, excluding the revert `160d807` and the combined revert `61e842a`) are:

```
b1b1496 (oldest) → fd179cf → 6350078 → 95ba7e0 → 14609ec → 866c137 (newest)
```

### Procedure

1. **Create a new working branch (recommended)**

   ```bash
   git checkout -b apply-good-commits
   ```

2. **Cherry‑pick the commit – choose your method**

   **Option A – Commit immediately (default)**

   ```bash
   git cherry-pick b1b1496
   ```

   - The change is **automatically committed**.
   - You’ll see no uncommitted files; in VS Code this often shows a “Sync (1)” button (one new commit ready to push).
   - Go to step 4 to review the commit.

   **Option B – Stage but don’t commit (recommended for review)**

   ```bash
   git cherry-pick --no-commit b1b1496
   ```

   - The changes are applied to your working directory and **staged**, but no commit is created.
   - You can inspect, modify, or test before committing.

3. **Review the changes (depending on your option)**

   - **If you used Option B (staged changes)**, view the staged modifications:

     ```bash
     git status
     git diff --cached
     ```

     When you’re ready, commit them:

     ```bash
     git commit -m "feat: implement database backup and restore functionality in admin panel"
     ```

   - **If you used Option A (already committed)**, view the last commit:

     ```bash
     git show
     # or
     git diff --name-only HEAD~1
     ```

4. **Resolve conflicts (only if Git reports a conflict)**

   If Git outputs a conflict message (this can happen with either option):

   - Edit the conflicting files to resolve the issue.
   - Stage the resolved files: `git add <file>`
   - Continue the cherry‑pick:

     ```bash
     git cherry-pick --continue   # for Option A
     # or, if you used Option B, resolve and then commit manually:
     git add <resolved-files>
     git commit -m "your message"
     ```

5. **Test the application**

   - Run your development server, tests, or manually verify the feature.
   - Check that the changes introduced by this commit work correctly.

6. **If something is broken, fix it now**

   Make the necessary corrections in the code.

   - Stage the corrections: `git add .`
   - Amend the cherry‑picked commit (if already committed) or include them in your manual commit:

     ```bash
     # If you used Option A and already committed:
     git commit --amend --no-edit

     # If you used Option B and haven't committed yet:
     git commit -m "your message"
     ```

   This keeps the history clean and the commit correct.

7. **Proceed to the next commit**

   ```bash
   git log -1   # verify the current state
   git cherry-pick (or git cherry-pick --no-commit) <next-commit-hash>
   ```

   Repeat steps 2‑6 for each remaining commit.

8. **Push the branch and create a pull request (PR)**

   Once all commits have been applied and tested, push your branch to the remote repository:

   ```bash
   git push -u origin apply-good-commits
   ```

   Then create a pull request against `master` (or your target branch). Use a clear title and description, summarizing what was restored and why.

   After the PR is reviewed, merge it into the target branch.

9. **Final verification**

   After merging, pull the latest changes locally and run a full regression check to ensure everything works together.

### Example session (using Option B)

```bash
git checkout -b apply-good-commits
git cherry-pick --no-commit b1b1496
git diff --cached          # review changes
git commit -m "feat: implement database backup and restore functionality in admin panel"
# test … OK

git cherry-pick --no-commit fd179cf
# conflict: resolve, git add, git commit -m "fix: adjust volume definitions..."
# test … OK

git cherry-pick --no-commit 6350078
# test … fails (permission denied)
# fix code, git add, git commit -m "feat: add data directory creation"
# test … OK

# … continue with remaining commits

git push -u origin apply-good-commits
# create pull request on GitHub
```

### Benefits

- **Safety** – you catch errors immediately, not days later.
- **Clean history** – each commit remains atomic and correct.
- **Flexibility** – you can easily skip a commit or decide not to commit yet.

### When to use this technique

- After a large revert, when you need to selectively re‑apply features.
- When you suspect a series of commits may contain regressions, and you want to isolate them.
- For any situation where you must carefully reintroduce past changes while testing each step.

Always communicate with your team before cherry‑picking shared commits, especially if the original commits are already public.