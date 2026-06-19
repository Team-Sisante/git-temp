# Poste.io setup wizard fails to complete in staging environment
## Source: Docs/Trouble-shooting/Poste.io setup wizard fails to complete in staging.md

## Troubleshooting the Poste.io setup wizard in the staging environment

> **Environment:** Staging only (GCP VM `35.198.231.9`, Linux host, Docker Engine).
> For the **dev** variant, see `Poste.io setup wizard fails to complete in dev.md`.

### Symptom
The Poste.io setup wizard (`cy.setupPosteio()`) failed with HTTP 500 when run against staging. The 500 appeared immediately after clicking the submit button on the setup form. Multiple cascading root causes were diagnosed.

### Root Causes (Final, Comprehensive)

This issue has **nine** distinct root causes that compound each other. All must be fixed for the setup wizard to complete reliably.

#### 1. Domain Conflict (THE primary 500 cause)
The deploy script creates the `humrine.com` domain via the Poste.io console command (`domain:create`). When `cy.setupPosteio()` later runs the setup wizard, the wizard tries to create the same domain → 500 Internal Server Error.

**Diagnostic:**
```bash
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console domain:list
# If this shows humrine.com (or mail.humrine.com), the setup wizard will 500
```

#### 2. Admin Mailbox Conflict
Same pattern — deploy script creates `aeropaceadmin@humrine.com` via console. The setup wizard tries to create the same admin → conflict.

**Diagnostic:**
```bash
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console email:list
# If this shows aeropaceadmin@humrine.com, the setup wizard will 500
```

#### 3. `POSTE_DOMAIN` vs Mail Server Hostname Confusion
`POSTE_DOMAIN` is the EMAIL DOMAIN (e.g., `humrine.com`) — the part after `@` in email addresses. It is NOT the mail server hostname. The mail server hostname is `mail.humrine.com` (a separate DNS A record).

**Correct values:**
- `POSTE_DOMAIN=humrine.com` (email domain)
- `POSTE_HOSTNAME=mail-staging` (Docker-internal hostname, for Django → Poste.io API)
- Mail server hostname (setup wizard field): `mail.humrine.com` (derived as `mail.${POSTE_DOMAIN}`)

**Incorrect (causes failures):**
- `POSTE_DOMAIN=mail.humrine.com` → mailboxes would be `user@mail.humrine.com` (wrong)
- `POSTE_DOMAIN=35.198.231.9` → Poste.io rejects IP as hostname (500)

#### 4. No DNS Record for `mail.humrine.com`
Poste.io's setup wizard runs connectivity tests (SMTP, IMAP, POP3, etc.) against the hostname entered in the "Mailserver hostname" field. Without a DNS A record for `mail.humrine.com` → `35.198.231.9`, all tests timeout (~30s each, 13 tests = ~6.5 minutes).

**Diagnostic:**
```bash
nslookup mail.humrine.com
# Should return 35.198.231.9
```

#### 5. Mail Ports Not Open on GCP Firewall
Even with DNS, the connectivity tests fail if the mail ports are not open on the GCP firewall.

**Diagnostic:**
```bash
gcloud compute firewall-rules list --project=project-39c0ea08-238b-47b5-915 | grep allow-mail
# Should show: allow-mail-smtp, allow-mail-smtps, allow-mail-submission,
# allow-mail-imap, allow-mail-imaps, allow-mail-pop3, allow-mail-pop3s,
# allow-mail-sieve, allow-mail-https-staging, allow-mail-https-production
```

#### 6. Container Memory Limit Too Low (256MB)
The mail container's `mem_limit: 256m` was too low. At 256MB, Rspamd was OOM-killed (`signal 9`), causing the container to be unhealthy and SMTP handshakes to timeout.

**Diagnostic:**
```bash
sudo docker stats --no-stream badminton-staging-mail-staging-1
# MEM USAGE / LIMIT should be well under 512MiB
```

#### 7. Staging Reset Command API Path Bug
The `reset_posteio_db_staging.py` management command used `/api/v1/...` paths, but Poste.io's API lives at `/admin/api/v1/...`. The 301 redirect stripped the Authorization header, causing silent auth failures.

