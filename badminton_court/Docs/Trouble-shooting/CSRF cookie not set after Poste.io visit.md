# CSRF cookie not set after Poste.io visit
## Source: Docs/Trouble-shooting/CSRF cookie not set after Poste.io visit.md

## Troubleshooting CSRF cookie not set errors after visiting Poste.io

### Symptom
The Cypress signup test fails with:
```
Forbidden (403)
CSRF verification failed. Request aborted.
Reason given for failure: CSRF cookie not set.
```

The test visits the signup page, fills in the form, and submits — but Django rejects the POST because no CSRF cookie was sent.

### Root Cause
The test's Background includes `Given I set up Poste.io and log in`, which calls `cy.visit('https://localhost:8443/')` (the Poste.io admin). This leaves the Cypress browser context on the Poste.io domain.

When the test then visits `/accounts/signup/` (relative URL), the browser:
1. Navigates to `http://localhost:8000/accounts/signup/` ✅ (correct URL)
2. But the cookies are still from the Poste.io domain (`roundcube_sessid`, `PHPSESSID`)
3. The Django CSRF cookie (`csrftoken`) is NOT set
4. When the form submits, Django rejects it with "CSRF cookie not set"

### Diagnostic Steps

1. **Check cookies after visiting the signup page:**
   ```javascript
   // In signUp.cy.js, after cy.visit('/accounts/signup/'):
   cy.getCookies().then((cookies) => {
       cy.log('Cookies after visit:', JSON.stringify(cookies.map(c => c.name)));
   });
   ```
   If you see `["roundcube_sessid","PHPSESSID"]` (Poste.io cookies) instead of `["csrftoken","sessionid"]` (Django cookies), the browser context is wrong.

2. **Check the test's Background** — if it includes `Given I set up Poste.io and log in`, that step visits Poste.io and leaves the browser on that domain.

3. **Verify the signup page URL** — if it's correct (`http://localhost:8000/accounts/signup/`) but cookies are wrong, the issue is cookie domain scoping.

### Fix

#### Step 1: Clear cookies before visiting the signup page

In `cypress/support/commands/signUp.cy.js`, add `cy.clearCookies()` before visiting the signup page:

```javascript
Cypress.Commands.add('signUp', (options = {}) => {
    const uniqueEmail = Cypress.env('REGULARUSER_EMAIL');
    const password = Cypress.env('REGULARUSER_PASSWORD');

    cy.log(`Signing up with email: ${uniqueEmail}`);

    // Clear cookies from previous domain (e.g., Poste.io admin)
    // to ensure Django's CSRF cookie is set fresh
    cy.clearCookies();

    // Visit signup page and fill the registration form
    cy.visit('/accounts/signup/');
    // ...
});
```

#### Step 2: Ensure the CSRF cookie is set before form submission

After `cy.visit('/accounts/signup/')`, the Django page should set the CSRF cookie automatically (via the `{% csrf_token %}` template tag). But to be safe, you can explicitly fetch it:

```javascript
    cy.visit('/accounts/signup/');

    // Ensure CSRF cookie is set before submitting the form
    cy.request({
        method: 'GET',
        url: '/api/test-csrf-cookie/',
        failOnStatusCode: false
    }).then((resp) => {
        cy.log('CSRF cookie fetched');
    });

    cy.get('#id_email').typeWithHighlight(uniqueEmail);
    // ...
```

**Note:** `cy.request()` uses a separate cookie jar from the browser context. This alone may not set the cookie in the browser. The `cy.clearCookies()` + `cy.visit()` approach is more reliable.

#### Step 3: Alternative — visit an absolute URL

If clearing cookies doesn't help, visit the signup page with an absolute URL to force the browser context:

```javascript
    const baseUrl = Cypress.config('baseUrl');
    cy.visit(`${baseUrl}/accounts/signup/`);
```

This ensures the browser navigates to the Django app, not a relative URL that might inherit the Poste.io context.

### Why This Happens

Cypress maintains a single browser session across all `cy.visit()` calls. When you visit Poste.io (`https://localhost:8443/`), the browser:
1. Loads the Poste.io page
2. Poste.io sets cookies (`PHPSESSID`, `roundcube_sessid`) for the `localhost:8443` domain
3. The browser's "current domain" becomes `localhost:8443`

When you then visit `/accounts/signup/` (relative):
1. Cypress resolves this against `baseUrl` (`http://localhost:8000`)
2. The browser navigates to `http://localhost:8000/accounts/signup/`
3. Django serves the page and tries to set a CSRF cookie for `localhost:8000`
4. But the browser's cookie jar may not immediately apply the new cookie
5. When the form submits, the CSRF cookie isn't sent

Clearing cookies before the visit forces a clean cookie jar, so Django's CSRF cookie is the only one present.

### Verification

```javascript
// In signUp.cy.js, after the fix:
cy.clearCookies();
cy.visit('/accounts/signup/');

cy.getCookies().then((cookies) => {
    cy.log('Cookies after visit:', JSON.stringify(cookies.map(c => c.name)));
    // Should now include "csrftoken"
});
```

### Related Files
- `badminton_court/cypress/support/commands/signUp.cy.js` — the signup command
- `badminton_court/cypress/support/commands/setupPosteio.cy.js` — the Poste.io setup (causes the cookie issue)
- `badminton_court/cypress/support/e2e.js` — `cy.request` overwrite (may need to handle absolute URLs)
