# Cypress mailbox creation 404 in dev
## Source: Docs/Trouble-shooting/Cypress mailbox creation 404 in dev.md

## Troubleshooting Cypress mailbox creation 404 errors in dev

### Symptom
The `Given a regular user mailbox exists` step fails in dev with:
```
requestPOST 404 /api/domains/aeropace.com/mailboxes
```

The request URL is relative (`/api/domains/...`), but it should be absolute (`https://localhost:8443/api/domains/...`).

### Root Cause
The `cy.request` overwrite in `cypress/support/e2e.js` intercepts ALL `cy.request()` calls and may modify the URL. When the mailbox step passes an absolute URL (`https://localhost:8443/api/domains/...`), the overwrite should leave it unchanged — but if the URL construction fails (e.g., env vars are undefined), the URL becomes malformed and Cypress falls back to `baseUrl`.

The step definition:
```javascript
const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;
cy.request({
    method: 'POST',
    url: `${apiHost}/api/domains/${domain}/mailboxes`,
    // ...
});
```

If `Cypress.env('POSTE_HOSTNAME')` is undefined, then:
- `apiHost` becomes `https://undefined:undefined`
- The URL becomes `https://undefined:undefined/api/domains/aeropace.com/mailboxes`
- This is invalid, so Cypress falls back to `baseUrl` (`http://localhost:8000`)
- The request goes to `http://localhost:8000/api/domains/aeropace.com/mailboxes`
- Django returns 404 (no such URL pattern)

### Diagnostic Steps

1. **Add debug logs to the step definition:**
   ```javascript
   Given('a regular user mailbox exists', () => {
     const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;
     cy.log(`DEBUG: apiHost = ${apiHost}`);
     cy.log(`DEBUG: POSTE_PROTOCOL = ${Cypress.env('POSTE_PROTOCOL')}`);
     cy.log(`DEBUG: POSTE_HOSTNAME = ${Cypress.env('POSTE_HOSTNAME')}`);
     cy.log(`DEBUG: POSTE_PORT = ${Cypress.env('POSTE_PORT')}`);
     cy.log(`DEBUG: full URL = ${apiHost}/api/domains/${domain}/mailboxes`);
     cy.request({ /* ... */ });
   });
   ```

2. **Check the Cypress env vars are loaded:**
   ```bash
   cd badminton_court
   grep "POSTE" .env.dev
   # Should show:
   # POSTE_PROTOCOL=https
   # POSTE_HOSTNAME=localhost
   # POSTE_PORT=8443
   ```

3. **Check `cypress.config.js` env loading:**
   ```bash
   grep -A 5 "POSTE" cypress.config.js
   ```
   If the env vars aren't loaded into `config.env`, `Cypress.env('POSTE_HOSTNAME')` returns undefined.

4. **Check the `cy.request` overwrite:**
   ```bash
   grep -A 20 "Cypress.Commands.overwrite('request'" cypress/support/e2e.js
   ```
   Verify it only prefixes URLs starting with `/`, not absolute URLs.

### Fix

#### Step 1: Verify the env vars are loaded

Check `.env.dev` has the POSTE variables:
```bash
POSTE_PROTOCOL=https
POSTE_HOSTNAME=localhost
POSTE_PORT=8443
POSTE_API_USER=admin@aeropace.com
POSTE_ADMIN_PASSWORD=StrongPassword123!
```

Check `cypress.config.js` loads `.env.dev` for development:
```javascript
const environment = (process.env.ENVIRONMENT || 'development').toLowerCase();
let fallbackFile;
switch (environment) {
  case 'staging': fallbackFile = '.env.staging'; break;
  case 'production': fallbackFile = '.env.production'; break;
  case 'docker': fallbackFile = '.env.docker'; break;
  default: fallbackFile = '.env.dev';
}
```

#### Step 2: Add a debug log to verify the URL

In `cypress/support/step_definitions/common.js`:

