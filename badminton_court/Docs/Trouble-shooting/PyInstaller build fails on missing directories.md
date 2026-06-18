# PyInstaller build fails on missing directories
## Source: Docs/Trouble-shooting/PyInstaller build fails on missing directories.md

## Troubleshooting PyInstaller "Unable to find" build errors

### Symptom
The `badminton_court-artifacts` pipeline fails during the PyInstaller build step with:
```
ERROR: Unable to find '/app/inventory/templates' when adding binary and data files.
```

The build aborts and no binary is produced.

### Root Cause
The `Dockerfile.compile` had `--add-data` flags for directories that **don't exist** in the repo. For example:

```dockerfile
--add-data "inventory/templates:inventory/templates"
```

But `inventory/templates` doesn't exist — the `inventory` app has no templates directory. PyInstaller refuses to build when a `--add-data` source path doesn't exist.

This happened when adding `--add-data` flags to fix [missing templates in the binary](PyInstaller%20binary%20missing%20templates.md). The fix added flags for all possible template directories, but not all apps actually have templates.

### Diagnostic Steps

1. **Check which template directories actually exist:**
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
   Note: `./inventory/templates` is NOT in the list.

2. **Check the Dockerfile.compile's `--add-data` flags:**
   ```bash
   grep "add-data" Dockerfile.compile
   ```
   Look for flags referencing directories that don't exist.

### Fix

#### Option A: Remove the non-existent directories from `--add-data` (simple)

Just remove the `--add-data` flags for directories that don't exist:

```dockerfile
# Remove this line (inventory/templates doesn't exist):
--add-data "inventory/templates:inventory/templates" \
```

**Downside:** If you later add an `inventory/templates` directory, you'll need to remember to add the `--add-data` flag back.

#### Option B: Make `--add-data` conditional (robust, recommended)

Replace the static `--add-data` flags with a shell loop that only includes directories that actually exist:

```dockerfile
# Compile the binary
# Build the --add-data arguments dynamically based on which directories
# actually exist. This prevents "Unable to find" errors when an app
# doesn't have a templates/ or migrations/ directory.
RUN export PYINSTALLER_BUILD=true \
    && export DJANGO_SETTINGS_MODULE=badminton_court.settings \
    && export DEBUG=True \
    && export SECRET_KEY=build-key-for-pyinstaller \
    && export DATABASE_URL=sqlite:///tmp/dummy.db \
    && export GCP_PROJECT_ID=dummy-for-build \
    && export SITE_HEADER=dummy-for-build \
    && export SITE_TITLE=dummy-for-build \
    && export SITE_INDEX_TITLE=dummy-for-build \
    && export APP_PROTOCOL=http \
    && export APP_DOMAIN=localhost \
    && export APP_PORT=8000 \
    && export ALLOWED_HOSTS=localhost \
    && export CSRF_TRUSTED_ORIGINS=http://localhost:8000 \
    && export POSTE_PROTOCOL=http \
    && export POSTE_HOSTNAME=localhost \
    && export POSTE_PORT=25 \
    && export POSTE_API_USER=dummy \
    && export POSTE_ADMIN_PASSWORD=dummy \
    && export POSTEIO_DB_HOST=dummy \
    && export POSTEIO_DB_PORT=5432 \
    && export POSTEIO_DB_NAME=dummy \
    && export POSTEIO_DB_USER=dummy \
    && export POSTEIO_DB_PASSWORD=dummy \
    && export ADMIN_PASSWORD=dummy \
    && export SUPPORT_EMAIL=dummy@example.com \
    && export PYTHONPATH=/app \
    && ADD_DATA_ARGS="" \
    && for dir in \
        court_management/management/commands \
        court_management/templates \
        court_management/migrations \
        inventory/templates \
        inventory/migrations \
        news/templates \
        news/migrations \
        badminton_court/templates \
        templates \
        static \
    ; do \
        if [ -d "/app/$dir" ]; then \
            ADD_DATA_ARGS="$ADD_DATA_ARGS --add-data \"$dir:$dir\""; \
            echo "Including: $dir"; \
        else \
            echo "Skipping (not found): $dir"; \
        fi; \
    done \
    && eval pyinstaller \
        --onefile \
        --name badminton_court_linux \
        --clean \
        --collect-submodules celery \
        --collect-submodules kombu \
        --collect-submodules badminton_court \
        --collect-submodules court_management \
        --collect-submodules inventory \
        --collect-submodules news \
        --copy-metadata django-bootstrap5 \
        --copy-metadata django-allauth \
        --hidden-import badminton_court.context_processors \
        --hidden-import court_management.adapters \
        --hidden-import court_management.email_backend \
        $ADD_DATA_ARGS \
        --collect-all allauth \
        manage.py
```

**Key changes:**
1. `ADD_DATA_ARGS=""` — start with empty string
2. `for dir in ...` — loop over each candidate directory
3. `if [ -d "/app/$dir" ]` — only add to args if directory exists
4. `eval pyinstaller ... $ADD_DATA_ARGS` — `eval` expands the variable, splitting it properly

#### Step 2: Rebuild

Commit & push the `Dockerfile.compile` change, then trigger the `badminton_court-artifacts` pipeline.

### Expected Build Log Output

With the conditional loop, the build log shows:
```
Including: court_management/management/commands
Including: court_management/templates
Including: court_management/migrations
Skipping (not found): inventory/templates
Skipping (not found): inventory/migrations
Including: news/templates
Including: news/migrations
Including: badminton_court/templates
Including: templates
Including: static
INFO: Building EXE from EXE-00.toc completed successfully.
```

Directories that don't exist are skipped — no more "Unable to find" errors.

### Related Files
- `badminton_court/Dockerfile.compile` — the PyInstaller build command
- See also: [PyInstaller binary missing templates](PyInstaller%20binary%20missing%20templates.md)
