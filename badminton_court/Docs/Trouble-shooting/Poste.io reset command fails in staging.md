# Poste.io reset command fails in staging (no Docker access)
## Source: Docs/Trouble-shooting/Poste.io reset command fails in staging.md

## Troubleshooting Poste.io reset command failures in staging

### Symptom
The `Given the Poste.io database is reset` step works in dev but fails silently in staging. Tests that depend on a clean Poste.io state fail unpredictably because stale mailboxes persist.

### Root Cause
The `reset_posteio_db.py` management command uses `subprocess.run()` to execute `docker-compose` commands:

```python
# court_management/management/commands/reset_posteio_db.py
def _reset_container_data(self, container_name):
    subprocess.run(['docker-compose', '--env-file', '.env.docker', 'stop', container_name])
    subprocess.run(['docker', 'run', '--rm', '-v', 'badminton_court_poste_data:/data', 'busybox', 'sh', '-c', 'rm -rf /data/*'])
    subprocess.run(['docker-compose', '--env-file', '.env.docker', 'up', '-d', container_name])
```

| Environment | Where Django runs | Docker available? | `docker-compose` works? |
|-------------|------------------|-------------------|-------------------------|
| Dev | Local machine | ✅ Yes (Docker Desktop) | ✅ Yes |
| Staging | Inside `web-staging` container | ❌ No (no Docker-in-Docker) | ❌ Fails silently |

In staging, the Django container:
1. Doesn't have `docker-compose` installed (slim binary image)
2. Doesn't have access to the host's Docker daemon (no `/var/run/docker.sock` mount)
3. Uses the wrong container name (`mail-test` vs `badminton-staging-mail-staging-1`)
4. Uses the wrong volume name (`badminton_court_poste_data` vs the staging volume)

### Diagnostic Steps

1. **Check if Docker is available inside the staging container:**
   ```bash
   ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
     "sudo docker exec badminton-staging-web-staging-1 which docker-compose"
   # If empty, docker-compose isn't installed in the container
   ```

2. **Check the reset command's behavior:**
   ```bash
   ssh -i gocd-server/secrets/agent-key xmione@35.198.231.9 \
     "sudo docker exec badminton-staging-web-staging-1 python manage.py reset_posteio_db"
   # If it returns errors about docker-compose not found, that's the bug
   ```

3. **Verify the Cypress command dispatch:**
   ```bash
   grep -A 10 "the Poste.io database is reset" cypress/support/step_definitions/common.js
   ```
   Check if it dispatches to `cy.resetPosteioDbStaging()` for staging.

### Fix

The fix is to create a **separate staging-safe reset command** that uses Poste.io's REST API instead of `docker-compose`. The dev command stays unchanged.

#### Step 1: Create `reset_posteio_db_staging.py` management command

Create `badminton_court/court_management/management/commands/reset_posteio_db_staging.py`:

```python
# court_management/management/commands/reset_posteio_db_staging.py

from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
import requests
from urllib3.exceptions import InsecureRequestWarning
import urllib3

urllib3.disable_warnings(InsecureRequestWarning)


class Command(BaseCommand):
    help = 'Reset the Poste.io user data via API (staging-safe — no docker-compose)'

    def handle(self, *args, **options):
        if not settings.DEBUG:
            raise CommandError('This command can only be used in DEBUG mode')

        self.stdout.write('Resetting Poste.io user data via API (staging mode)...')

        api_host = getattr(settings, 'POSTE_API_HOST')
        api_user = getattr(settings, 'POSTE_API_USER')
        api_password = getattr(settings, 'POSTE_ADMIN_PASSWORD')

        if not all([api_host, api_user, api_password]):
            raise CommandError('Poste.io configuration missing in settings')

        session = requests.Session()
        session.verify = False
        session.auth = (api_user, api_password)

        # Step 1: Delete all mailboxes (SKIP admin mailbox!)
        self.stdout.write('\nStep 1: Deleting all mailboxes...')
        deleted_mailboxes = self._delete_all_mailboxes(session, api_host, api_user)
        # ...

        # Step 2: Delete all non-default domains (keep admin's domain)
        # ...

        # Step 3: Recreate the admin mailbox (so Poste.io admin still works)
        # ...

    def _delete_all_mailboxes(self, session, api_host, api_user):
        """Delete all mailboxes via API (SKIP admin mailbox!)"""
        # ... see full implementation ...
        for mailbox in mailboxes:
            email = mailbox.get('address') if isinstance(mailbox, dict) else mailbox
            if not email:
                continue

            # CRITICAL: Skip the admin mailbox — deleting it locks us out of the API!
            if email == api_user:
                self.stdout.write(f'    ⏭ Skipping admin mailbox: {email}')
                continue

            del_response = session.delete(f"{api_host}/api/v1/boxes/{email}", timeout=10)
            # ...
```

