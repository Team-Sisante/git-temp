# Google OAuth Flow Testing with Playwright – Gherkin/Cucumber Edition

This guide explains how to set up and use **Playwright** together with **Gherkin/Cucumber** to automate the full Google OAuth sign‑up flow – from clicking "Continue with Google" to returning to your application – without the `load` event hangs that occur in Cypress’s `cy.origin()`.  
All examples use `.feature` files and step definitions, so you can reuse the same BDD style you already use in Cypress.

Playwright is a free, open‑source browser automation framework from Microsoft. It supports Chromium, Firefox, and WebKit, and handles cross‑origin redirects and SPA pages reliably.  
**Cucumber** provides the human‑readable Gherkin syntax and test runner.

---

## 1. Why Playwright + Cucumber for Google OAuth

- **No cross‑origin `load` event problems** – Playwright navigates pages natively, not through an iframe proxy. It waits for the page to be ready (network idle, visible elements) but never hangs indefinitely like Cypress’s `cy.origin()` when Google’s SPA doesn’t fire a `load` event.
- **Built‑in auto‑waiting** – commands automatically wait for elements to be actionable, reducing flakiness.
- **Full browser control** – you can follow the entire OAuth redirect chain: your app → Google account chooser → consent screen → your app callback.
- **BDD syntax** – Gherkin files keep the test readable and maintainable.
- **Free and open‑source** – no license fees, works on your own infrastructure.

---

## 2. Prerequisites

- **Node.js** 16 or later
- Your Django application running with HTTPS (e.g. `https://localhost:8000`)
- A Google account added as a **Test User** in your Google Cloud Console OAuth consent screen
- The account already signed into the Chrome profile you will use, or you can sign in during the test

---

## 3. Installation

```bash
npm init -y
npm install -D @cucumber/cucumber playwright
npx playwright install chromium
```

---

## 4. Project Structure

```
project-root/
├── features/
│   ├── google-signup.feature
│   ├── step_definitions/
│   │   └── google-signup.steps.js
│   └── support/
│       └── hooks.js            # shared Before/After/BeforeAll/AfterAll hooks
├── cucumber.cjs                # Cucumber config
├── videos/                     # recorded test videos (auto‑created)
└── chrome-profile/             # persistent browser profile (auto‑created)
```

---

## 5. Configuration

Create `cucumber.cjs` in the project root:

```javascript
module.exports = {
  default: {
    require: ['features/step_definitions/**/*.js', 'features/support/**/*.js'],
    format: ['progress-bar', 'html:reports/cucumber-report.html'],
    parallel: 0,
    timeout: 120000,
  },
};
```

---

## 6. Feature File

`features/google-signup.feature` – this is almost identical to your existing Cypress Gherkin.

```gherkin
Feature: Demo – Social Login with Profile Completion & Booking
  As a presenter
  I want to show real user interactions with social login and booking
  So that I can record a realistic demo video

  Background:
    Given the Django database is reset
    And the Poste.io database is reset
    And the social media apps are configured
    And I set up Poste.io and log in

  Scenario: Sign up with Google, complete profile, and book a court
    When I visit the login page for the demo
    And I click the Google signup button
    Then I should be redirected to the Google consent screen
    When I click the first Google account
    Then I should see the profile completion page
    When I complete my profile with:
      | name    | John Demo       |
      | phone   | 09171234567     |
      | address | 123 Demo Street |
    And I submit the profile form
    Then I should be redirected to the dashboard
    And I should see a welcome message
    When I navigate to the booking creation page
    And I select a court and time slot
    And I submit the booking form
    Then I should see the booking confirmation
```

---

## 7. Shared Hooks (Replaces Repetitive `Before`/`After`)

Instead of putting browser launch and video recording in every step file, define them **once** in `features/support/hooks.js`.  
This file is automatically loaded by Cucumber because it's in the `support` folder.

