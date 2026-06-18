# Poste.io SMTP auth fails after fresh volume reset
## Source: Docs/Trouble-shooting/Poste.io SMTP auth fails after fresh volume reset.md

## Troubleshooting Poste.io SMTP authentication failures after volume wipe

### Symptom
After resetting the Poste.io container (e.g., via `cy.resetPosteioDb()` or `docker volume rm`), the SMTP auth check fails:

```
[SSL:465] Authentication failed: (535, b'5.7.8 Authentication failed')
```

Or:
```
[SSL:465] Connection failed: Connection unexpectedly closed: The read operation timed out
```

The web admin UI works, but SMTP login fails.

### Root Cause
When Poste.io starts with a fresh volume, it goes into **setup mode**. The setup wizard must be completed (via the web UI) before:
1. The admin mailbox is created
2. The API becomes functional (returns 301 redirect to setup wizard until complete)
3. SMTP authentication works

The `cy.resetPosteioDb()` command wipes the volume, putting Poste.io back in setup mode. If a test then tries to check SMTP auth WITHOUT first completing the setup wizard, it fails.

### The Chicken-and-Egg Problem

| Operation | Works on fresh Poste.io? | Why |
|-----------|--------------------------|-----|
| Web UI setup wizard (`/admin/install/server`) | ✅ Yes | This is the only way to initialize Poste.io |
| Poste.io REST API (`/api/mailboxes`, `/api/health`) | ❌ No | Returns 301 redirect to setup wizard |
| `setup_posteio_server` management command | ❌ No | Calls `/api/health`, which returns 301 → "API not ready" |
| SMTP auth | ❌ No | Admin mailbox doesn't exist until setup completes |

**Only the web UI setup wizard can initialize a fresh Poste.io.** The API and SMTP are non-functional until setup is complete.

### Diagnostic Steps

1. **Check if Poste.io is in setup mode:**
   ```bash
   curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:8443/
   # 302 = redirecting (likely to setup wizard)
   # 200 = already set up
   ```

2. **Check the API health endpoint:**
   ```bash
   curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:8443/api/health
   # 200 = API ready
   # 301 = redirecting to setup (Poste.io is fresh)
   ```

3. **Test SMTP auth directly:**
   ```bash
   DJANGO_SETTINGS_MODULE=badminton_court.settings ENVIRONMENT=development python manage.py shell -c "
   import smtplib, ssl
   from django.conf import settings
   context = ssl.create_default_context()
   context.check_hostname = False
   context.verify_mode = ssl.CERT_NONE
   try:
       server = smtplib.SMTP_SSL(settings.EMAIL_HOST, settings.EMAIL_PORT, context=context, timeout=30)
       server.login(settings.EMAIL_HOST_USER, settings.POSTE_ADMIN_PASSWORD)
       print('SMTP auth SUCCESS')
       server.quit()
   except Exception as e:
       print(f'SMTP FAILED: {e}')
   "
   ```

4. **Check Poste.io container logs:**
   ```bash
   docker logs mail-test --tail=30 2>&1
   ```
   Look for `sendmail: recipient address sh@example.com not accepted` — this indicates Poste.io's mail services didn't fully initialize.

### Fix

#### Step 1: Complete the Poste.io setup wizard via Cypress

The `cy.setupPosteio()` command (in `cypress/support/commands/setupPosteio.cy.js`) drives the web UI setup wizard. It's called by the `When I set up Poste.io and log in` step.

**Option A: Run `posteio-flow.feature` first scenario**
```cucumber
Scenario: Setup the Poste.io server and log in
  When I set up Poste.io and log in
  Then I should see the Poste.io dashboard
```

**Option B: Add the setup step to your test's Background**
```cucumber
Background:
  Given I set up Poste.io and log in    # ← This runs the setup wizard if needed
  And the mail server is ready
  ...
```

The `cy.setupPosteio()` command is **idempotent**:
- **Fresh Poste.io**: runs the setup wizard → creates admin account → logs in
- **Already configured**: detects setup is complete → just logs in (fast path)

```javascript
cy.visit(apiHost);
cy.url().then((url) => {
    if (url.includes('/webmail/')) {
        // Already set up — just log in
        cy.visit(`${apiHost}/admin/login`);
        performLogin(adminEmail, adminPassword);
    } else {
        // Fresh — run the setup wizard
        performSetup(apiHost, adminEmail, adminPassword);
    }
});
```

#### Step 2: Restart Poste.io after setup (if SMTP still fails)

After the setup wizard completes, Poste.io's SMTP service may need a restart to fully initialize:

```bash
cd badminton_court
docker-compose --env-file .env.docker --profile dev restart mail-test
sleep 45  # Wait for all services to start
```

#### Step 3: Increase SMTP timeout in the check-smtp-auth view

The `test_check_smtp_auth.py` view had `timeout=10`, which is too short for Poste.io's slow SSL handshake. Increase to `timeout=30`:

```python
# In court_management/components/views/test_check_smtp_auth.py
# Change all three timeout=10 to timeout=30:
with smtplib.SMTP_SSL(host, port, context=context, timeout=30) as server:
    server.login(user, password)
```

#### Step 4: Increase wait in `setupPosteio.cy.js`

After the setup wizard submits, Poste.io needs time to start its mail services. Change `cy.wait(5000)` to `cy.wait(15000)`:

```javascript
function performSetup(apiHost, adminEmail, adminPassword) {
    // ... fill form ...
    cy.get('button[type="submit"]', {timeout: 10000}).clickWithHighlight();
    
    cy.wait(15000);  // ← Increased from 5000 — Poste.io needs time to start mail services
    cy.url().should('include', '/admin/').should('not.include', '/install/');
    // ...
}
```

### Verification

```bash
# 1. SMTP auth should succeed
curl -s http://localhost:8000/api/test/check-smtp-auth/
# Expected: {"status":"ok","protocol":"SSL:465","host":"localhost"}

# 2. Poste.io API should be functional (not redirecting)
curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:8443/api/health
# Expected: 200
```

### Why This Happens

Poste.io is a full mail server suite (postfix + dovecot + clamav + rspamd + nginx + more). When the volume is fresh:
1. The container starts, but no admin account exists
2. The web UI shows a setup wizard at `/admin/install/server`
3. The API redirects all requests to the setup wizard (301)
4. SMTP accepts connections but can't authenticate (no users exist)
5. Only after the setup wizard completes do all services become functional

### Related Files
- `badminton_court/cypress/support/commands/setupPosteio.cy.js` — drives the web setup wizard
- `badminton_court/court_management/components/views/test_check_smtp_auth.py` — SMTP auth check (increase timeout)
- `badminton_court/cypress/support/commands/database.cy.js` — `cy.resetPosteioDb()` (the cause)
- See also: [Poste.io setup wizard assertion fails](Poste.io%20setup%20wizard%20assertion%20fails.md)
- See also: [Poste.io SMTP auth timeout via Django endpoint](Poste.io%20SMTP%20auth%20timeout%20via%20Django%20endpoint.md)
