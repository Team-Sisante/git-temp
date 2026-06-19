# Poste.io setup wizard fails to complete in staging environment
## Source: Docs/Trouble-shooting/Poste.io setup wizard fails to complete in staging.md

## Troubleshooting the Poste.io setup wizard in the staging environment

> **Environment:** Staging only (GCP VM `35.198.231.9`, Linux host, Docker Engine).
> For the **dev** variant, see `Poste.io setup wizard fails to complete in dev.md`.

### Symptom
After merging the dev-environment fix, the same Cypress feature (`posteio-flow.feature`) was run against staging. It failed in three distinct ways:

1. **`ENOTFOUND mail-staging`** — Cypress tried to resolve the Docker-internal hostname `mail-staging`, which doesn't exist on the Cypress host.
2. **HTTP 500 on the setup form submission** — the Poste.io setup wizard crashed when the hostname field was filled with the VM's raw IP `35.198.231.9`.
3. **`cy.resetPosteioDb` silently failed** — the dev command tried `docker-compose down mail-staging`, but `mail-staging` isn't in the local `docker-compose.yml`. The volume was never wiped.

### Root Causes (Multiple, Cascading)

#### 1. Hard-coded dev URLs in Cypress commands
`setupPosteio.cy.js` visited `https://localhost:8443` unconditionally.

**Diagnostic:**
```javascript
console.log(Cypress.env('ENVIRONMENT'));  // 'staging'
console.log(apiHost);                      // still 'https://localhost:8443' → wrong
```

#### 2. Step definitions silently defaulted to dev
`cypress/support/step_definitions/common.js` checked `Cypress.env('ENVIRONMENT')` and, when absent, fell back to `'dev'`. This violated Roadmap #52.

**Diagnostic:**
```javascript
const env = Cypress.env('ENVIRONMENT') || 'dev';   // ← silent default — FORBIDDEN
```

#### 3. Hostname field filled with raw IP
Poste.io's installer validates the hostname as a domain (`aeropace.com`), not an IP.

**Diagnostic:**
```bash
# Visit https://35.198.231.9:8446/ in a browser
# Fill hostname: 35.198.231.9
# Submit
# Result: HTTP 500 — server.ini cannot be written with IP-only hostname

docker logs mail-staging --tail 50
# Look for: "server.ini" write error / "invalid hostname" / PHP exception
```

#### 4. No API-based reset for staging
Dev reset goes through `docker-compose down` + `docker volume rm`. On staging, the Cypress runner is on the user's local machine and can't `docker-compose down` the remote VM's container.

**Diagnostic:**
```bash
docker-compose -f /path/to/staging/docker-compose.yml down mail-staging
# Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

### Fix

#### Fix 1: Staging URL dispatch in `setupPosteio.cy.js`

```javascript
const apiHost = Cypress.env('ENVIRONMENT') === 'staging'
    ? `https://${Cypress.env('GCP_VM_IP')}:${Cypress.env('MAIL_HTTPS_HOST_PORT')}`
    : 'https://localhost:8443';

const hostname = Cypress.env('ENVIRONMENT') === 'staging'
    ? Cypress.env('POSTE_DOMAIN')   // 'aeropace.com'
    : 'localhost';

cy.get('#install_hostname').clear().typeWithHighlight(hostname);
```

Required `cypress.env.json` (staging profile):
```json
{
    "ENVIRONMENT": "staging",
    "GCP_VM_IP": "35.198.231.9",
    "MAIL_HTTPS_HOST_PORT": "8446",
    "POSTE_DOMAIN": "aeropace.com",
    "POSTE_ADMIN_EMAIL": "admin@aeropace.com",
    "POSTE_ADMIN_PASSWORD": "..."
}
```

#### Fix 2: Strict `ENVIRONMENT` validation in `common.js`

```javascript
const env = Cypress.env('ENVIRONMENT');
if (!env) {
    throw new Error(
        'ENVIRONMENT (dev|staging) is required. ' +
        'Set it via cypress.env.json or CYPRESS_ENVIRONMENT. ' +
        'Silent defaults are forbidden per Roadmap #52.'
    );
}
if (env !== 'dev' && env !== 'staging') {
    throw new Error(`Unknown ENVIRONMENT: ${env}`);
}

if (env === 'dev') {
    // docker-compose-driven path
} else if (env === 'staging') {
    // API-driven path
}
```

#### Fix 3: API-based staging reset

```python
# court_management/management/commands/reset_posteio_db_staging.py

class Command(BaseCommand):
    def handle(self, *args, **options):
        subprocess.run(['docker', 'rm', '-f', 'mail-staging'], check=False)
        subprocess.run(
            ['docker', 'volume', 'rm', '-f', 'badminton-staging_poste_data_staging'],
            check=False
        )
        subprocess.run(
            ['docker-compose', '--env-file', '.env.staging', 'up', '-d', 'mail-staging'],
            check=True
        )
        # NOTE: This command does NOT re-create the admin mailbox.
        # The admin account persists across staging test runs.
