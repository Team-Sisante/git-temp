# GoCD artifacts pipeline reports passed on build failure
## Source: Docs/Trouble-shooting/GoCD artifacts pipeline false pass.md

## Troubleshooting the GoCD artifacts pipeline false-positive pass

### Symptom
The `badminton_court-artifacts` (or `humrine_site-artifacts`, `pay-sol-artifacts`) pipeline **fails to build the Docker images**, but GoCD reports the task as `passed`. The downstream staging pipeline then tries to deploy the new image tag and fails with:
```
failed to resolve reference "ghcr.io/team-sisante/badminton_court-mail:sha-076283f": not found
```

The staging pipeline fails because the image was never pushed, even though the artifacts pipeline claimed success.

### Root Cause
The bash script in the `cruise-config.xml` `<arg>` block runs two commands sequentially without `set -e` or `&&`:

```bash
node Scripts/build-and-push.js
git rev-parse --short HEAD > /shared-tags/badminton_court-tag-${GO_PIPELINE_COUNTER}.txt
```

When `node Scripts/build-and-push.js` exits with code 1 (build failure):
1. Bash **does not exit** — it proceeds to the next line
2. The `git rev-parse` command succeeds (the commit exists)
3. The tag file is written with the new SHA
4. Bash exits with code 0 (from the last command)
5. GoCD reports the task as `passed`

The tag file now contains a SHA for images that were never pushed.

### Diagnostic Steps

1. **Check the artifacts pipeline logs** for actual build failures:
   ```
   Look for:
   ❌ Compilation failed!
   Error: Command failed: node Scripts/compile.js
   Push of badminton_court-mail failed on attempt 3
   ```
   These errors appear BEFORE the `[go] Task status: passed` line.

2. **Verify the image exists in GHCR:**
   ```bash
   docker pull ghcr.io/team-sisante/badminton_court-web:sha-<TAG>
   docker pull ghcr.io/team-sisante/badminton_court-mail:sha-<TAG>
   ```
   If either pull fails with `not found`, the image was never pushed despite the pipeline reporting success.

3. **Check the tag file contents:**
   ```bash
   docker exec gocd-agent-1 cat /shared-tags/badminton_court-tag-<N>.txt
   ```
   If this contains a SHA for which the images don't exist in GHCR, the false-pass bug occurred.

### Fix

#### Step 1: Add `set -e` and `&&` to the artifacts pipeline scripts

In `gocd-server/config/cruise-config.xml`, update ALL three artifacts pipelines.

**badminton_court-artifacts** — find the `<arg>` block:
```xml
<arg><![CDATA[
  git config --global --add safe.directory /badminton_court
  cd /badminton_court
  npm ls axios >/dev/null 2>&1 || npm install axios
  export GITHUB_TOKEN='__GITHUB_TOKEN__'
  node Scripts/build-and-push.js
  git rev-parse --short HEAD > /shared-tags/badminton_court-tag-${GO_PIPELINE_COUNTER}.txt
]]></arg>
```

Replace with:
```xml
<arg><![CDATA[
  set -e
  git config --global --add safe.directory /badminton_court
  cd /badminton_court
  npm ls axios >/dev/null 2>&1 || npm install axios
  export GITHUB_TOKEN='__GITHUB_TOKEN__'
  node Scripts/build-and-push.js && \
  git rev-parse --short HEAD > /shared-tags/badminton_court-tag-${GO_PIPELINE_COUNTER}.txt
]]></arg>
```

**humrine_site-artifacts** — same pattern:
```xml
<arg><![CDATA[
  set -e
  git config --global --add safe.directory /humrine_site
  cd /humrine_site
  npm ls axios >/dev/null 2>&1 || npm install axios
  export GITHUB_TOKEN='__GITHUB_TOKEN__'
  node Scripts/build-and-push.js && \
  git rev-parse --short HEAD > /shared-tags/humrine_site-tag-${GO_PIPELINE_COUNTER}.txt
]]></arg>
```

**pay-sol-artifacts** — no tag file, but `set -e` still valuable:
```xml
<arg><![CDATA[
  set -e
  export GITHUB_TOKEN='__GITHUB_TOKEN__'
  node /pay-sol/Scripts/build-and-push.js
]]></arg>
```

#### Step 2: Apply the changes

Two changes are needed:
1. The `set -e` makes bash exit immediately on any command failure
2. The `&& \` between `build-and-push.js` and `git rev-parse` ensures the tag file is only written if the build succeeds

#### Step 3: Recreate the gocd-server container

Use menu option **1.13** (Force-recreate gocd-server) or:
```bash
cd gocd-server
docker compose --env-file .env.docker up -d --force-recreate --no-deps gocd-server
```

#### Step 4: Verify the fix is live

```bash
MSYS_NO_PATHCONV=1 docker exec gocd-server grep -c "set -e" /godata/config/cruise-config.xml
# Should return: 3 (one per artifacts pipeline)
```

### How `set -e` + `&&` Fixes It

| Scenario | Without fix | With fix |
|----------|-------------|----------|
| `build-and-push.js` succeeds | Tag file written, task passes ✅ | Tag file written, task passes ✅ |
| `build-and-push.js` fails | Tag file written anyway, task passes ❌ (false) | Bash exits immediately (`set -e`), tag file NOT written, task fails ✅ (correct) |

### Verification

After the fix, trigger the artifacts pipeline:
- **If build succeeds**: task shows `passed`, both images exist in GHCR, tag file written
- **If build fails**: task shows `failed` (correctly), no tag file written, staging pipeline cannot be triggered (or fails immediately because no tag file exists)

### Related Files
- `gocd-server/config/cruise-config.xml` — the `<arg>` blocks for all three artifacts pipelines
