# Memory Detail: Poste.io Setup Wizard Fails in Development Environment

## Environment
**Development Environment Only** — This issue was diagnosed and fixed in the local development environment (Windows host, Docker Desktop, Git Bash). Staging/production were not affected. After this fix is merged via PR, the artifacts and staging pipelines will be triggered to verify staging.

## Issue Summary
The Poste.io setup wizard (cy.setupPosteio()) failed to complete during Cypress tests in the dev environment. After submitting the first install form, Poste.io stayed on /admin/install/server instead of progressing to the admin dashboard. This caused all downstream tests (posteio-flow.feature, auth-flow.feature) to fail because the admin account was never properly created.

## Root Causes (Multiple, Cascading)

### 1. Volume Not Properly Removed (Docker Desktop Windows)
- cy.resetPosteioDb() ran docker-compose down mail-test followed by docker volume rm.
- On Docker Desktop for Windows, the volume lock is sometimes held even after the container stops.
- The docker volume rm failed silently (failOnNonZeroExit: false), so old corrupted data persisted.

### 2. Stale Browser Session/Cookies
- Previous setup attempts left session cookies in the Cypress browser.
- When cy.setupPosteio() visited Poste.io again, the stale cookies caused the setup wizard to fail silently.

### 3. Multi-Step Install Wizard Not Handled
- Poste.io's setup wizard has MULTIPLE steps (not just one form).
- The old performSetup function only submitted the FIRST form, then expected to be on /admin/box/.

### 4. Excessive Wait Causing Socket Timeout
- A cy.wait(30000) was added to setupPosteio before cy.visit().
- This 30-second wait caused ESOCKETTIMEDOUT.

### 5. SMTP Auth Timeout in Django Endpoint
- The test_check_smtp_auth.py view used timeout=10 for SMTP connections.
- Poste.io's SSL handshake on port 465 can take 15-25 seconds.

## Resolution

### Fix 1: database.cy.js — resetPosteioDb
- Replaced docker-compose down with docker rm -f + docker volume rm -f.
- Added verification: checks if volume is actually gone, retries up to 10 times.
- Added verification: checks if /data is empty after container starts.
- Added dynamic polling: polls Poste.io HTTPS endpoint every 2s (up to 60s).

### Fix 2: setupPosteio.cy.js — setupPosteio command
- Added cy.clearCookies(), cy.clearLocalStorage(), cy.clearAllSessionStorage() BEFORE cy.visit(apiHost).
- Removed the cy.wait(30000) that caused ESOCKETTIMEDOUT.

### Fix 3: setupPosteio.cy.js — performSetup function
- Replaced single-form submission with a step-through loop.
- After submitting the first install form, checks if still on /admin/install/.
- If yes, clicks any visible submit button again (handles multi-step wizard).
- Repeats until no longer on an install page.
- Changed cy.wait(5000) to cy.wait(10000) after first submit.

### Fix 4: test_check_smtp_auth.py — Django endpoint
- Increased timeout=10 to timeout=30 for all SMTP connections.
- Added socket.setdefaulttimeout(30) before each connection.
- Added retry logic: retries up to 3 times with 10s delay.
- Reset socket.setdefaulttimeout(None) after each attempt.

## Files Modified
- cypress/support/commands/database.cy.js
- cypress/support/commands/setupPosteio.cy.js
- court_management/components/views/test_check_smtp_auth.py

## Key Lesson
Poste.io's setup wizard is a multi-step process that requires:
1. A truly fresh volume (verified, not assumed)
2. Clean browser state (no stale cookies)
3. Handling of multiple install screens (not just the first one)
4. Adequate timeouts for SSL handshake and auth plugin warmup

## Status
- **Dev Environment:** Fixed and verified
- **Staging:** Pending — PR will be created, artifacts + staging pipelines triggered
- **Production:** Pending — After staging verification

## Commit Reference
- Working commit: 62f7acb (Fix posteio-flow.feature)
- Additional fixes: volume removal verification, SMTP timeout/retry, polling loop