# June 2026 Fixes & Improvements
## Source: Docs/Trouble-shooting/June 2026 Fixes.md

**Status:** Completed (June 25, 2026)

This document summarises several small but important fixes completed in late June.

### 72. Social Media App Configuration Menu
- Added menu option 16.2 (“Setup Social Media DB Records”) to create/update `SocialApp` entries for Google, Facebook, Twitter.
- Works idempotently for both staging and production.

### 73. Database Permission Repair Automation
- Menu options 11.1 (staging) and 14.1 (production) now load the complete environment from local `.env.common` and `.env.production`, fix volume ownership, and restart containers securely.

### 74. Load Balancer Health Check Host Headers
- `setup-load-balancer.js` now automatically includes the `--host` flag when creating/updating health checks, preventing `DisallowedHost` errors from Django.

### 75. Deployment Script Image Tag Reliability
- `deploy.js` discovers the latest SHA‑tag from GHCR if no `IMAGE_TAG` is provided, and explicitly stops/removes the old web container before `docker compose up` to guarantee the correct image is used.

### 76. SMTP Check Timeout Fix
- `test_check_smtp_auth` view now uses a short (5‑second) timeout in staging/production, preserving the original 30‑second timeout in development.

### 77. Cypress Environment Variable Resolution
- Cypress config now loads the full base env file (`.env.production` or `.env.staging`) when a `.env.test.*` file is selected, ensuring all required variables like `REGULARUSER_EMAIL` are available.

### 78. /court Path Routing Correction
- Removed the explicit `path('court/', include(...))` from the project URLconf; now uses `FORCE_SCRIPT_NAME='/court'` (set from `DOMAIN_PREFIX`) to strip the prefix internally.

### 79. User Profile Completion Notice
- Added a notification before booking when the profile is incomplete, improving the demo flow.

### 80. Troubleshooting Documentation
- Created `Docs/Trouble-shooting/Revert to a specific commit state.md` and `Docs/Trouble-shooting/Restoring files from previous commit.md`.
- All documentation is linked from the central `git-temp/Memory.md`.

### Related Files
- `badminton_court/Scripts/options/option_16_2.js`
- `badminton_court/Scripts/options/option_11_1.js`, `option_14_1.js`
- `gocd-server/Scripts/setup-load-balancer.js`
- `gocd-server/Scripts/deploy.js`
- `badminton_court/court_management/components/views/test_check_smtp_auth.py`
- `badminton_court/cypress.config.js`
- `badminton_court/badminton_court/urls.py`
- `badminton_court/templates/...`