# Git: Sync Master Branch with Feature Branch

This document outlines the procedure to make the `master` branch's files an **exact copy** of a feature branch in a single, clean commit, while preserving the existing history of `master`.

## ⚠️ When to Use This Procedure

This is a powerful and potentially disruptive operation. Use it with caution.

**✅ Good for:**
*   Personal projects where you are the sole maintainer.
*   Syncing a long-lived feature branch that represents a major state change.
*   Reverting `master` to a known-good state represented by another branch.

**❌ Do NOT use for:**
*   Standard feature integration on a team project. **Use a Pull Request instead.**
*   If `master` is a protected branch that other team members actively push to.

---

## Prerequisites

1.  You have a feature branch (e.g., `before-mailcow`) that is pushed to the remote repository.
2.  You have the latest changes for both branches locally.
    ```bash
    git fetch origin
    ```

---

## Procedure

### Step 1: Switch to the Master Branch

Ensure you are performing the operation on the correct branch.

```bash
git checkout master
```

### Step 2: (Optional) Clean Up Previous Commits

If you have any incorrect commits on `master` (e.g., from a previous failed merge attempt), you can reset them. For example, to undo the last 2 commits:

```bash
git reset --hard HEAD~2
```
> **Note:** Only run this if you need to clean up the branch. Skip if `master` is already in the state you want to start from.

### Step 3: Stage the Exact Contents of the Feature Branch

This is the core command. It replaces the entire staging area (index) and your working directory with the exact file tree from your feature branch, without creating a commit.

```bash
git read-tree -u --reset before-mailcow
```
*   `read-tree`: Reads the file tree from a commit/branch into the staging area.
*   `-u`: Updates the working directory to match.
*   `--reset`: Replaces the staging area's contents, staging all additions, modifications, and deletions required to match `before-mailcow`.

### Step 4: Commit the Changes

Now that the staging area perfectly represents the desired state, create a single commit on `master`.

```bash
git commit -m "Sync master with before-mailcow branch"
```

### Step 5: Force Push to Update the Remote

Because your local `master` history has now diverged from the remote, a normal `git push` will be rejected. You must force push to tell the remote to accept your new state. Using `--force-with-lease` is safer than `--force`.

```bash
git push origin master --force-with-lease
```

---

## Verification

After the push is complete, you can verify that `master` is now identical to `before-mailcow` by running:

```bash
git diff --name-status master..before-mailcow
```

If the branches are identical, this command will produce **no output**.