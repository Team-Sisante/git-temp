# Memory Detail: Strict Environment Variable Validation

## Purpose
Codifies Roadmap entry #52 — "no silent defaults for environment variables". All code that reads an environment variable (os.environ, Cypress.env, process.env) MUST fail loudly if the variable is missing or has an unknown value. Silent defaults are forbidden.

## The Rule

Every environment variable that drives behavior branching MUST be:
1. Read explicitly (no `|| 'default'` fallback)
2. Validated against an allowed-value list (when applicable)
3. Failed loudly with a clear error message if missing or unknown

Forbidden pattern:
```javascript
env = Cypress.env('ENVIRONMENT') || 'dev'      // silent default
host = os.environ.get('SMTP_HOST', 'localhost') // silent default
port = int(os.environ.get('PORT', '8000'))      // silent default
```

Required pattern:
```javascript
env = Cypress.env('ENVIRONMENT')
if not env:
    raise RuntimeError(
        'ENVIRONMENT is required. Set it via cypress.env.json or CYPRESS_ENVIRONMENT. ' +
        'Silent defaults are forbidden per Roadmap #52.'
    )
if env not in ('dev', 'staging', 'production'):
    raise ValueError(f'Unknown ENVIRONMENT: {env}')
```

## Why This Matters

### 1. Silent defaults mask configuration drift
When a developer forgets to set `ENVIRONMENT=staging` in their local `cypress.env.json`, the test silently runs against dev. The test passes, the PR is merged, and the bug ships to staging — where it explodes because the staging-specific code path was never exercised.

### 2. Silent defaults violate the principle of least surprise
A new contributor running `npx cypress run` for the first time should see a clear error like "ENVIRONMENT is required", not a mysterious test failure caused by silently hitting `localhost:8443`.

### 3. Silent defaults make rollback harder
When staging fails, the first debugging step is "what environment was this run against?". With silent defaults, the answer is ambiguous. With strict validation, the answer is in the error message.

## Where This Rule Applies

### Cypress (`cypress.env`)
- `ENVIRONMENT` — must be `'dev'`, `'staging'`, or `'production'`
- `GCP_VM_IP` — required when `ENVIRONMENT=staging`
- `MAIL_HTTPS_HOST_PORT` — required when `ENVIRONMENT=staging`
- `POSTE_DOMAIN` — required when `ENVIRONMENT=staging`
- `DJANGO_API_URL` — required when `ENVIRONMENT=staging`
- `TEST_AUTH_TOKEN` — required when `ENVIRONMENT=staging`

### Django (`os.environ`)
- `DJANGO_SETTINGS_MODULE` — must point to a valid settings module
- `ENVIRONMENT` — must match the Cypress environment (for API endpoints that branch on it)
- `POSTE_DOMAIN`, `POSTE_ADMIN_EMAIL`, `POSTE_ADMIN_PASSWORD` — required for SMTP setup

### Docker Compose (`.env.docker`)
- `GCP_VM_IP`, `MAIL_HTTPS_HOST_PORT`, `POSTE_DOMAIN` — required for staging compose files
- `UID`, `GID` — required for volume permission handling (no defaults like `1000:0`)

### GoCD (`apps.json`)
- Every app entry must declare its `environment` and `env_var` keys explicitly
- No app may fall back to a default environment

## Enforcement Pattern

### Cypress step definition
```javascript
const env = Cypress.env('ENVIRONMENT');
if (!env) {
    throw new Error(
        'ENVIRONMENT (dev|staging|production) is required. ' +
        'Set it via cypress.env.json or CYPRESS_ENVIRONMENT. ' +
        'Silent defaults are forbidden per Roadmap #52.'
    );
}
const ALLOWED = ['dev', 'staging', 'production'];
if (!ALLOWED.includes(env)) {
    throw new Error(`Unknown ENVIRONMENT: ${env}. Allowed: ${ALLOWED.join(', ')}`);
}
```

### Django settings
```python
ENVIRONMENT = os.environ.get('ENVIRONMENT')
if not ENVIRONMENT:
    raise ImproperlyConfigured(
        'ENVIRONMENT is required. Set it in the environment or .env file. '
        'Silent defaults are forbidden per Roadmap #52.'
    )
if ENVIRONMENT not in ('dev', 'staging', 'production'):
    raise ImproperlyConfigured(f'Unknown ENVIRONMENT: {ENVIRONMENT}')
```

### Docker entrypoint script
```bash
if [ -z "$ENVIRONMENT" ]; then
    echo "ERROR: ENVIRONMENT is required. Silent defaults are forbidden per Roadmap #52." >&2
    exit 1
fi
case "$ENVIRONMENT" in
    dev|staging|production) ;;
    *) echo "ERROR: Unknown ENVIRONMENT: $ENVIRONMENT" >&2; exit 1 ;;
esac
```

## Anti-Patterns (Forbidden)

### `|| 'dev'` fallback
```javascript
const env = Cypress.env('ENVIRONMENT') || 'dev';
```

### `os.environ.get(..., default)`
```python
host = os.environ.get('SMTP_HOST', 'localhost')
port = int(os.environ.get('PORT', '8000'))
```

### `??` operator with default
```javascript
const host = process.env.SMTP_HOST ?? 'localhost';
```

### "Set a sensible default" excuse
```javascript
// "But localhost is a sensible default for dev!"
const env = Cypress.env('ENVIRONMENT') || 'dev';
// FORBIDDEN: "sensible" defaults are exactly what Roadmap #52 forbids.
```

## Allowed Exceptions

The ONLY variables that may have defaults are:

1. Pure logging/display variables — `LOG_LEVEL=INFO`, `DEBUG=false` (these don't drive behavior branching)
2. Inside a `.env.docker.template` file — the template may show a default as documentation, but the actual `.env.docker` must explicitly set the value
3. Inside test fixtures — fixtures may hard-code values for repeatability

If you find yourself wanting to add an exception, document it in this memory first.

## When to Update This Memory
- A new environment is added (e.g. `production`)
- A new variable is added to the required list
- An exception is being considered (must be reviewed before merging)

## Status
- Established: 2026-06-19
- Origin: Roadmap entry #52
- Enforced by: Code review checklist + automated checks in `common.js` and Django settings

## Related Documentation
- `Memory_EnvironmentDispatchProtocol.md` — how to dispatch on `ENVIRONMENT`
- `Memory_PosteioStagingSetupWizardFix.md` — staging fix that motivated this rule
- `Roadmap_Environments_Update.md` — entry #52 (origin), entry #63 (staging fix using this rule)