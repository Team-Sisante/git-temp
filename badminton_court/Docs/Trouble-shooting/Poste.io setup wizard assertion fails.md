# Poste.io setup wizard assertion fails
## Source: Docs/Trouble-shooting/Poste.io setup wizard assertion fails.md

## Troubleshooting Poste.io setup wizard assertion failures

### Symptom
The `cy.setupPosteio()` command fails after submitting the setup wizard:

```
AssertionError
Timed out retrying after 5000ms: expected 'https://localhost:8443/admin/login' to include '/admin/box/'
cypress/support/commands/setupPosteio.cy.js:48
```

The setup wizard completed (form submitted, redirected to `/admin/login`), but the assertion expected `/admin/box/`.

### Root Cause
Different Poste.io versions behave differently after the setup wizard completes:

| Poste.io version | After setup submit, redirects to... |
|------------------|-------------------------------------|
| Older versions | `/admin/box/` (auto-logs in the admin) |
| Newer versions | `/admin/login` (requires explicit login) |

The assertion `cy.url().should('include', '/admin/box/')` was too strict — it only accepted the older behavior.

### Diagnostic Steps

1. **Check the Cypress log** — look for the URL after the setup form submits:
   ```
   (new url)https://localhost:8443/admin/login
   ```
   If it's `/admin/login`, the setup succeeded but the assertion is too strict.

2. **Manually complete the setup wizard** to see where Poste.io redirects:
   - Visit `https://localhost:8443/`
   - Fill out the setup form
   - Submit
   - Note the URL you land on

3. **Check the setup wizard completion** — if you see the admin login page, setup succeeded. If you see an error, setup failed.

### Fix

#### Step 1: Relax the assertion

In `cypress/support/commands/setupPosteio.cy.js`, find `performSetup`:

```javascript
function performSetup(apiHost, adminEmail, adminPassword) {
    const hostname = new URL(apiHost).hostname;

    cy.get('#install_hostname').clear().typeWithHighlight(hostname);
    cy.get('#install_superAdmin').clear().typeWithHighlight(adminEmail);
    cy.get('#install_superAdminPassword').clear().typeWithHighlight(adminPassword);
    cy.get('button[type="submit"]', {timeout: 10000}).clickWithHighlight();
    
    cy.wait(5000);
    cy.url().should('include', '/admin/box/');     // ← TOO STRICT
    cy.log('Setup complete. Navigating to admin login...');
    cy.visit(`${apiHost}/admin/login`);
    performLogin(adminEmail, adminPassword);
}
```

Replace the assertion:

```javascript
function performSetup(apiHost, adminEmail, adminPassword) {
    const hostname = new URL(apiHost).hostname;

    cy.get('#install_hostname').clear().typeWithHighlight(hostname);
    cy.get('#install_superAdmin').clear().typeWithHighlight(adminEmail);
    cy.get('#install_superAdminPassword').clear().typeWithHighlight(adminPassword);
    cy.get('button[type="submit"]', {timeout: 10000}).clickWithHighlight();
    
    cy.wait(15000);  // ← Increased from 5000 — Poste.io needs time to start mail services
    // After setup, Poste.io either:
    //   - Auto-logs us in and redirects to /admin/box/ (older versions)
    //   - Redirects to /admin/login (newer versions require explicit login)
    cy.url().should('include', '/admin/').should('not.include', '/install/');
    cy.log('Setup complete. Navigating to admin login...');
    cy.visit(`${apiHost}/admin/login`);
    performLogin(adminEmail, adminPassword);
}
```

**Key changes:**
1. `cy.url().should('include', '/admin/box/')` → `cy.url().should('include', '/admin/').should('not.include', '/install/')`
   - ✅ Accepts `/admin/box/` (auto-logged-in)
   - ✅ Accepts `/admin/login` (need to log in manually)
   - ❌ Rejects `/admin/install/server` (setup didn't complete)
2. `cy.wait(5000)` → `cy.wait(15000)` — Poste.io needs more time to start mail services after setup

#### Step 2: (Optional) Suppress JSON parse warnings

The setup wizard makes AJAX calls that return HTML instead of JSON (a Poste.io bug). These are harmless but noisy. In `cypress/support/e2e.js`:

```javascript
Cypress.on('uncaught:exception', (err, runnable) => {
  // Existing suppressions
  if (err.message.includes("Cannot read properties of null (reading 'addEventListener')")) {
    return false;
  }
  if (err.message.includes('is not valid JSON')) {
    return false;
  }
  // Add this for Poste.io setup wizard AJAX errors
  if (err.message.includes("Unexpected token '<'")) {
    return false;
  }
  return true;
});
```

### Why Poste.io Redirects to `/admin/login`

After the setup wizard completes:
1. Poste.io creates the admin account
2. Poste.io starts all mail services (postfix, dovecot, etc.)
3. Poste.io invalidates the setup session
4. Poste.io redirects to `/admin/login` for security (admin must explicitly log in)

The next line in `performSetup` (`cy.visit('/admin/login')` + `performLogin`) handles this correctly — the assertion was the only problem.

### Verification

After the fix:
1. Run the test that calls `Given I set up Poste.io and log in`
2. The setup wizard should complete
3. The assertion should pass (because the URL includes `/admin/` and doesn't include `/install/`)
4. The login should succeed
5. The test should proceed

### Related Files
- `badminton_court/cypress/support/commands/setupPosteio.cy.js` — the `performSetup` function
- `badminton_court/cypress/support/e2e.js` — uncaught exception suppression
- See also: [Poste.io SMTP auth fails after fresh volume reset](Poste.io%20SMTP%20auth%20fails%20after%20fresh%20volume%20reset.md)
