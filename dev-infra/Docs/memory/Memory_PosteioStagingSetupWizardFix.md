# Memory Detail: Poste.io Setup Wizard — Staging Environment Fix

## Environment
**Staging Environment** — GCP VM (`35.198.231.9`), Linux host, Docker Engine (not Docker Desktop).
This memory covers the staging-specific fix for the Poste.io setup wizard.

> For the **dev** (Windows + Docker Desktop) variant, see `Memory_PosteioDevSetupWizardFix.md`.

## Issue Summary
After the dev-environment fix was merged, the same Cypress feature (`posteio-flow.feature`) had to run against **staging**. The existing `setupPosteio` command was hard-coded to `https://localhost:8443` (dev), and the `common.js` step definitions silently defaulted to dev behavior when `ENVIRONMENT` was unset. Three staging-specific failures appeared:

1. Cypress hit `ENOTFOUND mail-staging` — the Docker-internal hostname was unreachable from the Cypress host.
2. Poste.io setup wizard returned **HTTP 500** when the hostname field was filled with the staging VM's raw IP (`35.198.231.9`). Poste.io's installer rejects a bare IP as the mail server hostname — it requires a real domain.
3. `cy.resetPosteioDb` (the dev command) tried to run `docker-compose down` against the staging container, which is not managed by the local `docker-compose.yml`. It silently failed and the staging volume was never wiped.

## Root Causes

### 1. Hard-coded dev URLs in Cypress commands
- `setupPosteio.cy.js` visited `https://localhost:8443` unconditionally.
- `database.cy.js` `resetPosteioDb` targeted the dev `mail-test` container.

### 2. Step definitions silently defaulted to dev
- `cypress/support/step_definitions/common.js` checked `Cypress.env('ENVIRONMENT')` and, when absent, fell back to `'dev'`.
- This violated Roadmap #52 (no silent environment defaults). A misconfigured staging run could silently run dev assertions.

### 3. Hostname field filled with raw IP
- Staging setup form was filled with `35.198.231.9` because that's what the Cypress command derived from `GCP_VM_IP`.
- Poste.io's installer validates the hostname as a domain (`aeropace.com`), not an IP. Submitting an IP caused an internal 500 during `server.ini` creation.

### 4. No API-based reset for staging
- Dev reset goes through `docker-compose down` + `docker volume rm`. This is correct for the local dev box, but staging is on a remote GCP VM and the Cypress runner can't `docker-compose down` the staging container directly.
- Staging needed an HTTP API endpoint exposed by the Django app that performs the same reset on the VM, where the docker socket actually lives.

## Resolution

### Fix 1: Staging URL dispatch in `setupPosteio.cy.js`
The `setupPosteio` command now derives its target URL from the environment:

```javascript
const apiHost = Cypress.env('ENVIRONMENT') === 'staging'
    ? `https://${Cypress.env('GCP_VM_IP')}:${Cypress.env('MAIL_HTTPS_HOST_PORT')}`
    : 'https://localhost:8443';