**Diagnostic:**
```bash
curl -s -k https://35.198.231.9:8446/api/v1/boxes
# Returns 301 redirect to /admin/api/v1/boxes (auth stripped during redirect)

curl -s -k https://35.198.231.9:8446/admin/api/v1/boxes
# Returns 401 (auth required) — this is the correct path
```

#### 8. SSL Verification Failure in PyInstaller Binary
The `requests` library in the PyInstaller binary respected the `REQUESTS_CA_BUNDLE` env var (set in `Dockerfile.binary`), overriding `session.verify = False`. SSL verification failed against Poste.io's self-signed certificate.

**Diagnostic:**
```bash
sudo docker exec badminton-staging-web-staging-1 /app/badminton_court_linux reset_posteio_db_staging
# If you see "SSLCertVerificationError", the SSL fix is not applied
```

#### 9. `configure-poste-relay.js` Single-Attempt Failure
The relay config script used `runCmd` (single attempt) for the relay config call. If Poste.io's API was briefly unavailable after login, the relay config failed with no retry.

**Diagnostic (from deploy logs):**
```
[SETUP] Login to Poste.io API succeeded on attempt 2.
WARNING: SMTP relay config failed, but deployment completed.
```
If you see "SMTP relay config failed", the retry fix is not applied.

### Fix

#### Fix 1: Delete Domains + Admin Before Setup Wizard (`setupPosteio.cy.js`)
The `setupPosteio` command checks if the admin mailbox exists. If yes, it:
1. Deletes the admin mailbox via API
2. Lists all domains via API
3. Deletes the domain matching the admin email's domain
4. Waits 3 seconds
5. Runs the setup wizard (creates fresh domain + admin + server.ini)

#### Fix 2: Correct `POSTE_DOMAIN` Usage
- `POSTE_DOMAIN=humrine.com` (the email domain)
- Mail server hostname (setup wizard field): `mail.${POSTE_DOMAIN}` (e.g., `mail.humrine.com`)

The `performSetup` function uses `mail.${POSTE_DOMAIN}` for the hostname field, NOT `POSTE_DOMAIN` directly.

#### Fix 3: DNS A Record for `mail.humrine.com`
```bash
gcloud config set account solomiosisante@gmail.com
gcloud dns record-sets create mail.humrine.com. \
    --zone=humrine-com \
    --project=project-39c0ea08-238b-47b5-915 \
    --type=A \
    --ttl=300 \
    --rrdatas=35.198.231.9
```

#### Fix 4: Open Mail Ports on GCP Firewall (`setup-firewall-rules.js`)
Add 8 new ports to the `PORTS` object and `appRules` array:
- `allow-mail-smtp` (port 25)
- `allow-mail-smtps` (port 465)
- `allow-mail-submission` (port 587)
- `allow-mail-imap` (port 143)
- `allow-mail-imaps` (port 993)
- `allow-mail-pop3` (port 110)
- `allow-mail-pop3s` (port 995)
- `allow-mail-sieve` (port 4190)

Then run menu option 6.2 (`setup-firewall-rules.js`) to create the rules.

#### Fix 5: Increase Container Memory Limit (`docker-compose.vm.yml`)
Change `mem_limit: 256m` to `mem_limit: 512m` for both `mail-staging` and `mail-production`.

#### Fix 6: Fix API Path in `reset_posteio_db_staging.py`
Change all `/api/v1/...` to `/admin/api/v1/...` (5 occurrences). Also add:
- `session.trust_env = False` (prevents `requests` from reading `REQUESTS_CA_BUNDLE` env var)
- `verify=False` on each request call

#### Fix 7: Preserve Admin Mailbox in Reset Command
The `_delete_all_mailboxes` function skips the admin mailbox (reads `POSTE_API_USER` from settings). This ensures the admin mailbox persists across test cycles.

#### Fix 8: Retry Logic in `configure-poste-relay.js`
Change the relay config call from `runCmd` to `runCmdWithRetry` (12 attempts, 5s delay).

#### Fix 9: Menu Options 16.7 and 17.7 (Wipe Volume + Recreate)
Added two new menu options for wiping the Poste.io volume and recreating the container fresh. Both have confirmation prompts and 90-second countdowns.

#### Fix 10: Secure Env Export in Menu Options 16.1-16.7 and 17.1-17.7
All staging/production container start/restart options now export env vars in the SSH session (no files written to VM disk).

