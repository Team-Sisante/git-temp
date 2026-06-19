# Memory Detail: Environment Dispatch Protocol for Cypress Step Definitions

## Purpose
Cypress tests must run against both dev and staging environments without code forks. Step definitions in `cypress/support/step_definitions/` dispatch on `Cypress.env('ENVIRONMENT')` to choose the correct command path.

This memory codifies the dispatch protocol so future test additions follow the same pattern.

## The Protocol

### 1. `ENVIRONMENT` is REQUIRED — no silent defaults
Every step definition that touches environment-specific behavior MUST read `Cypress.env('ENVIRONMENT')` and throw immediately if it's missing.

```javascript
const env = Cypress.env('ENVIRONMENT');
if (!env) {
    throw new Error(
        'ENVIRONMENT (dev|staging) is required. ' +
        'Set it via cypress.env.json or CYPRESS_ENVIRONMENT. ' +
        'Silent defaults are forbidden per Roadmap #52.'
    );
}
if (!['dev', 'staging'].includes(env)) {
    throw new Error(`Unknown ENVIRONMENT: ${env}`);
}
```

See `Memory_StrictEnvironmentValidation.md` for the full rationale.

### 2. Two explicit branches — never a ternary on hot paths
For non-trivial dispatch (reset, mailbox creation, setup wizard), use explicit `if/else if/else`. Do NOT use a one-liner ternary that hides one branch behind a colon — the dispatch must be visible at a glance.

```javascript
// CORRECT
if (env === 'dev') {
    cy.resetPosteioDb();
} else if (env === 'staging') {
    cy.resetPosteioDbStaging();
} else {
    throw new Error(`Unknown ENVIRONMENT: ${env}`);
}

// FORBIDDEN (hides the staging branch on one line)
cy[env === 'dev' ? 'resetPosteioDb' : 'resetPosteioDbStaging']();
```

### 3. URL derivation lives in the command, not in the step
Each Cypress command (`setupPosteio`, `resetPosteioDb`, `createRegularUserMailbox`) computes its own URL based on `ENVIRONMENT`. Step definitions just call the command — they don't pass URLs in.

```javascript
// In setupPosteio.cy.js
const apiHost = Cypress.env('ENVIRONMENT') === 'staging'
    ? `https://${Cypress.env('GCP_VM_IP')}:${Cypress.env('MAIL_HTTPS_HOST_PORT')}`
    : 'https://localhost:8443';
```

### 4. Dev path = docker-compose; Staging path = Django API
The two environments have fundamentally different reset/provisioning mechanisms:

| Operation | Dev | Staging |
|-----------|-----|---------|
| Reset Poste.io | `cy.resetPosteioDb` (docker-compose) | `cy.resetPosteioDbStaging` (Django API) |
| Create regular-user mailbox | `cy.createRegularUserMailbox` (UI-driven) | `cy.createRegularUserMailboxStaging` (Django API) |
| Setup wizard URL | `https://localhost:8443` | `https://${GCP_VM_IP}:${MAIL_HTTPS_HOST_PORT}` |
| Hostname field | `localhost` | `POSTE_DOMAIN` (e.g. `aeropace.com`) |
| Admin mailbox lifecycle | Recreated each cycle | Persists across cycles |

### 5. Required `cypress.env.json` keys per environment

Dev:
```json
{
    "ENVIRONMENT": "dev",
    "POSTE_ADMIN_EMAIL": "admin@localhost",
    "POSTE_ADMIN_PASSWORD": "..."
}
```

Staging:
```json
{
    "ENVIRONMENT": "staging",
    "GCP_VM_IP": "35.198.231.9",
    "MAIL_HTTPS_HOST_PORT": "8446",
    "POSTE_DOMAIN": "aeropace.com",
    "DJANGO_API_URL": "https://35.198.231.9/api",
    "TEST_AUTH_TOKEN": "...",
    "POSTE_ADMIN_EMAIL": "admin@aeropace.com",
    "POSTE_ADMIN_PASSWORD": "..."
}
```

If any required key is missing for the active environment, the step definition MUST throw (no silent fallback).

### 6. Test file naming convention
- Feature files: `<feature>.feature` (shared across environments — dispatch happens in step definitions)
- Step definitions: `cypress/support/step_definitions/<feature>.js`
- Environment-specific commands: `cypress/support/commands/<feature>.cy.js`

### 7. Don't fork feature files per environment
A feature like `posteio-flow.feature` should have ONE file. The scenarios should be environment-agnostic. Environment-specific behavior is dispatched inside the step definitions, not by maintaining two `.feature` files.

## Anti-Patterns (Forbidden)

### Silent default to dev
```javascript
const env = Cypress.env('ENVIRONMENT') || 'dev';
```

### Hard-coded URL in step definition
```javascript
Given('I visit Poste.io', () => {
    cy.visit('https://localhost:8443');  // FORBIDDEN: hard-coded dev URL
});
```

### Two feature files for the same scenario
```text
posteio-flow.dev.feature
posteio-flow.staging.feature
// FORBIDDEN: maintain ONE feature file, dispatch in steps
```

### Skipping dispatch entirely
```javascript
// FORBIDDEN: this only works in dev
Given('I reset the Poste.io database', () => {
    cy.resetPosteioDb();  // breaks staging
});
```

## Required Files (Reference)
- `cypress/support/step_definitions/common.js` — dispatch hub for shared steps
- `cypress/support/commands/setupPosteio.cy.js` — `setupPosteio` (URL dispatch)
- `cypress/support/commands/database.cy.js` — `resetPosteioDb` (dev), `resetPosteioDbStaging` (staging)
- `cypress/support/commands/mailbox.cy.js` — `createRegularUserMailbox` (dev), `createRegularUserMailboxStaging` (staging)
- `court_management/components/views/test_database.py` — Django API endpoints used by staging commands
- `court_management/management/commands/reset_posteio_db_staging.py` — staging reset command

## When to Update This Memory
- A new environment is added (e.g. `production` test path)
- A new step definition is added that has environment-specific behavior
- The dispatch logic needs to change (e.g. moving from if/else to a registry pattern)

## Status
- Established: 2026-06-19
- Applies to: All Cypress step definitions in `badminton_court/cypress/support/step_definitions/`
- Enforced by: `common.js` throws on missing/unknown `ENVIRONMENT`

## Related Documentation
- `Memory_StrictEnvironmentValidation.md` — Roadmap #52 enforcement
- `Memory_PosteioStagingSetupWizardFix.md` — staging-specific fix
- `Memory_PosteioDevSetupWizardFix.md` — dev-specific fix
- `Poste.io setup wizard fails to complete in staging.md`
- `Roadmap_Environments_Update.md` — entry #52 (no silent defaults), entry #63 (staging fix)