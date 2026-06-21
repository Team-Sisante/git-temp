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

## Menu 6.x: `gocd-server/Scripts/menu.js` (GCP VM Management)

| Option | Action | Side Effects |
|--------|--------|--------------|
| 6.1    | Create fresh GCP VM (runs `create-fresh-vm.js`) | Creates new VM, configures firewall, updates .env files |
| 6.2    | Setup firewall rules (runs `setup-firewall-rules.js`) | Creates/updates GCP firewall rules (SSH, HTTP, HTTPS, GoCD, app ports, mail ports) |
| 6.3    | Inject SSH key into VM | Adds agent's SSH key to VM's authorized_keys |
| 6.7    | Configure GoCD pipelines | Sets up GoCD pipeline config |
| 6.15   | Run firewall + SSH + secrets + reachability (combined) | Runs 6.2, 6.3, secrets setup, reachability check |
| 6.21   | SSH to VM | Opens SSH session to `xmione@35.198.231.9` |
| 6.22   | Create fresh VM (fully automatic) | Runs 6.1 + 6.2 + 6.3 + 6.7 automatically |
| 6.26   | Diagnose site | Runs full diagnostics (container status, logs, connectivity, SMTP, nginx, GCP LB) |
| 6.29   | Reverse SSH tunnel (ngrok alternative) | Sets up reverse SSH tunnel with GatewayPorts |
| 6.30   | Setup GCP Load Balancer | Creates/updates GCP LB for humrine.com |
| 0      | Back to main menu | None |