**Critical:** The `_delete_all_mailboxes` method MUST skip the admin mailbox. If it deletes the admin, the API credentials stop working (chicken-and-egg: you need admin to call the API, but you just deleted admin).

#### Step 2: Add a Django view for the staging reset

In `court_management/components/views/test_database.py`:

```python
@csrf_exempt
@require_POST
def reset_posteio_database_staging(request):
    """Reset Poste.io user data via API (staging-safe)."""
    if not settings.DEBUG:
        return JsonResponse({'status': 'error', 'message': 'Only available in debug mode'}, status=403)
    try:
        call_command('reset_posteio_db_staging')
        return JsonResponse({'status': 'success', 'message': 'Poste.io user data reset successfully (staging mode)'})
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
```

#### Step 3: Add URL route

In `court_management/urls.py`:
```python
path('api/test/reset-posteio-db-staging/', views.reset_posteio_database_staging, name='reset_posteio_db_staging'),
```

#### Step 4: Wire up imports

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

#### Step 5: Add Cypress dispatch

In `cypress/support/commands/database.cy.js`, add a staging command:
```javascript
Cypress.Commands.add('resetPosteioDbStaging', () => {
  cy.log('Resetting Poste.io database (staging mode via API)…');
  cy.request({
    method: 'POST',
    url: '/api/test/reset-posteio-db-staging/',
    headers: { 'Content-Type': 'application/json' },
    body: {},
    failOnStatusCode: false,
    timeout: 120000
  }).then((response) => {
    if (response.status !== 200) {
      throw new Error(`Poste.io DB reset (staging) failed: ${response.body.message}`);
    }
    cy.log('✓ Poste.io database reset successfully (staging mode)');
  });
  cy.wait(2000);
});
```

In `cypress/support/step_definitions/common.js`, dispatch based on environment:
```javascript
Given('the Poste.io database is reset', () => {
  const env = Cypress.env('ENVIRONMENT') || 'development';
  cy.log(`Environment: ${env} — dispatching to appropriate reset command`);

  if (env === 'staging' || env === 'production') {
    cy.resetPosteioDbStaging();
  } else {
    cy.resetPosteioDb();
  }
});
```

### Why Two Commands Instead of One

| Concern | Dev command (`reset_posteio_db`) | Staging command (`reset_posteio_db_staging`) |
|---------|----------------------------------|----------------------------------------------|
| Method | `docker-compose` (wipes volume) | Poste.io REST API (deletes mailboxes/domains) |
| Requires Docker | ✅ Yes | ❌ No |
| Works in staging | ❌ No | ✅ Yes |
| True factory reset | ✅ Yes (volume wipe) | ❌ No (only user data, server config preserved) |

Keeping two commands preserves the dev behavior (true factory reset) while giving staging its own working path.

### Verification

```bash
# In staging:
curl -s -X POST https://humrine.com/court-staging/api/test/reset-posteio-db-staging/
# Expected: {"status":"success","message":"Poste.io user data reset successfully (staging mode)"}

# Verify admin mailbox still exists (was skipped during deletion):
curl -s -X POST https://humrine.com/court-staging/api/test/check-smtp-auth/
# Expected: {"status":"ok","protocol":"SSL:465","host":"localhost"}
```

### Related Files
- `badminton_court/court_management/management/commands/reset_posteio_db.py` — dev command (unchanged)
- `badminton_court/court_management/management/commands/reset_posteio_db_staging.py` — staging command (new)
- `badminton_court/court_management/components/views/test_database.py` — Django views
- `badminton_court/cypress/support/commands/database.cy.js` — Cypress commands
- `badminton_court/cypress/support/step_definitions/common.js` — step dispatch
- See also: [Cypress tests can't reach Poste.io directly in staging](Cypress%20tests%20cant%20reach%20Poste.io%20directly.md)
