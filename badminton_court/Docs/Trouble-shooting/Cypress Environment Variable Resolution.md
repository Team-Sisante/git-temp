# Cypress Environment Variable Resolution
## Source: Docs/Trouble-shooting/Cypress Environment Variable Resolution.md

**Status:** Completed (June 25, 2026)

### Problem
When running Cypress tests against staging or production, environment variables like `REGULARUSER_EMAIL` were `undefined`. The test selected a `.env.test.*` file (e.g., `.env.test.production`), but that file didn't contain the full set of application variables – only test‑specific overrides.

### Solution
- Updated `cypress.config.js` to automatically load the corresponding **base** environment file when a `.env.test.*` file is selected.
- If the test file is `.env.test.production`, the config also loads `.env.production` and merges it (with the test file values taking precedence).
- This ensures all application variables (including `REGULARUSER_EMAIL`, `ADMIN_EMAIL`, etc.) are available in Cypress tests without duplicating them in test files.

### Related Files
- `badminton_court/cypress.config.js`