```javascript
// features/support/hooks.js
const { Before, After, BeforeAll, AfterAll } = require('@cucumber/cucumber');
const { chromium } = require('playwright');

let browser, page;

BeforeAll(async () => {
  // Runs ONCE before any scenario.
  // You can perform global setup here (e.g. reset databases, check services).
  console.log('BeforeAll – global setup');
});

Before(async function () {
  // Runs BEFORE EVERY scenario.
  browser = await chromium.launchPersistentContext('C:\\cypress-chrome-profile', {
    headless: false,
    ignoreHTTPSErrors: true,
    recordVideo: {
      dir: 'videos/',
      size: { width: 1280, height: 720 },
    },
    args: [
      '--disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure',
    ],
  });
  page = await browser.newPage();
  page.setDefaultTimeout(30000);

  // Make browser and page available to step definitions via `this`.
  this.browser = browser;
  this.page = page;
});

After(async function () {
  // Runs AFTER EVERY scenario.
  await browser.close();
});

AfterAll(async () => {
  // Runs ONCE after all scenarios.
  // Post‑process videos (same cropping as Cypress)
  const { execSync } = require('child_process');
  const path = require('path');
  const fs = require('fs');
  const videosFolder = path.resolve('videos');
  if (!fs.existsSync(videosFolder)) return;

  fs.readdirSync(videosFolder).forEach(file => {
    if (file.endsWith('.webm')) {
      const inputPath = path.join(videosFolder, file);
      const outputFile = `presentation_${file.replace('.webm', '.mp4')}`;
      const outputPath = path.join(videosFolder, outputFile);
      try {
        execSync(
          `ffmpeg -i "${inputPath}" -filter:v "crop=1280:720:400:0" -y "${outputPath}"`,
          { stdio: 'inherit' }
        );
        console.log(`✅ Presentation video created: ${outputPath}`);
      } catch (error) {
        console.error(`Error processing ${file}:`, error.message);
      }
    }
  });
});
```

**Now, all your step definitions can simply use `this.page` and `this.browser` without ever worrying about browser launch or video recording.**  
*(Make sure to use regular `function` syntax in step definitions, not arrow functions, so that `this` refers to Cucumber’s world object.)*

---

## 8. Step Definitions (No More Hooks)

`features/step_definitions/google-signup.steps.js`

```javascript
const { Given, When, Then } = require('@cucumber/cucumber');

// ---- Background steps (database, Posteio, social apps) ----
Given('the Django database is reset', async function () {
  await this.page.request.post('https://localhost:8000/api/test/reset-django-db/');
});

Given('the Poste.io database is reset', async function () {
  console.log('Poste.io database reset – implement if needed');
});

Given('the social media apps are configured', async function () {
  console.log('Social apps configured – run manage.py setup_social_apps');
});

Given('I set up Poste.io and log in', async function () {
  console.log('Poste.io setup – implement if needed');
});

// ---- Step 1: Visit login page and click Google signup ----
When('I visit the login page for the demo', async function () {
  await this.page.goto('https://localhost:8000/accounts/login/');
  await this.page.waitForSelector('text=Sign In', { timeout: 10000 });
});

When('I click the Google signup button', async function () {
  await this.page.click('a[href*="google"]');
});

Then('I should be redirected to the Google consent screen', async function () {
  await this.page.waitForSelector('div[role="link"][data-identifier]', { timeout: 15000 });
});

// ---- Step 2: Click the first Google account ----
When('I click the first Google account', async function () {
  await this.page.click('div[role="link"][data-identifier]:first-of-type');

  // Handle consent screen if it pops up
  try {
    await this.page.waitForSelector('button:has-text("Continue")', { timeout: 5000 });
    await this.page.click('button:has-text("Continue")');
    console.log('Consent granted');
  } catch (e) {
    console.log('No consent screen (already authorised)');
  }

  await this.page.waitForURL('**/localhost:8000/**', { timeout: 60000 });
});

// ---- Step 3: Profile completion ----
Then('I should see the profile completion page', async function () {
  await this.page.waitForSelector('text=Complete Your Profile', { timeout: 10000 });
});

When('I complete my profile with:', async function (dataTable) {
  const data = dataTable.rowsHash();
  await this.page.fill('#id_name', data.name);
  await this.page.fill('#id_phone', data.phone);
  await this.page.fill('#id_address', data.address);
});

When('I submit the profile form', async function () {
  await this.page.click('button[type="submit"]');
});

// ---- Step 4: Dashboard ----
Then('I should be redirected to the dashboard', async function () {
  await this.page.waitForURL('**/dashboard/');
});

Then('I should see a welcome message', async function () {
  await this.page.waitForSelector('text=Welcome', { timeout: 10000 });
});

// ---- Step 5: Booking ----
When('I navigate to the booking creation page', async function () {
  await this.page.goto('https://localhost:8000/bookings/create/');
});

When('I select a court and time slot', async function () {
  await this.page.selectOption('#id_court', { index: 1 });
  await this.page.fill('#id_date', '2026-07-01');
  await this.page.selectOption('#id_time_slot', '08:00');
});

When('I submit the booking form', async function () {
  await this.page.click('button[type="submit"]');
});

Then('I should see the booking confirmation', async function () {
  await this.page.waitForSelector('text=Booking confirmed', { timeout: 10000 });
});
```

