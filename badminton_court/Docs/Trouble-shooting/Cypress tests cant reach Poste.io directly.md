# Cypress tests can't reach Poste.io directly in staging
## Source: Docs/Trouble-shooting/Cypress tests cant reach Poste.io directly.md

## Troubleshooting Cypress tests that can't reach Poste.io directly in staging

### Symptom
Cypress test step `Given a regular user mailbox exists` fails in staging with:
```
cy.request() timed out waiting 5000ms for a response from your server.

The request we sent was:
Method: POST
URL: https://mail-staging/api/domains/aeropace.com/mailboxes

No response was received within the timeout.
```

The same step works in dev.

### Root Cause
`mail-staging` is a **Docker internal hostname** — it only resolves inside the staging VM's Docker network. Cypress runs on your local machine (or CI runner), which cannot resolve `mail-staging`.

| Environment | Where Cypress runs | Can resolve `mail-staging`? |
|-------------|-------------------|----------------------------|
| Dev | Local machine | ✅ Yes (Docker port mapping makes `mail-test` reachable) |
| Staging | Local machine | ❌ No (`mail-staging` is Docker-internal on the VM) |

The step definition calls Poste.io's API directly:
```javascript
const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;
cy.request({
    method: 'POST',
    url: `${apiHost}/api/domains/${domain}/mailboxes`,  // ← https://mail-staging/... — can't resolve!
});
```

### Diagnostic Steps

1. **Check the Cypress env vars:**
   ```bash
   cd badminton_court
   grep "POSTE_HOSTNAME" .env.staging
   # Staging: POSTE_HOSTNAME=mail-staging (Docker-internal)
   ```

2. **Try to resolve the hostname from your machine:**
   ```bash
   ping mail-staging
   # ping: mail-staging: Name or service not known
   ```

3. **Check the Cypress error log** — if the URL contains a Docker-internal hostname, that's the issue.

### Fix

Route mailbox creation **through Django** in staging. Django can reach Poste.io via the Docker network. Cypress calls Django, Django calls Poste.io.

#### Step 1: Create a Django endpoint for mailbox creation

In `court_management/components/views/test_database.py`:

```python
@csrf_exempt
@require_POST
def create_mailbox(request):
    """Create a mailbox on Poste.io via API (staging-safe)."""
    if not settings.DEBUG:
        return JsonResponse({'status': 'error', 'message': 'Only available in debug mode'}, status=403)

    import json, requests, urllib3
    urllib3.disable_warnings(InsecureRequestWarning)

    try:
        body = json.loads(request.body)
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return JsonResponse({'status': 'error', 'message': 'email and password are required'}, status=400)

        local_part, domain = email.split('@')

        api_host = settings.POSTE_API_HOST
        api_user = settings.POSTE_API_USER
        api_password = settings.POSTE_ADMIN_PASSWORD

        session = requests.Session()
        session.verify = False
        session.auth = (api_user, api_password)

        # Check if mailbox already exists
        check_response = session.get(f"{api_host}/api/v1/boxes/{email}", timeout=10)
        if check_response.status_code == 200:
            return JsonResponse({'status': 'success', 'message': f'Mailbox {email} already exists'})

        # Create the mailbox
        response = session.post(
            f"{api_host}/api/v1/domains/{domain}/mailboxes",
            json={'local_part': local_part, 'password': password, 'active': True},
            timeout=10
        )

        if response.status_code in [200, 201, 409]:
            return JsonResponse({'status': 'success', 'message': f'Mailbox {email} created'})
        else:
            return JsonResponse({
                'status': 'error',
                'message': f'Poste.io API returned {response.status_code}: {response.text}'
            }, status=500)

    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
```

#### Step 2: Add URL route

In `court_management/urls.py`:
```python
path('api/test/create-mailbox/', views.create_mailbox, name='test-create-mailbox'),
```

#### Step 3: Wire up imports

In `court_management/components/views/__init__.py`:
```python
from .test_database import reset_django_database, reset_posteio_database, reset_posteio_database_staging, reset_all_databases, create_mailbox
```

