# Google OAuth Flow Testing with Playwright

This guide explains how to set up and use **Playwright** to automate the full Google OAuth sign‑up flow – from clicking "Continue with Google" to returning to your application – without the `load` event hangs that occur in Cypress’s `cy.origin()`.

Playwright is a free, open‑source browser automation framework from Microsoft. It supports Chromium, Firefox, and WebKit, and handles cross‑origin redirects and SPA pages reliably. It is the recommended tool when you need a true end‑to‑end UI test of third‑party authentication.

---

## 1. Why Playwright for Google OAuth

- **No cross‑origin `load` event problems** – Playwright navigates pages natively, not through an iframe proxy. It waits for the page to be ready (network idle, visible elements) but never hangs indefinitely like Cypress’s `cy.origin()` when Google’s SPA doesn’t fire a `load` event.
- **Built‑in auto‑waiting** – commands automatically wait for elements to be actionable, reducing flakiness.
- **Full browser control** – you can follow the entire OAuth redirect chain: your app → Google account chooser → consent screen → your app callback.
- **Free and open‑source** – no license fees, works on your own infrastructure.

---

## 2. Prerequisites

- **Node.js** 16 or later (Playwright requires Node 14+)
- Your Django application running with HTTPS (e.g. `https://localhost:8000`)
- A Google account added as a **Test User** in your Google Cloud Console OAuth consent screen (so that Google does not show the “unverified app” warning)
- The account already signed into the Chrome profile you will use, or you can sign in during the test (instructions below)

---

## 3. Installation

In your project’s root directory (or a dedicated `e2e` folder), install Playwright:

```bash
npm init -y                   # if you don't have a package.json
npm install -D playwright     # install the framework
npx playwright install        # download browser binaries (Chromium, Firefox, WebKit)
```

If you only need Chromium, you can install just that:

```bash
npx playwright install chromium
```

---

## 4. Basic Configuration (optional)

