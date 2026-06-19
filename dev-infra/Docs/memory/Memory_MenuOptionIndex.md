# Memory Detail: Menu Option Index

## Purpose
A central index of every interactive menu and its options across the project. When the user types "1.13" or "run option 1.12", the AI assistant should consult this memory to know which script to invoke and what it does — without re-reading every script file.

The user explicitly requested this index after the conversation kept losing track of which menu option number corresponded to which action (reset, recreate, prune, etc.).

## Index Format

Each menu is documented as a table:

| Option | Action | Side Effects |

When a new menu option is added or an existing one changes, this file MUST be updated in the same PR.

---

## Menu 1: `dev-infra/Scripts/menu.js` (shared workspace launcher)

The shared entry point. Dispatches to per-app menus based on the user's selection.

| Option | Action | Side Effects |
|--------|--------|--------------|
| 1      | Open badminton_court menu | None (delegates) |
| 2      | Open gocd-server menu | None (delegates) |
| 3      | Open humrine_site menu | None (delegates) |
| 4      | Open dev-infra menu | None (delegates) |
| 0      | Exit | None |

---

## Menu 1.x: `gocd-server/Scripts/menu.js`

The GoCD management menu. All options that start with `1.` (e.g. `1.12`, `1.13`) refer to this menu.

| Option | Action | Side Effects |
|--------|--------|--------------|
| 1.1    | Start gocd-server and agents (`docker-compose up -d`) | Starts containers |
| 1.2    | Stop gocd-server and agents (`docker-compose down`) | Stops containers, keeps volumes |
| 1.3    | Restart gocd-server and agents | Stop + start |
| 1.4    | View gocd-server logs (`docker logs -f gocd-server`) | None |
| 1.5    | View agent logs | None |
| 1.6    | Build & push all app images (runs `build-and-push.js`) | Pushes to registry |
| 1.7    | Deploy all apps (runs `deploy.js`) | Deploys to GCP VM |
| 1.8    | Setup firewall rules (runs `setup-firewall-rules.js`) | Modifies GCP firewall |
| 1.9    | View agent status (GoCD dashboard) | None |
| 1.10   | Register agents (runs `register-agents.js`) | Registers agents with GoCD server |
| 1.11   | `docker system prune -f` (cleanup dangling images/containers) | Removes dangling Docker resources |
| 1.12   | Reset GoCD project (runs `gocd-reset.js`) | Wipes GoCD config volumes, preserves app data |
| 1.13   | Force-recreate gocd-server container (runs `gocd-recreate-server.js`) | Removes + recreates gocd-server container only |
| 1.14   | Cleanup gocd-server and its agents + volumes + buildkit | Wipes GoCD containers/volumes/buildkit cache (NOT app data) |
| 0      | Back to main menu | None |

### Notes on 1.11 vs 1.14
- 1.11 (`docker system prune -f`) is non-destructive — it only removes dangling (untagged) images and stopped containers. Safe to run any time.
- 1.14 is destructive — it removes the gocd-server container, all agent containers, their volumes, AND the buildkit cache. Use this only when GoCD itself is in a corrupted state and 1.12 (reset) doesn't help. App data is NOT affected.

### Notes on 1.12 (gocd-reset.js)
- Wipes GoCD's config volumes (`/godata/config`, `/godata/db`, etc.) so the next `docker-compose up` starts from a clean cruise-config.xml.
- Does NOT touch app data (badminton_court, humrine_site, etc.).
- After running 1.12, agents need to be re-registered via 1.10.

### Notes on 1.13 (gocd-recreate-server.js)
- Only recreates the `gocd-server` container itself — does NOT touch agents or volumes.
- Useful when the server container's filesystem is corrupted but the volumes are fine.
- Faster than 1.12 and preserves agent registrations.

---

## Menu 2.x: `badminton_court/Scripts/menu.js`

The badminton_court app menu.

