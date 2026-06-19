# Poste.io setup wizard fails to complete in dev environment
## Source: Docs/Trouble-shooting/Poste.io setup wizard fails to complete in dev.md

## Troubleshooting the Poste.io setup wizard in the development environment

> **Environment:** Development only (Windows host, Docker Desktop, Git Bash). Staging/production use a different reset path (API-based, not docker-compose).

### Symptom
The Poste.io setup wizard (cy.setupPosteio()) fails to complete during Cypress tests. After submitting the first install form, Poste.io stays on /admin/install/server instead of progressing to the admin dashboard.

All downstream tests fail because the admin account was never properly created.

### Root Causes (Multiple, Cascading)

This issue has five distinct root causes that compound each other. All must be fixed for the setup wizard to complete reliably.

#### 1. Volume Not Properly Removed (Docker Desktop Windows)
cy.resetPosteioDb() runs docker-compose down mail-test followed by docker volume rm. On Docker Desktop for Windows, the volume lock is sometimes held even after the container stops. The docker volume rm fails silently (failOnNonZeroExit: false), so old corrupted data persists.

Diagnostic:
- docker volume ls -q -f name=badminton_court_poste_data — if returns the name, it was NOT removed
- MSYS_NO_PATHCONV=1 docker exec mail-test ls /data/ — if shows files, volume was not wiped

#### 2. Stale Browser Session/Cookies
Previous setup attempts leave session cookies in the Cypress browser. When cy.setupPosteio() visits Poste.io again, the stale cookies cause the setup wizard to fail silently.

#### 3. Multi-Step Install Wizard Not Handled
Poste.io's setup wizard has multiple steps. The old performSetup function only submitted the FIRST form, then expected to be on /admin/box/. When Poste.io showed additional install screens, the test timed out.

#### 4. Excessive Wait Causing Socket Timeout
A cy.wait(30000) was added to setupPosteio before cy.visit(). This 30-second wait caused ESOCKETTIMEDOUT. The wait was unnecessary because resetPosteioDb already polls for readiness.

#### 5. SMTP Auth Timeout in Django Endpoint
The test_check_smtp_auth.py view used timeout=10 for SMTP connections. Poste.io's SSL handshake on port 465 can take 15-25 seconds. The endpoint timed out even though direct Python SMTP auth (with timeout=30) succeeded.

### Fix

#### Fix 1: database.cy.js — Force-remove container and verify volume removal
- Step 1: docker rm -f (force-remove container)
- Step 2: docker volume rm -f with verification (retry up to 10 times with 5s wait)
- Step 3: Start fresh container with docker-compose up -d
- Step 4: Verify /data is empty (confirms fresh volume)
- Step 5: Poll for readiness (not hardcoded wait)

#### Fix 2: setupPosteio.cy.js — Clear cookies before visiting
Add at the beginning of setupPosteio:
- cy.clearCookies()
- cy.clearLocalStorage()
- cy.clearAllSessionStorage()
- NO cy.wait(30000) before cy.visit

#### Fix 3: setupPosteio.cy.js — Step-through loop for multi-step wizard
- Step 1: Fill the first install form (hostname, admin email, password)
- Step 2: After submit, check if still on /admin/install/. If yes, click submit again. Repeat until off install page.
- Step 3: Navigate to /admin/login and perform login

#### Fix 4: test_check_smtp_auth.py — Increase timeout and add retry
- Increase timeout from 10 to 30
- Add socket.setdefaulttimeout(30) before each connection
- Add retry logic: 3 attempts, 10s delay between attempts
- Reset socket.setdefaulttimeout(None) after each attempt

### Verification
1. docker volume ls -q -f name=badminton_court_poste_data — should return empty
2. MSYS_NO_PATHCONV=1 docker exec mail-test ls /data/ — should return empty
3. Run posteio-flow.feature — should pass all scenarios
4. curl -s http://localhost:8000/api/test/check-smtp-auth/ — should return status ok
5. Run auth-flow.feature — all scenarios should pass

### Why This Only Affects Dev
- Dev: docker-compose down + volume rm (Docker Desktop Windows lock issues)
- Staging: API-based reset (reset_posteio_db_staging), Linux VM (no lock issues)
- Dev: Cypress browser stale cookies
- Staging: N/A (API-based reset)
- Dev: Windows SSL handshake slower
- Staging: Linux SSL handshake faster

### Related Files
- cypress/support/commands/database.cy.js — resetPosteioDb
- cypress/support/commands/setupPosteio.cy.js — setupPosteio
- court_management/components/views/test_check_smtp_auth.py — SMTP auth endpoint
- Dockerfile.posteio — must keep Haraka modifications
- Memory: Memory_PosteioDevSetupWizardFix.md