Create a `playwright.config.ts` (or `.js`) to store shared settings:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 120000,          // 2 minutes per test – generous for OAuth
  expect: { timeout: 10000 },
  use: {
    baseURL: 'https://localhost:8000',
    ignoreHTTPSErrors: true, // for self‑signed certificates
    headless: false,         // set to true for headless runs
    video: 'on',             // record video of the test
    screenshot: 'on',        // take screenshots on failure
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

For a quick script without the test runner, you can also use a plain `.js` file. This guide shows the plain script approach.

---

## 5. Writing the Google OAuth Test Script

Create a file `google-signup.js` (or `google-signup.spec.ts` if using the test runner). The script will:

1. Launch a persistent Chromium context (so that cookies and sessions are preserved).
2. Navigate to your application’s login page.
3. Click the “Continue with Google” button.
4. Wait for the Google account chooser to appear.
5. Click the first listed account.
6. Handle the consent screen if it appears (click “Continue”).
7. Wait for the redirect back to your app.
8. Verify that the user is logged in (e.g. profile completion page or dashboard).

### 5.1 Full Script (plain Node.js)

```javascript
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  // Launch browser with a persistent context – saves session data
  const userDataDir = path.join(__dirname, 'chrome-profile');
  const browser = await chromium.launchPersistentContext(userDataDir, {
    headless: false,
    ignoreHTTPSErrors: true,        // for self‑signed localhost certs
    args: [
      '--disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure',
    ],
  });

  const page = await browser.newPage();
  // (Optional) Set a longer timeout for all actions
  page.setDefaultTimeout(30000);

  try {
    // Step 1: Go to your login page
    await page.goto('https://localhost:8000/accounts/login/');
    console.log('Login page loaded');

    // Step 2: Click the Google button
    // Adjust selector to match your page (href contains "google")
    await page.click('a[href*="google"]');
    console.log('Google button clicked');

    // Step 3: Wait for the account chooser to appear.
    // Google’s account chooser lists accounts as elements with data-identifier.
    await page.waitForSelector('div[role="link"][data-identifier]', { timeout: 15000 });
    console.log('Account chooser visible');

    // Step 4: Click the first account
    await page.click('div[role="link"][data-identifier]:first-of-type');
    console.log('First account clicked');

    // Step 5: Handle consent screen if it pops up.
    // Consent screen may appear if the app hasn't been pre‑authorised.
    // Use a short timeout so we don't wait forever if it's already skipped.
    try {
      await page.waitForSelector('button:has-text("Continue")', { timeout: 5000 });
      await page.click('button:has-text("Continue")');
      console.log('Consent granted');
    } catch (e) {
      // No consent screen – that's fine, Google skipped it
      console.log('No consent screen (already authorised)');
    }

    // Step 6: Wait for the redirect back to your app.
    // The OAuth callback should bring us back to localhost.
    // Playwright’s default navigation wait will handle this.
    await page.waitForURL('**/localhost:8000/**', { timeout: 60000 });
    console.log('Redirected back to app');

    // Step 7: Verify logged‑in state.
    // Depending on your app, you may land on /dashboard/ or /profile/complete/
    await page.waitForSelector('text=Welcome', { timeout: 10000 });
    console.log('User is logged in');

    // Optionally fill the profile form etc.
    // ...

  } catch (err) {
    console.error('Error during sign‑up flow:', err);
  } finally {
    await browser.close();
  }
})();
```

### 5.2 Using the Test Runner (Playwright Test)

If you prefer the test runner, create a `google-auth.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test.use({
  ignoreHTTPSErrors: true,
  launchOptions: {
    args: [
      '--disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure',
    ],
  },
});

test('Google OAuth sign‑up', async ({ page }) => {
  await page.goto('/accounts/login/');
  await page.click('a[href*="google"]');
  await page.waitForSelector('div[role="link"][data-identifier]', { timeout: 15000 });
  await page.click('div[role="link"][data-identifier]:first-of-type');

  // Consent screen
  try {
    await page.waitForSelector('button:has-text("Continue")', { timeout: 5000 });
    await page.click('button:has-text("Continue")');
  } catch {}

  await page.waitForURL('**/localhost:8000/**', { timeout: 60000 });
  await expect(page.locator('text=Welcome')).toBeVisible();
});
```

Run with:
```bash
npx playwright test --headed
```

---

## 6. Handling Self‑Signed Certificates

Since you run Django on `https://localhost` with a self‑signed certificate, you must:

- Set `ignoreHTTPSErrors: true` in the browser context (as shown above).
- Or set the environment variable `NODE_EXTRA_CA_CERTS` to your CA bundle file before running Playwright, so the certificate is trusted.

---

## 7. Dealing with a Persistent Session

The script above uses `launchPersistentContext` with a `userDataDir`. This saves cookies and local storage to a real Chrome profile folder. If you log into Google once manually inside that profile, subsequent runs will skip the account chooser entirely (Google redirects straight through). That’s fine; the video will still show the button click and the redirect.

If you want the account chooser to appear every time, delete the profile folder before the test or use a fresh context without a `userDataDir`.

---

## 8. Running and Recording

### Headed mode (for recording a demo)

Set `headless: false` (in the config or launch options). A browser window will open, and you can record the screen with your preferred tool (OBS, Camtasia, etc.).

### Headless mode (for CI)

Set `headless: true`. Playwright still captures video if configured (`video: 'on'`).

To generate a video file, add the `video` option to the context:

```javascript
const context = await chromium.launchPersistentContext(userDataDir, {
  headless: false,
  ignoreHTTPSErrors: true,
  recordVideo: {
    dir: 'videos/',
    size: { width: 1280, height: 720 },
  },
});
```

After the test, the video will be saved as a `.webm` file in the `videos` folder.

---

## 9. Tips for Reliability

- **Pre‑authorise the app** – run the flow once manually in the same browser profile. After that, consent is remembered, and the test will never hang on the consent screen.
- **Increase timeouts** – Google’s servers can be slow; a 60‑second timeout for the redirect is reasonable.
- **Use stable selectors** – prefer `data-identifier` and `role="link"` over class names that Google may change.
- **Run Playwright alongside Cypress** – you don’t need to abandon Cypress. Use Playwright only for the OAuth part, and keep Cypress for the rest of your suite. You can even invoke the Playwright script from Cypress via `cy.exec()`.

---

## 10. Troubleshooting

| Problem | Solution |
|---------|----------|
| `ERR_CERT_AUTHORITY_INVALID` | Set `ignoreHTTPSErrors: true` or add the cert to the trusted store. |
| Timeout waiting for account chooser | Verify that the Google button navigated correctly. Check that the Chrome profile has a valid Google session (sign in manually first). |
| Consent screen never appears | That’s okay – Google skips it if the app was already authorised. |
| After consent, still on Google page | Ensure the `redirect_uri` in your Google Cloud Console matches exactly the callback URL your app uses (`https://localhost:8000/accounts/google/login/callback/`). |
| Playwright cannot find elements | Use `--headed` mode to see what’s happening. Google may show a different UI (e.g., email input instead of account list) if no session exists. Sign in once manually. |

---

## Conclusion

Playwright provides a clean, reliable way to automate the full Google OAuth UI flow. By using a persistent browser profile, ignoring SSL errors, and following the redirect chain, you can record a realistic demo or run end‑to‑end tests without the cross‑origin limitations of Cypress’s `cy.origin()`.

For the rest of your test suite (profile completion, booking, Poste.io), you can continue using Cypress. The two tools complement each other: Cypress for your application’s domain logic, Playwright for the third‑party authentication step.
```