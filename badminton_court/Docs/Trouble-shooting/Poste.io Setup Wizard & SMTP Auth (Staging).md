# Poste.io Setup Wizard & SMTP Auth — Staging Environment
## Source: Docs/Trouble-shooting/Poste.io Setup Wizard & SMTP Auth (Staging).md

**Status:** Fixed and verified (June 20, 2026)

### Problem
`cy.setupPosteio()` failed with HTTP 500 when run against staging. Nine cascading root causes were diagnosed and fixed.

### Root Causes (summary)
1. Domain conflict – deploy script creates `humrine.com` via console; wizard tries to create the same domain.
2. Admin mailbox conflict – deploy script creates `aeropaceadmin@humrine.com`; wizard tries to create the same admin.
3. `POSTE_DOMAIN` vs mail server hostname confusion (`humrine.com` vs `mail.humrine.com`).
4. No DNS record for `mail.humrine.com`.
5. Mail ports (25, 110, 143, 465, 587, 993, 995, 4190) not open on GCP firewall.
6. Container memory limit too low (256MB → OOM killed rspamd).
7. Staging reset command used wrong API path (`/api/v1/` instead of `/admin/api/v1/`).
8. SSL verification failure in PyInstaller binary due to `REQUESTS_CA_BUNDLE` env var.
9. `configure-poste-relay.js` single‑attempt failure.

### Solution
- `setupPosteio.cy.js`: delete admin mailbox + domain via API before setup; use `mail.${POSTE_DOMAIN}` for hostname field.
- `reset_posteio_db_staging.py`: fix API path, add `session.trust_env = False` and `verify=False`.
- `configure-poste-relay.js`: use `runCmdWithRetry` for relay config.
- `setup-firewall-rules.js`: add 8 mail service ports.
- `docker-compose.vm.yml`: increase mail memory limit to 512m.
- `menu.js`: add 16.7/17.7 (wipe volume + recreate), secure env export for staging/production.
- DNS: create `mail.humrine.com` A record pointing to VM IP.
- Env vars: `POSTE_DOMAIN=humrine.com`, `POSTE_HOSTNAME=mail-staging`.

### Result
All 3 Cypress `posteio-flow.feature` scenarios pass in staging. SMTP auth works, relay configured. Staging admin mailbox persists across test cycles.

### Related Files
- `Memory_PosteioStagingSetupWizardFix.md` (git‑temp)
- `badminton_court/cypress/support/commands/setupPosteio.cy.js`
- `badminton_court/docker-compose.vm.yml`
- `gocd-server/Scripts/setup-firewall-rules.js`