```javascript
Given('a regular user mailbox exists', () => {
  const env = Cypress.env('ENVIRONMENT') || 'development';
  cy.log(`Environment: ${env} — dispatching to appropriate mailbox creation`);

  if (env === 'staging' || env === 'production') {
    cy.createRegularUserMailboxStaging();
    return;
  }

  // Dev mode: call Poste.io API directly
  const email = Cypress.env('REGULARUSER_EMAIL');
  const [localPart, domain] = email.split('@');
  const apiHost = `${Cypress.env('POSTE_PROTOCOL')}://${Cypress.env('POSTE_HOSTNAME')}:${Cypress.env('POSTE_PORT')}`;

  // Debug logs
  cy.log(`DEBUG: apiHost = ${apiHost}`);
  cy.log(`DEBUG: full URL = ${apiHost}/api/domains/${domain}/mailboxes`);

  cy.request({
    method: 'POST',
    url: `${apiHost}/api/domains/${domain}/mailboxes`,
    body: {
      local_part: localPart,
      password: Cypress.env('REGULARUSER_PASSWORD'),
      active: true
    },
    auth: {
      username: Cypress.env('POSTE_API_USER'),
      password: Cypress.env('POSTE_ADMIN_PASSWORD')
    },
    failOnStatusCode: false
  });
});
```

Run the test and check the Cypress logs for the DEBUG output. If `apiHost` is `https://undefined:undefined`, the env vars aren't loaded.

#### Step 3: Verify the `cy.request` overwrite doesn't mangle absolute URLs

In `cypress/support/e2e.js`:

```javascript
Cypress.Commands.overwrite('request', (originalFn, ...args) => {
  const prefix = Cypress.env('DOMAIN_PREFIX') || '';

  let options;
  if (typeof args[0] === 'object' && args[0] !== null) {
    options = { ...args[0] };
  } else if (typeof args[0] === 'string') {
    if (args[0].startsWith('/') || args[0].startsWith('http')) {
      options = { url: args[0] };
      if (args.length > 1 && typeof args[1] !== 'undefined') options.body = args[1];
    } else {
      options = { method: args[0], url: args[1] };
      if (args.length > 2) options.body = args[2];
    }
  }

  // Only prefix RELATIVE URLs (starting with /)
  if (options && options.url && options.url.startsWith('/') && prefix) {
    options.url = `${prefix}${options.url}`;
  }

  return originalFn(options);
});
```

The condition `options.url.startsWith('/')` ensures absolute URLs (starting with `http`) are NOT prefixed. But if the URL is `https://undefined:undefined/...`, it starts with `https://`, so it's not prefixed — it's just invalid, and Cypress falls back to baseUrl.

#### Step 4: If env vars are undefined, fix the env loading

If `Cypress.env('POSTE_HOSTNAME')` returns undefined, the env file isn't being loaded. Check:

1. Is `.env.dev` in the repo root?
2. Does `cypress.config.js` load it?
3. Are the variable names correct (no typos)?

```bash
# Verify the env file exists and has the vars
cat .env.dev | grep POSTE

# Verify Cypress can load it
node -e "
require('dotenv').config({ path: '.env.dev' });
console.log('POSTE_HOSTNAME:', process.env.POSTE_HOSTNAME);
"
```

### Verification

After the fix:
1. The DEBUG logs should show `apiHost = https://localhost:8443`
2. The request should go to `https://localhost:8443/api/domains/aeropace.com/mailboxes`
3. The response should be 200 or 409 (mailbox created or already exists)

### Related Files
- `badminton_court/cypress/support/step_definitions/common.js` — the mailbox step
- `badminton_court/cypress/support/e2e.js` — the `cy.request` overwrite
- `badminton_court/cypress.config.js` — env loading
- `badminton_court/.env.dev` — POSTE env vars
- See also: [Cypress tests can't reach Poste.io directly in staging](Cypress%20tests%20cant%20reach%20Poste.io%20directly.md)