### Manual Recovery (if the 500 still happens)

If the setup wizard still 500s after applying all fixes, manually delete the domains and admin mailbox via console:

```bash
# Delete all mailboxes (none should exist, but verify)
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console email:list

# Delete all domains
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console domain:remove humrine.com
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console domain:remove mail.humrine.com

# Verify both are gone
sudo docker exec --user 8 badminton-staging-mail-staging-1 /opt/admin/bin/console domain:list
# Should be empty
```

Then re-run the Cypress test. The setup wizard will create everything fresh.

### Verification

After applying all fixes:

```bash
# 1. ENVIRONMENT is set
npx cypress env
# Should show: ENVIRONMENT=staging, GCP_VM_IP=35.198.231.9, MAIL_HTTPS_HOST_PORT=8446, POSTE_DOMAIN=humrine.com

# 2. Staging Poste.io container is healthy
docker ps --filter name=mail-staging
# STATUS: Up X seconds (healthy)

# 3. Memory is under 512MB
docker stats --no-stream badminton-staging-mail-staging-1
# MEM USAGE / LIMIT should be well under 512MiB

# 4. DNS resolves
nslookup mail.humrine.com
# Should return 35.198.231.9

# 5. Mail ports are open
gcloud compute firewall-rules list --project=project-39c0ea08-238b-47b5-915 | grep allow-mail
# Should show all 10 mail-related rules

# 6. SMTP auth works
curl -s https://humrine.com/court-staging/api/test/check-smtp-auth/
# Should return: {"status":"ok","protocol":"SSL:465","host":"mail-staging"}

# 7. Run the test
ENVIRONMENT=staging npx cypress run --spec cypress/e2e/posteio/posteio-flow.feature --browser chrome
# All 3 scenarios should pass
```

### Why This Only Affects Staging

| Concern | Dev | Staging |
|---------|-----|---------|
| Cypress host | Same machine as Docker | Different machine (user's PC) |
| Docker socket access | Direct | None — must go through Django API |
| Hostname field | `localhost` (from apiHost) | `mail.humrine.com` (from `mail.${POSTE_DOMAIN}`) |
| DNS resolution | N/A (localhost) | Requires `mail.humrine.com` A record |
| Firewall | N/A (local Docker) | Requires mail ports open on GCP firewall |
| Memory limit | 256MB works (no Rspamd OOM) | 512MB required (Rspamd OOM at 256MB) |
| Reset path | `docker-compose down` + `volume rm` | `POST /api/test/reset-posteio-db-staging/` |
| Admin mailbox | Recreated each cycle | Persists across cycles (reset skips admin) |
| Domain conflict | N/A (fresh volume each cycle) | Setup wizard must delete pre-created domain |
| Step default | Hard-coded dev | Explicit dispatch (no defaults) |

### Related Files
- `cypress/support/commands/setupPosteio.cy.js` — delete admin + domain before wizard; use `mail.${POSTE_DOMAIN}` for hostname field
- `cypress/support/commands/database.cy.js` — `resetPosteioDbStaging` (API-based)
- `cypress/support/commands/mailbox.cy.js` — `createRegularUserMailboxStaging` (API-based)
- `cypress/support/step_definitions/common.js` — environment dispatch, strict `ENVIRONMENT` validation
- `court_management/components/views/test_database.py` — `reset_posteio_database_staging`, `create_mailbox` views
- `court_management/management/commands/reset_posteio_db_staging.py` — API path fix, SSL fix, skip admin mailbox
- `Scripts/configure-poste-relay.js` — retry logic for relay config
- `Scripts/setup-firewall-rules.js` — 8 mail service ports
- `Scripts/menu.js` — 16.7/17.7 wipe volume + recreate; secure env export for 16.x/17.x
- `docker-compose.vm.yml` — `mem_limit: 512m` for mail-staging and mail-production
- See also: `Poste.io setup wizard fails to complete in dev.md`
- Memory: `Memory_PosteioStagingSetupWizardFix.md`
- Memory: `Memory_EnvironmentDispatchProtocol.md`
- Memory: `Memory_StrictEnvironmentValidation.md`
- Memory: `Memory_MenuOptionIndex.md