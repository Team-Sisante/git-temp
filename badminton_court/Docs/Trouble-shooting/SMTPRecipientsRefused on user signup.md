# SMTPRecipientsRefused on user signup
## Source: Docs/Trouble-shooting/SMTPRecipientsRefused on user signup.md

## Troubleshooting SMTPRecipientsRefused when users sign up

### Symptom
When a user signs up on the staging site, Django raises:
```
SMTPRecipientsRefused at /accounts/signup/
{'regularuser@aeropace.com': (550, b'Error: no such user <regularuser@aeropace.com>')}
```

The signup fails because Poste.io rejects the email with `550: no such user`.

### Root Cause
Poste.io is configured to treat `aeropace.com` as a **local domain**. When Django sends a verification email to `regularuser@aeropace.com`:

1. Poste.io receives the email via SMTP
2. Poste.io checks: "Is `aeropace.com` a local domain?" → YES
3. Poste.io checks: "Does `regularuser` mailbox exist locally?" → NO
4. Poste.io returns `550: no such user`
5. Django raises `SMTPRecipientsRefused`

**Django does NOT create Poste.io mailboxes during signup.** That's by design — in production, users have their own email providers (Gmail, Outlook, etc.). Poste.io would relay to those providers.

In staging, `aeropace.com` is local (so test emails don't leak to the real domain). The trade-off: test mailboxes must be pre-created.

### Why This Is Correct for Staging

| Environment | `aeropace.com` is... | What happens when email is sent to `regularuser@aeropace.com` |
|-------------|---------------------|--------------------------------------------------------------|
| Production | Not local | Poste.io relays to the real `aeropace.com` MX (or Gmail, etc.) |
| Staging | Local | Poste.io delivers locally — mailbox must exist |
| Dev | Local | Same as staging — mailbox must exist |

### Diagnostic Steps

1. **Check if the mailbox exists on Poste.io:**
   ```bash
   # Via the Django API (works in both dev and staging):
   curl -s -X POST http://localhost:8000/api/test/check-user/ \
     -H "Content-Type: application/json" \
     -d '{"email": "regularuser@aeropace.com"}'
   ```

2. **Try sending a test email:**
   ```bash
   DJANGO_SETTINGS_MODULE=badminton_court.settings python manage.py shell -c "
   from django.core.mail import send_mail
   try:
       send_mail('Test', 'Body', 'aeropaceadmin@humrine.com', ['regularuser@aeropace.com'], fail_silently=False)
       print('Email sent successfully')
   except Exception as e:
       print(f'Email failed: {e}')
   "
   ```
   If this fails with `550: no such user`, the mailbox doesn't exist.

### Fix

#### Step 1: Add `Given a regular user mailbox exists` to your test's Background

The mailbox must exist before signup can send an email to it. Add this step to your `.feature` file's Background:

```cucumber
Background:
  Given I set up Poste.io and log in
  And the mail server is ready
  And the Django database is reset
  And the test user is cleaned up
  And a regular user mailbox exists    # ← ADD THIS
```

This step creates the `regularuser@aeropace.com` mailbox on Poste.io before the test scenario runs.

#### Step 2: The step definition (already exists)

The `Given('a regular user mailbox exists')` step is in `cypress/support/step_definitions/common.js`. It dispatches based on environment:

**Dev path** (direct Poste.io API call):
```javascript
// Dev mode: call Poste.io API directly
const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;
cy.request({
    method: 'POST',
    url: `${apiHost}/api/domains/${domain}/mailboxes`,
    body: { local_part: localPart, password: Cypress.env('REGULARUSER_PASSWORD'), active: true },
    auth: { username: Cypress.env('POSTE_API_USER'), password: Cypress.env('POSTE_ADMIN_PASSWORD') },
    failOnStatusCode: false  // ← Idempotent: 409 Conflict is OK
});
```

**Staging path** (via Django API, because Cypress can't reach Poste.io's Docker-internal hostname):
```javascript
// Staging mode: route through Django
cy.createRegularUserMailboxStaging();
// Which calls: POST /api/test/create-mailbox/
```

The step is **idempotent** — `failOnStatusCode: false` means if the mailbox already exists (409 Conflict), the step succeeds without failing.

### Why Django Doesn't Create Mailboxes on Signup

| Concern | Reason |
|---------|--------|
| Decoupling | Django shouldn't know about mail server internals |
| Production reality | Users have their own email providers — Django can't create mailboxes on Gmail |
| Failure isolation | If Poste.io is down, signup should still work (email queues) |

### Alternative: Disable Email Verification in Tests

If you don't want to create mailboxes, you can disable email verification during tests:

```python
# In badminton_court/settings/social_auth.py
import os
is_running_tests = os.getenv('CYPRESS', 'false') == 'true'

if is_running_tests:
    ACCOUNT_EMAIL_VERIFICATION = 'none'  # Disable email verification
else:
    ACCOUNT_EMAIL_VERIFICATION = 'mandatory'
```

But this skips testing the email flow entirely. The mailbox creation approach is better — it tests the full signup flow including email delivery.

### Verification

```bash
# 1. Create the mailbox
curl -s -X POST http://localhost:8000/api/test/create-mailbox/ \
  -H "Content-Type: application/json" \
  -d '{"email": "regularuser@aeropace.com", "password": "StrongPassword123!"}'

# 2. Test signup via curl
curl -s -X POST http://localhost:8000/accounts/signup/ \
  -H "Content-Type: application/json" \
  -d '{"email": "regularuser@aeropace.com", "password1": "StrongPassword123!", "password2": "StrongPassword123!"}'
# Should not return SMTPRecipientsRefused
```

### Related Files
- `badminton_court/cypress/support/step_definitions/common.js` — `Given a regular user mailbox exists` step
- `badminton_court/cypress/support/commands/mailbox.cy.js` — `cy.createRegularUserMailboxStaging()` command
- `badminton_court/court_management/components/views/test_database.py` — `create_mailbox` view (staging path)
- `badminton_court/badminton_court/settings/social_auth.py` — `ACCOUNT_EMAIL_VERIFICATION` setting
- See also: [Poste.io reset command fails in staging](Poste.io%20reset%20command%20fails%20in%20staging.md)
- See also: [Cypress tests can't reach Poste.io directly in staging](Cypress%20tests%20cant%20reach%20Poste.io%20directly.md)