```

The hostname field in the setup form is now filled with `Cypress.env('POSTE_DOMAIN')` (e.g. `aeropace.com`), NOT the raw IP. This fixes the 500 error during `server.ini` creation.

### Fix 2: Strict `ENVIRONMENT` validation in `common.js`
`cypress/support/step_definitions/common.js` no longer falls back to `'dev'`. If `ENVIRONMENT` is not set, the test throws immediately with a clear message:

```javascript
throw new Error(
    'ENVIRONMENT (dev|staging) is required. ' +
    'Set it via cypress.env.json or CYPRESS_ENVIRONMENT. ' +
    'Silent defaults are forbidden per Roadmap #52.'
);
```

Each step that depends on the environment dispatches explicitly:

```javascript
const env = Cypress.env('ENVIRONMENT');
if (env === 'dev') {
    // docker-compose-driven path
} else if (env === 'staging') {
    // API-driven path
} else {
    throw new Error(`Unknown ENVIRONMENT: ${env}`);
}
```

### Fix 3: API-based staging reset
- New Django management command: `court_management/management/commands/reset_posteio_db_staging.py`
  - Calls Docker on the VM (via subprocess) to `docker rm -f` the staging container and `docker volume rm -f` the staging volume.
  - **Skips** the admin mailbox — only wipes the regular-user mailboxes, so the admin account persists across test runs.
- New Django views in `court_management/components/views/test_database.py`:
  - `reset_posteio_database_staging` — exposes the reset as an authenticated API endpoint.
  - `create_mailbox` — exposes a programmatic mailbox-creation endpoint (used by `cy.createRegularUserMailboxStaging`).
- New Cypress command in `cypress/support/commands/database.cy.js`: `resetPosteioDbStaging`
  - Calls the Django API endpoint with the test user's credentials.
  - Polls the staging Poste.io HTTPS endpoint for readiness.
- New Cypress command in `cypress/support/commands/mailbox.cy.js`: `createRegularUserMailboxStaging`
  - Calls the Django `create_mailbox` view to provision a mailbox without going through the Poste.io admin UI.

### Fix 4: Use `POSTE_DOMAIN` for the hostname field
- `setupPosteio.cy.js` now reads `Cypress.env('POSTE_DOMAIN')` (configured to `aeropace.com` for staging) and uses that as the hostname field value.
- The bare-IP hostname caused the 500 because Poste.io's `server.ini` writer rejects IP-only hostnames.

## Files Modified
- `cypress/support/commands/setupPosteio.cy.js` — staging URL dispatch, `POSTE_DOMAIN` hostname field
- `cypress/support/commands/database.cy.js` — new `resetPosteioDbStaging` command (API-based)
- `cypress/support/commands/mailbox.cy.js` — new `createRegularUserMailboxStaging` command (API-based)
- `cypress/support/step_definitions/common.js` — environment dispatch, strict `ENVIRONMENT` validation (no defaults)
- `court_management/components/views/test_database.py` — `reset_posteio_database_staging`, `create_mailbox` views
- `court_management/management/commands/reset_posteio_db_staging.py` — new management command (API-only, skips admin mailbox)
- `cypress.env.json` (staging profile) — must include `GCP_VM_IP`, `MAIL_HTTPS_HOST_PORT`, `POSTE_DOMAIN`, `ENVIRONMENT=staging`

## Key Lessons
1. **Never silent-default environment variables.** A missing `ENVIRONMENT` should fail loudly, not silently run dev assertions against staging.
2. **Staging reset must be API-driven.** The Cypress host cannot run `docker-compose down` against a remote VM. Expose a Django endpoint that performs the reset locally on the VM.
3. **Poste.io's hostname field requires a domain, not an IP.** Submitting `35.198.231.9` triggers an internal 500 during `server.ini` creation. Use `POSTE_DOMAIN` (`aeropace.com`).
4. **Staging admin mailbox must persist across test runs.** Unlike dev (where the whole volume is wiped), staging reset skips the admin mailbox so the setup wizard doesn't have to be re-run for every test cycle.

## Verification (staging)
```bash
# 1. Container is healthy
docker ps --filter name=mail-staging
# STATUS should be Up ... (healthy)

# 2. /data is empty (fresh volume after wipe)
docker exec mail-staging ls /data/

# 3. Setup wizard completes
# Cypress posteio-flow.feature should drive the wizard end-to-end

# 4. SMTP auth works
curl -s https://35.198.231.9/api/test/check-smtp-auth/
# Should return: {"status":"ok","protocol":"SSL:465","host":"..."}
```

## Status
- **Dev:** Fixed and verified (see `Memory_PosteioDevSetupWizardFix.md`)
- **Staging:** In progress — volume wiped, container restarted, setup wizard pending Cypress run
- **Production:** Pending — after staging verification

## Related Documentation
- `Memory_PosteioDevSetupWizardFix.md` — dev-environment variant
- `Memory_EnvironmentDispatchProtocol.md` — environment-dispatched test step definitions
- `Memory_StrictEnvironmentValidation.md` — Roadmap #52 enforcement
- `Poste.io setup wizard fails to complete in dev.md` — dev troubleshooting doc
- `Roadmap_Environments_Update.md` — entry #63

## Commit Reference
- Working state: staging fixes applied to `setupPosteio.cy.js`, `database.cy.js`, `mailbox.cy.js`, `common.js`, `test_database.py`, `reset_posteio_db_staging.py`
- To be committed once staging `posteio-flow.feature` passes end-to-end.