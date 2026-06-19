# Memory Detail: Poste.io Setup Wizard — Staging Environment Fix

## Environment
**Staging Environment** — GCP VM (`35.198.231.9`), Linux host, Docker Engine (not Docker Desktop).
This memory covers the staging-specific fix for the Poste.io setup wizard.

> For the **dev** (Windows + Docker Desktop) variant, see `Memory_PosteioDevSetupWizardFix.md`.

## Issue Summary
The Poste.io setup wizard (`cy.setupPosteio()`) failed with HTTP 500 when run against staging. Multiple cascading root causes were diagnosed and fixed over several iterations. The final working state requires: DNS A record for `mail.humrine.com`, open mail ports on the GCP firewall, increased container memory limit, correct `POSTE_DOMAIN` env var (the email domain, NOT the mail server hostname), and a Cypress command that deletes existing domains + admin mailbox before running the setup wizard.

## Root Causes (Final, Comprehensive)

### 1. Domain Conflict (THE primary 500 cause)
The deploy script creates the `humrine.com` domain via the Poste.io console command (`domain:create`). When `cy.setupPosteio()` later runs the setup wizard, the wizard tries to create the same domain → 500 Internal Server Error (Poste.io's Symfony backend rejects duplicate domain creation).

### 2. Admin Mailbox Conflict
Same pattern — deploy script creates `aeropaceadmin@humrine.com` via console (`email:create`). The setup wizard tries to create the same admin → conflict.

### 3. `POSTE_DOMAIN` vs Mail Server Hostname Confusion
`POSTE_DOMAIN` is the EMAIL DOMAIN (e.g., `humrine.com`) — the part after `@` in email addresses. It is NOT the mail server hostname. The mail server hostname is `mail.humrine.com` (a separate DNS A record). These are distinct concepts:
- Email domain: `humrine.com` (mailboxes are `user@humrine.com`, NOT `user@mail.humrine.com`)
- Mail server hostname: `mail.humrine.com` (used in the setup wizard's "Mailserver hostname" field, and in the DNS A record)

### 4. No DNS Record for `mail.humrine.com`
Poste.io's setup wizard runs connectivity tests (SMTP, IMAP, POP3, etc.) against the hostname entered in the "Mailserver hostname" field. Without a DNS A record for `mail.humrine.com` → `35.198.231.9`, all tests timeout.

### 5. Mail Ports Not Open on GCP Firewall
Even with DNS, the connectivity tests fail if the mail ports (25, 110, 143, 465, 587, 993, 995, 4190) are not open on the GCP firewall. The original `setup-firewall-rules.js` only opened the mail HTTPS port (8446), not the SMTP/IMAP/POP3 ports.

### 6. Container Memory Limit Too Low (256MB)
The mail container's `mem_limit: 256m` was too low. Poste.io's services (Postfix, Dovecot, Rspamd, Nginx, ClamAV, Roundcube) need more memory. At 256MB, Rspamd was OOM-killed (`signal 9`), causing the container to be unhealthy and SMTP handshakes to timeout.

### 7. Staging Reset Command API Path Bug
The `reset_posteio_db_staging.py` management command used `/api/v1/...` paths, but Poste.io's API lives at `/admin/api/v1/...`. The 301 redirect stripped the Authorization header, causing silent auth failures. The reset appeared to succeed (HTTP 200) but didn't actually delete anything.

### 8. SSL Verification Failure in PyInstaller Binary
The `requests` library in the PyInstaller binary respected the `REQUESTS_CA_BUNDLE` env var (set in `Dockerfile.binary`), overriding `session.verify = False`. SSL verification failed against Poste.io's self-signed certificate.

### 9. `configure-poste-relay.js` Single-Attempt Failure
The relay config script used `runCmd` (single attempt) for the relay config call, but `runCmdWithRetry` for the login. If Poste.io's API was briefly unavailable after login, the relay config failed with no retry.

## Resolution (Final, Comprehensive)

### Fix 1: Delete Domains + Admin Before Setup Wizard (`setupPosteio.cy.js`)
The `setupPosteio` command now checks if the admin mailbox exists. If yes, it:
1. Deletes the admin mailbox via API
2. Lists all domains via API
3. Deletes the domain matching the admin email's domain
4. Waits 3 seconds
5. Runs the setup wizard (creates fresh domain + admin + server.ini)

This handles the conflict where the deploy script pre-creates the domain + admin via console.

### Fix 2: Correct `POSTE_DOMAIN` Usage
- `POSTE_DOMAIN=humrine.com` (the email domain — stays as `humrine.com`)
- `POSTE_HOSTNAME=mail-staging` (Docker-internal hostname, for Django → Poste.io API calls)
- Mail server hostname (setup wizard field): `mail.humrine.com` (derived as `mail.${POSTE_DOMAIN}`)

The `performSetup` function in `setupPosteio.cy.js` uses `mail.${POSTE_DOMAIN}` for the hostname field, NOT `POSTE_DOMAIN` directly.

### Fix 3: DNS A Record for `mail.humrine.com`
Created in GCP Cloud DNS:
```
gcloud dns record-sets create mail.humrine.com. \
    --zone=humrine-com \
    --project=project-39c0ea08-238b-47b5-915 \
    --type=A \
    --ttl=300 \
    --rrdatas=35.198.231.9
```

### Fix 4: Open Mail Ports on GCP Firewall (`setup-firewall-rules.js`)
Added 8 new ports to the `PORTS` object and `appRules` array:
- `allow-mail-smtp` (port 25)
- `allow-mail-smtps` (port 465)
- `allow-mail-submission` (port 587)
- `allow-mail-imap` (port 143)
- `allow-mail-imaps` (port 993)
- `allow-mail-pop3` (port 110)
- `allow-mail-pop3s` (port 995)
- `allow-mail-sieve` (port 4190)

### Fix 5: Increase Container Memory Limit (`docker-compose.vm.yml`)
Changed `mem_limit: 256m` to `mem_limit: 512m` for both `mail-staging` and `mail-production`. This gives Poste.io enough headroom to run all services without OOM-killing Rspamd.

### Fix 6: Fix API Path in `reset_posteio_db_staging.py`
Changed all `/api/v1/...` to `/admin/api/v1/...` (5 occurrences). Also added:
- `session.trust_env = False` (prevents `requests` from reading `REQUESTS_CA_BUNDLE` env var)
- `verify=False` on each request call (belt-and-suspenders)

### Fix 7: Preserve Admin Mailbox in Reset Command
The `_delete_all_mailboxes` function now skips the admin mailbox (reads `POSTE_API_USER` from settings). This ensures the admin mailbox persists across test cycles, so the setup wizard doesn't need to re-run on every test.

### Fix 8: Retry Logic in `configure-poste-relay.js`
Changed the relay config call from `runCmd` (single attempt) to `runCmdWithRetry` (12 attempts, 5s delay). This handles transient API failures right after login.

### Fix 9: Menu Options 16.7 and 17.7 (Wipe Volume + Recreate)
Added two new menu options to `menu.js`:
- **16.7** — Wipe and recreate `mail-staging` volume (with confirmation prompt + 90-second countdown)
- **17.7** — Wipe and recreate `mail-production` volume (with confirmation prompt + 90-second countdown)

Both use secure env var export (no .env files written to VM disk).

### Fix 10: Secure Env Export in Menu Options 16.1-16.6 and 17.1-17.6
All staging/production container start/restart options now:
1. Load `.env.common` + `.env.staging` (or `.env.production`) locally via `dotenv.parse()`
2. Merge them (staging/production overrides common)
3. Export them in the SSH session (no files written to VM disk)
4. Run `sudo -E docker compose` (the `-E` preserves env vars through sudo)

## Files Modified
- `cypress/support/commands/setupPosteio.cy.js` — delete admin + domain before wizard; use `mail.${POSTE_DOMAIN}` for hostname field
- `cypress/support/commands/database.cy.js` — `resetPosteioDbStaging` command (API-based)
- `cypress/support/commands/mailbox.cy.js` — `createRegularUserMailboxStaging` command (API-based)
- `cypress/support/step_definitions/common.js` — environment dispatch, strict `ENVIRONMENT` validation, URL-based dashboard assertion
- `court_management/components/views/test_database.py` — `reset_posteio_database_staging`, `create_mailbox` views
- `court_management/management/commands/reset_posteio_db_staging.py` — API path fix (`/admin/api/v1/`), SSL fix (`trust_env=False`, `verify=False`), skip admin mailbox in deletion
- `Scripts/configure-poste-relay.js` — use `runCmdWithRetry` for relay config call
- `Scripts/setup-firewall-rules.js` — added 8 mail service ports
- `Scripts/menu.js` — secure env export for 16.1-16.7 and 17.1-17.7; 16.7/17.7 wipe volume + recreate with confirmation + countdown
- `docker-compose.vm.yml` — `mem_limit: 512m` for mail-staging and mail-production
- `cypress.env.json` / `.env.staging` — must include `GCP_VM_IP`, `MAIL_HTTPS_HOST_PORT`, `POSTE_DOMAIN=humrine.com`, `ENVIRONMENT=staging`

## Key Lessons
1. **Email domain vs mail server hostname are different.** `POSTE_DOMAIN` is the email domain (`humrine.com`). The mail server hostname (`mail.humrine.com`) is a separate DNS record used only for the setup wizard's hostname field and connectivity tests.
2. **The deploy script pre-creates domain + admin via console.** The setup wizard can't create duplicates. The Cypress test must delete existing domains + admin before running the wizard.
3. **Poste.io's API lives at `/admin/api/v1/...`, not `/api/v1/...`.** The 301 redirect strips auth headers, causing silent failures.
4. **PyInstaller binaries respect `REQUESTS_CA_BUNDLE` env var.** Use `session.trust_env = False` to override this when calling self-signed HTTPS endpoints.
5. **Poste.io needs 512MB memory minimum.** 256MB causes Rspamd OOM-kills, making the container unhealthy.
6. **Mail ports (25, 110, 143, 465, 587, 993, 995, 4190) must be open on the firewall** for Poste.io's setup wizard connectivity tests to pass.
7. **`mail.humrine.com` DNS A record is required** for the setup wizard's connectivity tests to resolve.
8. **Never silent-default environment variables.** A missing `ENVIRONMENT` should fail loudly, not silently run dev assertions against staging.
9. **Staging reset must be API-driven.** The Cypress host cannot run `docker-compose down` against a remote VM.
10. **The admin mailbox should persist across test cycles.** The reset command skips the admin mailbox so the setup wizard doesn't re-run on every test.

## Verification (staging)
```bash
# 1. Container is healthy
docker ps --filter name=mail-staging
# STATUS should be Up ... (healthy)

# 2. SMTP auth works
curl -s https://humrine.com/court-staging/api/test/check-smtp-auth/
# Should return: {"status":"ok","protocol":"SSL:465","host":"mail-staging"}

# 3. Domains exist
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console domain:list
# Should show: humrine.com

# 4. Admin mailbox exists
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console email:list
# Should show: aeropaceadmin@humrine.com

# 5. Cypress test passes
ENVIRONMENT=staging npx cypress run --spec cypress/e2e/posteio/posteio-flow.feature --browser chrome
# All 3 scenarios should pass
```

## Status
- **Dev:** Fixed and verified (see `Memory_PosteioDevSetupWizardFix.md`)
- **Staging:** Fixed and verified — all 3 Cypress scenarios pass
- **Production:** Pending — after staging verification (apply same fixes to production env vars + deploy)

## Related Documentation
- `Memory_PosteioDevSetupWizardFix.md` — dev-environment variant
- `Memory_EnvironmentDispatchProtocol.md` — environment-dispatched test step definitions
- `Memory_StrictEnvironmentValidation.md` — Roadmap #52 enforcement
- `Memory_MenuOptionIndex.md` — menu options 16.7, 17.7 (wipe volume + recreate)
- `Poste.io setup wizard fails to complete in staging.md` — staging troubleshooting doc
- `Roadmap_Environments_Update.md` — entry #63