In `court_management/views.py`:
```python
from .components.views import (
    # ... existing imports ...
    reset_django_database, reset_posteio_database, reset_posteio_database_staging,
    reset_all_databases, create_mailbox,
    # ...
)
```

#### Step 4: Add a staging-specific Cypress command

In `cypress/support/commands/mailbox.cy.js` (or `database.cy.js`):

```javascript
Cypress.Commands.add('createRegularUserMailboxStaging', () => {
  const email = Cypress.env('REGULARUSER_EMAIL');
  const password = Cypress.env('REGULARUSER_PASSWORD');

  cy.request({
    method: 'POST',
    url: '/api/test/create-mailbox/',  // ← Goes to Django, not Poste.io directly
    body: { email, password },
    failOnStatusCode: false
  }).then((response) => {
    if (response.status === 200) {
      cy.log(`✓ Mailbox ready (staging): ${email}`);
    } else {
      cy.log(`⚠ Mailbox creation returned ${response.status}: ${JSON.stringify(response.body)}`);
    }
  });
});
```

#### Step 5: Update the step definition to dispatch

In `cypress/support/step_definitions/common.js`:

```javascript
Given('a regular user mailbox exists', () => {
  const env = Cypress.env('ENVIRONMENT') || 'development';
  cy.log(`Environment: ${env} — dispatching to appropriate mailbox creation`);

  if (env === 'staging' || env === 'production') {
    // Staging: route through Django (Cypress can't reach mail-staging directly)
    cy.createRegularUserMailboxStaging();
    return;
  }

  // Dev: call Poste.io API directly (unchanged — works because Docker
  // port mapping makes mail-test reachable from the Cypress host)
  const email = Cypress.env('REGULARUSER_EMAIL');
  const [localPart, domain] = email.split('@');
  const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;
  cy.request({
    method: 'POST',
    url: `${apiHost}/api/domains/${domain}/mailboxes`,
    body: { local_part: localPart, password: Cypress.env('REGULARUSER_PASSWORD'), active: true },
    auth: { username: Cypress.env('POSTE_API_USER'), password: Cypress.env('POSTE_ADMIN_PASSWORD') },
    failOnStatusCode: false
  });
});
```

### The Pattern: Route Through Django in Staging

This same pattern applies to ANY operation that needs to reach Docker-internal services:

| Operation | Dev (direct) | Staging (via Django) |
|-----------|--------------|---------------------|
| Create mailbox | `POST https://mail-test:443/api/domains/.../mailboxes` | `POST /api/test/create-mailbox/` |
| Reset Poste.io | `docker-compose down/up` | `POST /api/test/reset-posteio-db-staging/` |
| Check SMTP auth | `POST https://mail-test:443/...` | `GET /api/test/check-smtp-auth/` |
| Setup Poste.io | Web UI wizard | Web UI wizard (via `cy.visit()`) |

Cypress always talks to Django via the public URL. Django talks to Docker-internal services via the Docker network.

### Verification

```bash
# Staging: create mailbox via Django
curl -s -X POST https://humrine.com/court-staging/api/test/create-mailbox/ \
  -H "Content-Type: application/json" \
  -d '{"email": "regularuser@aeropace.com", "password": "StrongPassword123!"}'
# Expected: {"status":"success","message":"Mailbox regularuser@aeropace.com created"}
```

### Related Files
- `badminton_court/court_management/components/views/test_database.py` — `create_mailbox` view
- `badminton_court/court_management/urls.py` — URL route
- `badminton_court/cypress/support/commands/mailbox.cy.js` — `cy.createRegularUserMailboxStaging()`
- `badminton_court/cypress/support/step_definitions/common.js` — step dispatch
- See also: [Poste.io reset command fails in staging](Poste.io%20reset%20command%20fails%20in%20staging.md)
- See also: [SMTPRecipientsRefused on user signup](SMTPRecipientsRefused%20on%20user%20signup.md)
