# PyInstaller binary missing templates
## Source: Docs/Trouble-shooting/PyInstaller binary missing templates.md

## Troubleshooting PyInstaller binary TemplateDoesNotExist errors

### Symptom
The staging deployment succeeds, but when accessing the dashboard or booking pages, Django raises:
```
TemplateDoesNotExist at /dashboard/
court_management/index.html

TemplateDoesNotExist at /bookings/create/
court_management/booking_form.html
```

The Python Path shows a PyInstaller binary:
```
Python Path:
['/app', '/tmp/_MEIXq6JRv/base_library.zip', ...]
```

### Root Cause
PyInstaller bundles Python modules but does NOT automatically include non-Python data files like HTML templates. The `Dockerfile.compile` had `--add-data` flags for:
- `templates` (project-level)
- `static`
- `news/templates`
- `news/migrations`
- `court_management/management/commands` (just commands, not templates!)

**Missing:**
- `court_management/templates` ← This is what Django looks for (for `court_management/index.html`, etc.)
- `inventory/templates` (if any)
- `badminton_court/templates`
- All migration directories

With `APP_DIRS: True` in Django's `TEMPLATES` setting, Django looks for templates at `<app>/templates/<app>/<template_name>`. So `court_management/index.html` is looked up at `court_management/templates/court_management/index.html` — which wasn't bundled.

### Diagnostic Steps

1. **Check the error's Python Path** — if it shows `/tmp/_MEI...`, it's a PyInstaller binary.

2. **Verify which template directories exist in the repo:**
   ```bash
   cd badminton_court
   find . -type d -name "templates" -not -path "./.git/*" -not -path "./venv/*"
   ```
   Typical output:
   ```
   ./badminton_court/templates
   ./court_management/templates
   ./news/templates
   ./templates
   ```

3. **Check the Dockerfile.compile's `--add-data` flags:**
   ```bash
   grep "add-data" Dockerfile.compile
   ```
   Look for missing template directories.

4. **Verify templates are bundled in the running binary:**
   ```bash
   ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
     "sudo docker exec badminton-staging-web-staging-1 find /tmp/_MEI* -name 'index.html' -path '*court_management*'"
   ```
   If this returns nothing, the templates aren't bundled.

### Fix

#### Step 1: Add missing `--add-data` flags to `Dockerfile.compile`

Find the `pyinstaller` command's `--add-data` section and ensure ALL template and migration directories are included:

```dockerfile
        --add-data "court_management/management/commands:court_management/management/commands" \
        --add-data "court_management/templates:court_management/templates" \
        --add-data "court_management/migrations:court_management/migrations" \
        --add-data "inventory/templates:inventory/templates" \
        --add-data "inventory/migrations:inventory/migrations" \
        --add-data "news/templates:news/templates" \
        --add-data "news/migrations:news/migrations" \
        --add-data "badminton_court/templates:badminton_court/templates" \
        --add-data "templates:templates" \
        --add-data "static:static" \
```

**Critical additions:**
- `court_management/templates` ← fixes dashboard, booking_form, base.html, etc.
- `court_management/migrations` ← fixes database migrations
- `inventory/templates` and `inventory/migrations`
- `badminton_court/templates`

#### Step 2: Rebuild and redeploy

1. Commit & push the `Dockerfile.compile` change
2. Trigger `badminton_court-artifacts` pipeline (rebuilds the binary)
3. Trigger `badminton_court-staging` pipeline (deploys)

### Why `--collect-submodules` Isn't Enough

The Dockerfile already had:
```
--collect-submodules court_management
```

But `--collect-submodules` only collects Python modules (`.py` files), NOT data files (`.html`, `.css`, `.js`, etc.). For non-Python files, you need explicit `--add-data` flags (or `--collect-all`, which does both but is slower and pulls in unintended files).

### The `--add-data` Format

```
--add-data "SOURCE:DEST"
```

- **SOURCE** — path relative to the build context (the repo root)
- **DEST** — path inside the bundled binary's virtual filesystem
- On Linux, the separator is `:` (on Windows it's `;`)

The DEST should match the SOURCE path so Django's template loader can find them at the same relative location.

### Verification

After redeployment:

```bash
# 1. Dashboard should return HTTP 200, not 500
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://humrine.com/court-staging/dashboard/

# 2. Templates should be in the binary
ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
  "sudo docker exec badminton-staging-web-staging-1 find /tmp/_MEI* -name 'index.html' -path '*court_management*'"
# Should return: /tmp/_MEIxxxx/court_management/templates/court_management/index.html
```

### Related Files
- `badminton_court/Dockerfile.compile` — the PyInstaller build command
- `badminton_court/badminton_court/settings/base.py` — `TEMPLATES` config with `APP_DIRS: True`
- See also: [PyInstaller build fails on missing directories](PyInstaller%20build%20fails%20on%20missing%20directories.md)
