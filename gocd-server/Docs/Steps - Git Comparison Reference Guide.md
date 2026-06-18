# Git Comparison Reference Guide

This guide summarizes how to compare files and branches when working between a
**feature branch** and a **master/main** branch.

---

## 1. Comparing Files with VS Code (Windows/PowerShell)

To compare a specific file (e.g., `package.json`) side-by-side using VS Code as your diff tool.

### One-Time Setup

```powershell
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
```

### Run Comparison

```powershell
git difftool master package.json
```

---

## 2. Viewing File Status

| Command | Description |
|:---|:---|
| `git diff master --name-status` | Shows file paths with status (A=Added, M=Modified, D=Deleted) |
| `git diff master --name-only` | Shows a clean list of changed filenames |
| `git diff master --stat` | Shows a summary of insertions and deletions per file |

> Add `> diff.txt` at the end of any command to save output to a file, then run `code diff.txt` to view it.

---

## 3. Viewing Content in Terminal

```bash
# See line-by-line changes
git diff master path/to/file.ext

# View the version of a file on master without switching branches
git show master:path/to/file.ext

# Open a side-by-side diff in VS Code using a temp file
git show "master:package.json" > "temp/temp_package.json" && code --diff "temp/temp_package.json" "package.json"
# Remember to delete temp_package.json afterward
```

---

## 4. Restoring Deleted Files

Files not in the current branch but present in master:

```bash
# Example
git restore --source master "Docs/Setup Guide.md"
```

---

## 5. Understanding Status Symbols

When using `--name-status`:

| Symbol | Meaning |
|---|---|
| `A` | Added — file is new in your current branch |
| `M` | Modified — file exists in both branches but content differs |
| `D` | Deleted — file was removed in your current branch but exists in master |

---

## 6. Branch vs. Merge Base

```bash
# Compares the tip of master to your current work
git diff master..HEAD

# Compares the merge base (where you branched off) to your current work
# This is usually what you want for Pull Requests
git diff master...HEAD
```

---

## 7. Checking What entrypoint.js Changed (gocd-server specific)

Since `entrypoint.sh` was converted to `entrypoint.js`, use this to compare:

```bash
git show master:Scripts/entrypoint.sh > temp/old_entrypoint.sh
code --diff temp/old_entrypoint.sh Scripts/entrypoint.js
```

---

## 8. Comparing cruise-config.xml Across Branches

```bash
# See what changed in the pipeline config
git diff master config/cruise-config.xml

# View the master version without switching
git show master:config/cruise-config.xml
```

---

## 9. Checking Docker Image Changes

When troubleshooting image build issues, compare Dockerfiles:

```bash
git diff master Dockerfile
git diff master Dockerfile.agent
git diff master Dockerfile.agent.solvpn
git diff master Dockerfile.agent.solvpn.base
```