**Note:**  
- The `page.request.post` method (for API calls) requires Playwright ≥ 1.30. Alternatively, you can use Node’s `fetch` or your own API helper.
- Background steps like database reset and Poste.io setup can be implemented as shell commands or HTTP requests – choose what fits your environment.

---

## 9. Using `@playwright/test` (Alternative to Cucumber)

If you prefer Playwright’s own test runner with its interactive UI (comparable to `npx cypress open`), you can write tests in plain JavaScript/TypeScript without Gherkin.  
**Important:** Playwright’s built‑in runner does **not** understand `.feature` files; it only works with `*.spec.js`/`*.spec.ts`. To keep using Gherkin, you must use `npx cucumber-js`. The `--ui` mode is exclusive to Playwright’s own test syntax.

### 9.1 Installation

```bash
npm install -D @playwright/test
```

### 9.2 Example Test

Create `tests/google-signup.spec.js`:

```javascript
const { test, expect } = require('@playwright/test');
const path = require('path');

test.use({
  ignoreHTTPSErrors: true,
  launchOptions: {
    args: [
      '--disable-features=SameSiteByDefaultCookies,CookiesWithoutSameSiteMustBeSecure',
    ],
  },
});

test('Google OAuth sign‑up', async ({ page }) => {
  // Navigate to the login page
  await page.goto('https://localhost:8000/accounts/login/');
  await page.waitForSelector('text=Sign In', { timeout: 10000 });

  // Click the Google button
  await page.click('a[href*="google"]');

  // Account chooser (may appear or be skipped if session is active)
  try {
    await page.waitForSelector('div[role="link"][data-identifier]', { timeout: 10000 });
    await page.click('div[role="link"][data-identifier]:first-of-type');
    console.log('First account clicked');
  } catch (e) {
    console.log('Account chooser skipped');
  }

  // Consent screen (if needed)
  try {
    await page.waitForSelector('button:has-text("Continue")', { timeout: 5000 });
    await page.click('button:has-text("Continue")');
    console.log('Consent granted');
  } catch (e) {
    console.log('No consent screen');
  }

  // Wait for the app to load after OAuth callback
  await page.waitForURL('**/localhost:8000/**', { timeout: 60000 });

  // Profile completion
  await page.waitForSelector('text=Complete Your Profile', { timeout: 10000 });
  await page.fill('#id_name', 'John Demo');
  await page.fill('#id_phone', '09171234567');
  await page.fill('#id_address', '123 Demo Street');
  await page.click('button[type="submit"]');

  // Dashboard
  await page.waitForURL('**/dashboard/');
  await page.waitForSelector('text=Welcome', { timeout: 10000 });

  // Booking
  await page.goto('https://localhost:8000/bookings/create/');
  await page.selectOption('#id_court', { index: 1 });
  await page.fill('#id_date', '2026-07-01');
  await page.selectOption('#id_time_slot', '08:00');
  await page.click('button[type="submit"]');
  await page.waitForSelector('text=Booking confirmed', { timeout: 10000 });
});
```

### 9.3 Running with Playwright Runner

```bash
npx playwright test --headed
```

To use the **interactive UI** (similar to `npx cypress open`):

```bash
npx playwright test --ui
```

You can also specify a single test file:

```bash
npx playwright test tests/google-signup.spec.js --headed
```

### 9.4 Important: Deleting `playwright.config.js`

If you see an error like `Cannot find module '@playwright/test'` when running `npx playwright test --ui` despite having installed `@playwright/test`, check for a `playwright.config.js` in your project root. This file may still reference the `playwright` package instead of `@playwright/test`.  
Delete or rename that file to fix the error:

```bash
mv playwright.config.js playwright.config.bak
```

The Playwright test runner will then look for its configuration in `playwright.config.js` with the correct package.

---

## 10. Running Cucumber Features (CLI)

Since you are using Cucumber, not Playwright’s own test runner, you run your Gherkin scenarios with `npx cucumber-js`. Below are the most common commands.

| Action | Command |
|--------|---------|
| Run all feature files | `npx cucumber-js` |
| Run a single feature file | `npx cucumber-js features/google-signup.feature` |
| Run multiple feature files | `npx cucumber-js features/file1.feature features/file2.feature` |
| Run a specific scenario by line number | `npx cucumber-js features/google-signup.feature:12` |
| Run only scenarios with a certain tag (e.g. `@smoke`) | `npx cucumber-js --tags @smoke` |
| List all scenarios without executing (dry‑run) | `npx cucumber-js --dry-run` |
| Run scenarios in parallel (e.g. 2 workers) | `npx cucumber-js --parallel 2` |
| Show a progress bar instead of detailed output | `npx cucumber-js --format progress-bar` |
| Generate an HTML report | `npx cucumber-js --format html:reports/report.html` |