### Notes on 6.2 (setup-firewall-rules.js)
- Opens ALL required ports: SSH (22), HTTP (80), HTTPS (443), GoCD web (8153), staging/production web ports, mail HTTPS ports (8446, 9444), AND mail service ports (25, 110, 143, 465, 587, 993, 995, 4190).
- Asks for confirmation ("Type 'yes' to continue") before applying.
- Handles `gcloud` warning lines (filter them out, don't treat as errors).
- Strict validation — no defaults for port env vars (per Roadmap #52).

---

## Menu 16.x: `badminton_court/Scripts/menu.js` (Staging Containers)

| Option | Action | Side Effects |
|--------|--------|--------------|
| 16.1   | Start/restart web-staging | Recreates web-staging container |
| 16.2   | Start/restart db-staging | Recreates db-staging container |
| 16.3   | Start/restart redis | Recreates redis container |
| 16.4   | Start/restart mail-staging | Recreates mail-staging container (keeps volume) |
| 16.5   | Start/restart nginx-staging | Recreates nginx-staging container |
| 16.6   | Start/restart ALL staging containers | Recreates all staging containers |
| 16.7   | Wipe and recreate mail-staging volume (DESTRUCTIVE) | Stops container, removes volume, recreates container with fresh volume, 90s countdown |
| 0      | Back to main menu | None |

### Notes on 16.1-16.6 (Secure Env Export)
All staging container start/restart options use secure env var export:
1. Load `.env.common` + `.env.staging` locally via `dotenv.parse()`
2. Merge them (staging overrides common)
3. Export them in the SSH session (no .env files written to VM disk)
4. Run `sudo -E docker compose` (the `-E` preserves env vars through sudo)

This ensures secrets are never persisted on the VM filesystem.

### Notes on 16.7 (Wipe Volume + Recreate)
- **DESTRUCTIVE:** Deletes ALL staging mail data (mailboxes, domains, settings, server.ini)
- Asks for confirmation: "Are you absolutely sure? Type 'yes' to confirm:"
- If confirmed:
  1. Stops and removes the `badminton-staging-mail-staging-1` container
  2. Removes the `badminton-staging_poste_data_staging` volume
  3. Verifies the volume is actually gone
  4. Recreates the container with a fresh volume (using secure env export)
  5. Runs a 90-second countdown for Poste.io initialization
- Use this when:
  - The Poste.io state is corrupted (e.g., domain conflicts causing 500s)
  - You want to force the setup wizard to run fresh
  - You're starting a new testing cycle from scratch

---

## Menu 17.x: `badminton_court/Scripts/menu.js` (Production Containers)

| Option | Action | Side Effects |
|--------|--------|--------------|
| 17.1   | Start/restart web-production | Recreates web-production container |
| 17.2   | Start/restart db-production | Recreates db-production container |
| 17.3   | Start/restart redis | Recreates redis container |
| 17.4   | Start/restart mail-production | Recreates mail-production container (keeps volume) |
| 17.5   | Start/restart nginx-production | NOT YET CONFIGURED (shows warning) |
| 17.6   | Start/restart ALL production containers | Recreates all production containers |
| 17.7   | Wipe and recreate mail-production volume (DESTRUCTIVE) | Stops container, removes volume, recreates container with fresh volume, 90s countdown |
| 0      | Back to main menu | None |

### Notes on 17.1-17.6 (Secure Env Export)
Same secure env export pattern as 16.1-16.6, but using `.env.production` instead of `.env.staging`.

### Notes on 17.7 (Wipe Volume + Recreate)
- **DESTRUCTIVE:** Deletes ALL PRODUCTION mail data (mailboxes, domains, settings, server.ini)
- Asks for confirmation: "Are you absolutely sure? Type 'yes' to confirm:"
- Same wipe + recreate + 90s countdown pattern as 16.7
- Use with EXTREME CAUTION — this deletes real user mailboxes in production

---

## Menu 20.x: `humrine_site/Scripts/menu.js` (GCP VM Management)

The humrine_site management menu. Section 20 contains operations that run directly on the GCP VM.

| Option | Action | Side Effects |
|--------|--------|--------------|
| 20.1   | Full Docker system reset (`docker system prune -af --volumes`) | ⚠ DESTROYS everything — all containers, images, volumes, build cache |
| **20.2** | **Fix staging DB permissions** | Runs `chown -R appuser:appuser /app/data` inside `humrine-web-staging` and restarts the container |
| **20.3** | **Fix production DB permissions** | Same as 20.2 for `humrine-web-production` |
| **20.4** | **Run staging migrations** | Executes `python manage.py migrate` inside `humrine-web-staging` |
| **20.5** | **Run production migrations** | Executes `python manage.py migrate` inside `humrine-web-production` |
| 0      | Back to main menu | None |

### Notes on 20.2 / 20.3 (Fix DB permissions)
- The `humrine_site` SQLite database is stored on a persistent Docker volume (`db_data`).
- When the volume was first created, the `/app/data` directory was owned by `root`, preventing the `appuser` from writing.
- These options fix ownership in-place and restart the container so Django can open the database.
- Safe to run any time — idempotent.

### Notes on 20.4 / 20.5 (Run migrations)
- Runs Django's `manage.py migrate` inside the running container.
- Use after a deploy that introduces new models or fields — otherwise the site may return 500 errors.
- Safe to run repeatedly — Django migrations are idempotent.

---

## How to Use This Memory

When the user says something like "run 6.2" or "do option 16.7":

1. Look up the menu by the first number(s):
   - 1.x → gocd-server menu
   - 6.x → GCP VM Management menu
   - 16.x → badminton_court staging containers
   - 17.x → badminton_court production containers
   - 20.x → humrine_site GCP VM management
2. Find the option in the table.
3. Confirm with the user before running destructive operations (1.12, 1.13, 1.14, 16.7, 17.7, 20.1).
4. Read the script's source if you need to understand its exact behavior — the table is a summary, not a substitute for the code.

## When to Update This Memory
- A new menu option is added (mandatory update)
- An existing option's behavior changes (mandatory update)
- A new menu is added (e.g. a new app gets its own menu)
- An option is removed or renumbered (mandatory update + note the migration)

## Status
- Established: 2026-06-19
- Updated: 2026-06-21 (added Menu 20.x — humrine_site GCP VM Management options 20.2–20.5)
- Applies to: All interactive menus in the project
- Enforced by: Code review checklist (PRs that add/change menu options must update this file)

## Related Documentation
- `MEMORY.md` — central AI assistant protocol (10 Golden Rules)
- `Memory_PosteioStagingSetupWizardFix.md` — context for menu options 16.7, 17.7
- `Memory_PosteioDevSetupWizardFix.md` — context for menu option 2.9 (dev Poste.io reset)
- `Roadmap_Environments.md` — entries #62 (dev fix), #63 (staging fix)