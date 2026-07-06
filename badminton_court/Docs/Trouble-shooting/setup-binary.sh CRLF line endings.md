# setup-binary.sh CRLF line endings cause container crash
## Source: Docs/Trouble-shooting/setup-binary.sh CRLF line endings.md

## Troubleshooting container crash due to CRLF line endings in shell scripts

### Symptom
The `badminton_court-web-staging-1` container exits immediately with:
```
exec /usr/local/bin/setup-binary.sh: no such file or directory
Exited (255) 18 minutes ago
```

The script exists in the image, has correct permissions, and the shebang is valid (`#!/bin/bash`). But the container claims the file doesn't exist.

### Root Cause
The shell script `deploy/setup-binary.sh` was committed with **CRLF (Windows) line endings** instead of LF (Unix). When the kernel reads the shebang:

```
#!/bin/bash\r\n
```

It interprets the shebang as `#!/bin/bash\r` (with a literal carriage return). The kernel tries to execute `/bin/bash\r` as the interpreter — which doesn't exist. The error message reports the script itself as "no such file or directory" (misleading).

This happens when files are edited on Windows and committed without `.gitattributes` enforcement, or when `core.autocrlf` converts LF to CRLF on checkout.

### Diagnostic Steps

1. **Check the file's line endings:**
   ```bash
   cd badminton_court
   file deploy/setup-binary.sh
   ```
   If it says `with CRLF line terminators`, that's the bug.

2. **Check for raw carriage returns:**
   ```bash
   grep -c $'\r' deploy/setup-binary.sh
   # 0 = LF only (good)
   # 1+ = has CRLF (bad)
   ```

3. **Verify inside the deployed image:**
   ```bash
   ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
     "sudo docker run --rm --entrypoint od ghcr.io/team-sisante/badminton_court-web:sha-<TAG> /usr/local/bin/setup-binary.sh | head -2"
   ```
   If the first line shows `#   !   /   b   i   n   /   b   a   s   h  \r  \n`, it's CRLF.

### Fix

#### Step 1: Convert the file to LF line endings

```bash
cd badminton_court

# Convert to LF (use one of these)
dos2unix deploy/setup-binary.sh 2>/dev/null || sed -i 's/\r$//' deploy/setup-binary.sh

# Verify
file deploy/setup-binary.sh
# Should say: ASCII text executable (no "CRLF line terminators")

grep -c $'\r' deploy/setup-binary.sh
# Should be: 0
```

#### Step 2: Add a `.gitattributes` file to prevent recurrence

Create `badminton_court/.gitattributes`:

```gitattributes
# Force LF line endings for shell scripts and Dockerfiles
*.sh            text eol=lf
*.bash          text eol=lf
Dockerfile*     text eol=lf
docker-compose*.yml text eol=lf
*.conf          text eol=lf
*.template      text eol=lf
.env*           text eol=lf

# Python files
*.py            text eol=lf
*.pyi           text eol=lf
manage.py       text eol=lf

# Allow CRLF for Windows-only scripts
*.bat           text eol=crlf
*.cmd           text eol=crlf
*.ps1           text eol=crlf
```

#### Step 3: Renormalize existing files in Git

```bash
cd badminton_court

# Renormalize all files according to the new .gitattributes
git add --renormalize .

# Verify what changed
git status

# Commit
git commit -m "Fix: convert setup-binary.sh to LF line endings + add .gitattributes"
git push
```

`git add --renormalize .` is the official Git-recommended way to apply `.gitattributes` rules to existing files. It only stages files where line endings actually changed.

#### Step 4: Rebuild and redeploy

1. Trigger `badminton_court-artifacts` pipeline (rebuilds the image with the corrected LF script)
2. Trigger `badminton_court-staging` pipeline (deploys the new image)

### Why `grep` Sometimes Lies

If you run:
```bash
grep -l $'\r' deploy/setup-binary.sh && echo "HAS CRLF" || echo "LF only"
```

And get `LF only` even though `file` says CRLF — that's because **Git Bash's `grep` on Windows can strip `\r` in text mode**. The `file` command reads bytes directly and is more reliable. Always use `grep -c $'\r'` (count mode) or `file` to check line endings.

### Why `.gitattributes` Alone Isn't Enough

`.gitattributes` rules only apply:
- ✅ When you **check out** files (after `git rm --cached` + `git checkout`)
- ✅ When you **stage** new changes
- ❌ **NOT** to files already in the working tree with CRLF

If `setup-binary.sh` was committed with CRLF before `.gitattributes` was added, the file in your working tree still has CRLF. You must either:
- Run `git add --renormalize .` to force renormalization, OR
- Manually convert with `sed -i 's/\r$//'`

### Verification

After redeployment:
```bash
# Web container should be Up, not Exited
ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
  "sudo docker ps --filter name=badminton_court-web-staging"

# Verify script has LF endings inside the container
ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
  "sudo docker exec badminton_court-web-staging-1 od -c /usr/local/bin/setup-binary.sh | head -1"
# Should show: #   !   /   b   i   n   /   b   a   s   h  \n  (no \r)
```

### Related Files
- `badminton_court/deploy/setup-binary.sh` — the script that had CRLF
- `badminton_court/.gitattributes` — forces LF for shell scripts
- `badminton_court/Dockerfile.binary` — copies the script into the image