| Option | Action | Side Effects |
|--------|--------|--------------|
| 2.1    | Start dev environment (`docker-compose --profile dev up -d`) | Starts dev containers |
| 2.2    | Stop dev environment | Stops dev containers, keeps volumes |
| 2.3    | Restart dev environment | Stop + start |
| 2.4    | View app logs | None |
| 2.5    | Run Cypress tests (dev) | `ENVIRONMENT=dev npx cypress run` |
| 2.6    | Run Django migrations | Applies migrations to dev DB |
| 2.7    | Create superuser | Prompts for credentials |
| 2.8    | Compile PyInstaller binary | Runs `Dockerfile.compile` |
| 2.9    | Reset Poste.io dev volume (via Cypress `cy.resetPosteioDb`) | Wipes `badminton_court_poste_data` |
| 2.10   | Reset Poste.io staging volume (via Django API) | Wipes `badminton-staging_poste_data_staging` (skips admin mailbox) |
| 2.11   | Run Cypress tests (staging) | `ENVIRONMENT=staging npx cypress run` |
| 0      | Back to main menu | None |

### Notes on 2.5 vs 2.11
- 2.5 (dev tests) uses `docker-compose`-driven reset and `localhost:8443` for Poste.io.
- 2.11 (staging tests) uses the Django API for reset and `https://35.198.231.9:8446/` for Poste.io, with `POSTE_DOMAIN=aeropace.com` as the hostname field.
- Both run the SAME feature files. Dispatch happens inside the step definitions (see `Memory_EnvironmentDispatchProtocol.md`).

### Notes on 2.9 vs 2.10
- 2.9 (dev) wipes the entire dev volume — including the admin mailbox. The setup wizard will re-run on the next test cycle.
- 2.10 (staging) wipes only regular-user mailboxes — the admin mailbox PERSISTS. The setup wizard does NOT re-run unless explicitly invoked.

---

## Menu 3.x: `humrine_site/Scripts/menu.js`

The humrine_site app menu. (Sparsely populated — add options as they're implemented.)

| Option | Action | Side Effects |
|--------|--------|--------------|
| 3.1    | Start dev environment | Starts dev containers |
| 3.2    | Stop dev environment | Stops dev containers |
| 0      | Back to main menu | None |

---

## Menu 4.x: `dev-infra/Scripts/menu.js`

The dev-infra menu (infrastructure-level operations).

| Option | Action | Side Effects |
|--------|--------|--------------|
| 4.1    | Setup GCP firewall rules (runs `setup-firewall-rules.js`) | Creates/updates GCP firewall rules |
| 4.2    | Verify GCP VM SSH access | None |
| 4.3    | Pull latest from all repos | `git pull` in each repo |
| 0      | Back to main menu | None |

### Notes on 4.1 (setup-firewall-rules.js)
- Reads ports dynamically from environment variables (no hard-coded port list).
- Required env vars: `MAIL_HTTPS_HOST_PORT`, `MAIL_SMTP_HOST_PORT`, `MAIL_SMTPS_HOST_PORT`, `BADMINTON_HTTPS_HOST_PORT`, etc.
- Asks for confirmation before applying.
- Handles `gcloud` warning lines (filter them out, don't treat as errors).

---

## How to Use This Memory

When the user says something like "run 1.13" or "do option 2.11":

1. Look up the menu by the first number (1 -> gocd-server, 2 -> badminton_court, 3 -> humrine_site, 4 -> dev-infra).
2. Find the option in the table.
3. Confirm with the user before running destructive operations (1.12, 1.13, 1.14, 2.9, 2.10).
4. Read the script's source if you need to understand its exact behavior — the table is a summary, not a substitute for the code.

## When to Update This Memory
- A new menu option is added (mandatory update)
- An existing option's behavior changes (mandatory update)
- A new menu is added (e.g. a new app gets its own menu)
- An option is removed or renumbered (mandatory update + note the migration)

## Status
- Established: 2026-06-19
- Applies to: All interactive menus in the project
- Enforced by: Code review checklist (PRs that add/change menu options must update this file)

## Related Documentation
- `MEMORY.md` — central AI assistant protocol (10 Golden Rules)
- `Memory_PosteioStagingSetupWizardFix.md` — context for menu options 2.10, 2.11
- `Memory_PosteioDevSetupWizardFix.md` — context for menu options 2.5, 2.9
- `Roadmap_Environments_Update.md` — entries #62 (dev fix), #63 (staging fix)