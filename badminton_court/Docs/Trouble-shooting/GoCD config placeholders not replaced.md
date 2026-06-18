# GoCD config placeholders not replaced
## Source: Docs/Trouble-shooting/GoCD config placeholders not replaced.md

## Troubleshooting the Badminton Court GoCD deployment

### Symptom
GoCD server fails to start with the error:
```
Error: URL does not seem to be valid.
java.lang.RuntimeException: Failed to start GoCD server.
Caused by: java.lang.NullPointerException
    at com.thoughtworks.go.server.service.GoConfigService.artifactsDir(GoConfigService.java:233)
```

The server crashes with a `NullPointerException` in `artifactsDir()` because the cruise-config.xml contains literal placeholder strings (e.g., `__GIT_REPO_URL_WITH_CREDENTIALS__`) that were never replaced.

### Root Cause
The `Scripts/entrypoint.js` script reads `cruise-config.xml` as a template and replaces `__PLACEHOLDER__` strings with real values. Three problems can prevent replacement:

1. **Inconsistent placeholder names** between `cruise-config.xml` and `apps.json` (e.g., `__GIT_REPO_URL_WITH_CREDENTIALS__` in XML vs `__BADMINTON_COURT_REPO_URL_WITH_CREDENTIALS__` in apps.json)
2. **Wrong `env_var` name** in `apps.json` (e.g., `GIT_REPO_REPONAME` when `.env.docker` defines `GIT_REPO_BADMINTON_REPONAME`)
3. **Trailing whitespace** in `.env.docker` values producing malformed URLs like `https://TOKEN @github.com/...`
4. **Missing `tokenGenerationKey`** replacement leaving `__TOKEN_GENERATION_KEY__` in the final config

### Diagnostic Steps

1. **Check the entrypoint logs** for placeholder replacement:
   ```bash
   docker logs gocd-server 2>&1 | grep -E '\[entrypoint\.js\].*(Successfully injected|WARNING|ERROR)'
   ```

2. **Verify the live config has no leftover placeholders:**
   ```bash
   MSYS_NO_PATHCONV=1 docker exec gocd-server grep -oE "__[A-Z][A-Z0-9_]*__" /godata/config/cruise-config.xml
   ```
   If this returns any output, placeholders were not replaced.

3. **Check git URLs are well-formed:**
   ```bash
   MSYS_NO_PATHCONV=1 docker exec gocd-server grep '<git url=' /godata/config/cruise-config.xml
   ```
   Each URL should look like `https://ghp_xxx@github.com/team/repo.git` — no spaces, no `__` placeholders.

4. **Cross-reference placeholder names** between `cruise-config.xml` and `apps.json`:
   ```bash
   # In gocd-server/
   grep -oE "__[A-Z][A-Z0-9_]*__" config/cruise-config.xml | sort -u
   grep -oE '"placeholder":\s*"__[A-Z][A-Z0-9_]*__"' apps.json | sort -u
   ```
   Every placeholder used in the XML must have a matching entry in apps.json.

### Fix

#### Step 1: Standardize placeholder names in `cruise-config.xml`

Use the `<APP_NAME>_REPO_URL_WITH_CREDENTIALS__` convention for all apps:

```xml
<!-- humrine_site -->
<git url="__HUMRINE_SITE_REPO_URL_WITH_CREDENTIALS__" branch="master" dest="humrine_site" />

<!-- badminton_court -->
<git url="__BADMINTON_COURT_REPO_URL_WITH_CREDENTIALS__" branch="master" dest="badminton_court" />

<!-- pay-sol -->
<git url="__PAYSOL_REPO_URL_WITH_CREDENTIALS__" branch="master" />
```

#### Step 2: Fix `apps.json` env_var names

Make sure the `env_var` field in apps.json matches what `.env.docker` actually defines:

```json
{
  "apps": [
    {
      "name": "badminton_court",
      "env_var": "GIT_REPO_BADMINTON_REPONAME",
      "placeholder": "__BADMINTON_COURT_REPO_URL_WITH_CREDENTIALS__"
    },
    {
      "name": "pay-sol",
      "env_var": "GIT_PAYSOL_REPONAME",
      "placeholder": "__PAYSOL_REPO_URL_WITH_CREDENTIALS__"
    },
    {
      "name": "humrine_site",
      "env_var": "GIT_HUMRINE_SITE_REPONAME",
      "placeholder": "__HUMRINE_SITE_REPO_URL_WITH_CREDENTIALS__"
    }
  ]
}
```

#### Step 3: Strip trailing whitespace from `.env.docker`

```bash
sed -i 's/[[:space:]]*$//' .env.docker
```

#### Step 4: Add post-replacement verification to `entrypoint.js`

Add this block after all placeholder substitutions to fail fast on leftover placeholders:

```javascript
// STEP 4.5: Verifying no placeholders remain in cruise-config.xml...
const finalConfigContent = fs.readFileSync(CRUISE_CONFIG, 'utf8');
const leftoverPlaceholders = finalConfigContent.match(/__[A-Z][A-Z0-9_]*__/g);
if (leftoverPlaceholders) {
  const unique = [...new Set(leftoverPlaceholders)];
  log(`ERROR: ${unique.length} unreplaced placeholder(s) remain in cruise-config.xml:`);
  unique.forEach(p => log(`  - ${p}`));
  process.exit(1);
}
log('All placeholders successfully replaced.');
```

#### Step 5: Recreate the gocd-server container

Use menu option **1.13** (Force-recreate gocd-server) or run:
```bash
cd gocd-server
docker compose --env-file .env.docker up -d --force-recreate --no-deps gocd-server
```

### Verification

```bash
# Should return no output (all placeholders replaced)
MSYS_NO_PATHCONV=1 docker exec gocd-server grep -oE "__[A-Z][A-Z0-9_]*__" /godata/config/cruise-config.xml

# Should show valid git URLs
MSYS_NO_PATHCONV=1 docker exec gocd-server grep '<git url=' /godata/config/cruise-config.xml
```

### Related Files
- `gocd-server/config/cruise-config.xml` — template with placeholders
- `gocd-server/apps.json` — maps app names to env vars and placeholders
- `gocd-server/Scripts/entrypoint.js` — performs placeholder replacement
- `gocd-server/.env.docker` — source of env var values
