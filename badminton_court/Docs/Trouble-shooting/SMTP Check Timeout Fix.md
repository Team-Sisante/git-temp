# SMTP Check Timeout Fix
## Source: Docs/Trouble-shooting/SMTP Check Timeout Fix.md

**Status:** Completed (June 25, 2026)

### Problem
Cypress tests timed out (30 seconds) when polling the `/api/test/check-smtp-auth/` endpoint on staging/production. The view used a 30‑second timeout for the SMTP connection, which exceeded Cypress's request timeout and caused the test to fail.

### Solution
- Modified `test_check_smtp_auth` in `court_management/components/views/test_check_smtp_auth.py` to use an environment‑aware timeout.
- In **staging/production**, the SMTP connection timeout is **5 seconds** (fast fail, returns 503 if mail server isn't ready).
- In **development**, the original **30‑second** timeout is preserved.
- The view now responds immediately instead of hanging, allowing the Cypress polling loop to retry until the mail server is ready.

### Related Files
- `badminton_court/court_management/components/views/test_check_smtp_auth.py`
- `badminton_court/cypress/support/step_definitions/authentication/auth-flow.js`