```

```python
# court_management/components/views/test_database.py

@require_http_methods(['POST'])
def reset_posteio_database_staging(request):
    if not request.user.is_staff:
        return JsonResponse({'error': 'forbidden'}, status=403)
    call_command('reset_posteio_db_staging')
    return JsonResponse({'status': 'ok'})

@require_http_methods(['POST'])
def create_mailbox(request):
    if not request.user.is_staff:
        return JsonResponse({'error': 'forbidden'}, status=403)
    # ... create mailbox via Poste.io admin API ...
    return JsonResponse({'status': 'ok'})
```

```javascript
// cypress/support/commands/database.cy.js
Cypress.Commands.add('resetPosteioDbStaging', () => {
    const apiUrl = Cypress.env('DJANGO_API_URL');
    cy.request({
        method: 'POST',
        url: `${apiUrl}/test/reset-posteio-database-staging/`,
        headers: { 'X-Test-Auth': Cypress.env('TEST_AUTH_TOKEN') },
        failOnStatusCode: false,
    }).then((resp) => {
        expect(resp.status).to.eq(200);
    });

    const apiHost = `https://${Cypress.env('GCP_VM_IP')}:${Cypress.env('MAIL_HTTPS_HOST_PORT')}`;
    const pollPosteioStatus = (remaining) => {
        if (remaining <= 0) throw new Error('Poste.io staging initialization timeout');
        cy.exec(`curl -k -s -o /dev/null -w "%{http_code}" ${apiHost}`, { failOnNonZeroExit: false })
          .then((r) => {
              const code = parseInt(r.stdout.trim(), 10);
              if (code >= 200 && code < 400) {
                  cy.log(`✓ Staging Poste.io ready (HTTP ${code})`);
              } else {
                  cy.wait(2000);
                  pollPosteioStatus(remaining - 1);
              }
          });
    };
    pollPosteioStatus(60);
});
```

#### Fix 4: Use `POSTE_DOMAIN` for the hostname field

```javascript
// In setupPosteio.cy.js
const hostname = Cypress.env('POSTE_DOMAIN');  // 'aeropace.com'
cy.get('#install_hostname').clear().typeWithHighlight(hostname);
```

### Verification

After applying all fixes:

```bash
# 1. ENVIRONMENT is set
npx cypress env
# Should show: ENVIRONMENT=staging, GCP_VM_IP=35.198.231.9, MAIL_HTTPS_HOST_PORT=8446, POSTE_DOMAIN=aeropace.com

# 2. Staging Poste.io container is healthy
docker ps --filter name=mail-staging
# STATUS: Up X seconds (healthy)

# 3. /data is empty (fresh volume)
docker exec mail-staging ls /data/

# 4. Cypress can reach staging
curl -k -s -o /dev/null -w "%{http_code}\n" https://35.198.231.9:8446/
# Should return 200 or 302

# 5. Run the test
npx cypress run --spec cypress/e2e/posteio-flow.feature --env ENVIRONMENT=staging

# 6. SMTP auth works after setup
curl -s https://35.198.231.9/api/test/check-smtp-auth/
# Should return: {"status":"ok","protocol":"SSL:465","host":"..."}
```

### Why This Only Affects Staging

| Concern | Dev | Staging |
|---------|-----|---------|
| Cypress host | Same machine as Docker | Different machine (user's PC) |
| Docker socket access | Direct | None — must go through Django API |
| Hostname field | `localhost` (or any string) | `aeropace.com` (Poste.io rejects bare IPs) |
| Reset path | `docker-compose down` + `volume rm` | `POST /api/test/reset-posteio-database-staging/` |
| Admin mailbox | Recreated every test cycle | Persists across test cycles |
| Step default | Hard-coded dev | Explicit dispatch (no defaults) |

### Related Files
- `cypress/support/commands/setupPosteio.cy.js` — staging URL dispatch, `POSTE_DOMAIN` hostname field
- `cypress/support/commands/database.cy.js` — `resetPosteioDbStaging` (API-based)
- `cypress/support/commands/mailbox.cy.js` — `createRegularUserMailboxStaging` (API-based)
- `cypress/support/step_definitions/common.js` — environment dispatch, strict `ENVIRONMENT` validation
- `court_management/components/views/test_database.py` — `reset_posteio_database_staging`, `create_mailbox` views
- `court_management/management/commands/reset_posteio_db_staging.py` — staging reset (skips admin mailbox)
- `cypress.env.json` (staging) — must include `GCP_VM_IP`, `MAIL_HTTPS_HOST_PORT`, `POSTE_DOMAIN`, `ENVIRONMENT=staging`
- See also: `Poste.io setup wizard fails to complete in dev.md`
- Memory: `Memory_PosteioStagingSetupWizardFix.md`
- Memory: `Memory_EnvironmentDispatchProtocol.md`
- Memory: `Memory_StrictEnvironmentValidation.md