All these commands respect your `cucumber.cjs` configuration and the shared hooks in `features/support/hooks.js`.  
The `--ui` flag (`npx playwright test --ui`) does **not** work with Gherkin files; it is only for Playwright’s own test syntax (`.spec.js`). For a visual interactive experience, keep `headless: false` in the hooks – a browser window will open and you can watch the test run.

---

## 11. Video Recording and Post‑Processing (Mimicking Cypress)

The shared hooks file (`features/support/hooks.js`) already records videos and post‑processes them with `ffmpeg` after all scenarios finish. This exactly mirrors the behaviour in your `cypress.config.js`.

If you use `@playwright/test`, you can configure video recording in `playwright.config.js` and add a `global-teardown.js` for the cropping step (see the hooks example for the same ffmpeg logic).

---

## 12. Handling Self‑Signed Certificates

- `ignoreHTTPSErrors: true` is already set in the browser context.
- Alternatively, set the environment variable `NODE_EXTRA_CA_CERTS` to your CA bundle file.

---

## 13. Using a Persistent Session & Chrome Profiles

The script uses `chromium.launchPersistentContext` with a `userDataDir`. This creates a real Chrome profile directory that stores cookies, local storage, and extensions. By reusing the same profile, you avoid having to sign in manually every time.

### 13.1 Default Profile Location

In the example, the profile is stored in `./chrome-profile` (relative to the project root). This is a **separate** profile from the one Cypress uses. To avoid having two separate profiles, you can point Playwright directly at your existing Cypress profile:

```javascript
browser = await chromium.launchPersistentContext(
  'C:\\cypress-chrome-profile',  // ← same profile Cypress uses
  { ... }
);
```

### 13.2 Important Rules When Sharing a Profile

- **Close all Chrome/Cypress windows** before running Playwright – the profile is locked if another process is using it.
- The Cypress profile (`C:\cypress-chrome-profile`) is created and seeded by your **menu option 16.3**. Once you run that, the profile contains a valid Google session and a pre‑approved app. Playwright can then pick it up directly.
- If you want to keep the profiles separate (e.g., for different test suites), keep the relative path `./chrome-profile` and manually sign into Google once before running tests.

### 13.3 Forcing the Account Chooser to Appear Every Time

If you want the account chooser to appear in every test run (instead of Google silently redirecting), **delete the profile folder before each test** or use a non‑persistent context:

```javascript
const browser = await chromium.launch();   // no userDataDir
```

But be aware that you will need to sign in from scratch each time.

---

## 14. Tips for Reliability

- **Pre‑authorise the app** – run the flow once manually in the same browser profile. After that, consent is remembered, and the test will never hang on the consent screen.
- **Increase timeouts** – Google’s servers can be slow; a 60‑second timeout for the redirect is reasonable.
- **Use stable selectors** – prefer `data-identifier` and `role="link"` over class names that Google may change.
- **Run Playwright alongside Cypress** – keep Cypress for your existing suite, and use Playwright only for the OAuth flow.

---

## 15. Troubleshooting

| Problem | Solution |
|---------|----------|
| `ERR_CERT_AUTHORITY_INVALID` | Set `ignoreHTTPSErrors: true` or add the cert to the trusted store. |
| Timeout waiting for account chooser | Check that the Chrome profile has a valid Google session (sign in manually first). |
| Consent screen never appears | That’s okay – Google skips it if the app was already authorised. |
| After consent, still on Google page | Ensure the `redirect_uri` in your Google Cloud Console matches exactly the callback URL your app uses (`https://localhost:8000/accounts/google/login/callback/`). |
| Playwright cannot find elements | Run in headed mode to see what’s happening. Google may show a different UI if no session exists. |
| `Cannot find module '@playwright/test'` when using `npx playwright test --ui` | Delete or rename `playwright.config.js` (if present) – it may be conflicting with the correct package. |

---

## Conclusion

Playwright with Gherkin/Cucumber provides a clean, reliable way to automate the full Google OAuth UI flow. You can record a realistic demo or run end‑to‑end tests without the cross‑origin limitations of Cypress’s `cy.origin()`.  
For the rest of your test suite (profile completion, booking, Poste.io), you can continue using Cypress – the two tools complement each other perfectly.