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

## Menu 3.x: `humrine_site/Scripts/menu.js` (Humrine Site Management)

This menu is launched from the top‑level `dev-infra/Scripts/menu.js` (option 3) or directly via `node Scripts/menu.js <environment>`.

### 1. LOCAL DEVELOPMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 1.1    | Start local dev (`python manage.py runserver`) | Runs Django development server on port 8000 |
| 1.2    | Start local dev (detached) | Runs `node Scripts/run-detached.js` |
| 1.3    | Stop local dev | Runs `node Scripts/stop-server.js` |
| 1.4    | Load local dev data | Runs `python manage.py load_test_data` |
| 1.5    | Start dev tunnel | Runs `python tunnel.py` |

### 2. LOCAL CYPRESS TESTING
| Option | Action | Side Effects |
|--------|--------|--------------|
| 2.1    | Open Cypress interactive | Opens Cypress GUI with env file selection |
| 2.2    | Run Cypress (headed) | Runs Cypress tests in headed Chrome |
| 2.3    | Run Cypress (headless) | Runs Cypress tests headlessly |
| 2.4    | Run Cypress for presentation (headed) | Runs tests with video recording, then post‑processes videos |
| 2.5    | Select Cypress test for presentation | Interactive test selection for presentation |
| 2.6    | Post‑process videos | Runs `Scripts/post-process-videos.js` |
| 2.7    | Run Cypress spec (headed) | Runs a specific spec file for presentation |

### 3. DOCKER DEVELOPMENT ENVIRONMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 3.1    | Start dev environment | `docker compose up` with dev profile |
| 3.2    | Start dev (detached) | `docker compose up -d` with dev profile |
| 3.3    | Stop dev | `docker compose down` with dev profile |
| 3.4    | Show dev logs | `docker compose logs -f` with dev profile |
| 3.5    | Restart web‑dev | `docker compose restart web-dev` |
| 3.6    | Start dev with certs | Generates SSL certs, then starts dev detached |
| 3.7    | Reset and start dev | Rebuilds dev, generates certs, starts detached, waits for DB, runs migrations |
| 3.8    | Force recreate dev containers | `docker compose up -d --force-recreate` |

### 4. DOCKER TESTING ENVIRONMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 4.1    | Start test environment | `docker compose up` with test profile |
| 4.2    | Start test (detached) | `docker compose up -d` with test profile |
| 4.3    | Stop test | `docker compose down` with test profile |
| 4.4    | Show test logs | `docker compose logs -f` with test profile |
| 4.5    | Setup test data | Runs `test-setup` service |

### 5. DOCKER CYPRESS TESTING
| Option | Action | Side Effects |
|--------|--------|--------------|
| 5.1    | Start Cypress container | `docker compose up -d cypress` |
| 5.2    | Open Cypress in container | `docker compose exec cypress open` |
| 5.3    | Run Cypress in container | `docker compose exec cypress run` |
| 5.4    | Stop Cypress container | `docker compose stop cypress` |
| 5.5    | Run Cypress headed (new container) | `docker compose run --rm cypress cypress run --headed` |
| 5.6    | Run Cypress headless (new container) | `docker compose run --rm cypress cypress run --headless` |
| 5.7    | Run connectivity tests | Runs connectivity spec headlessly |
| 5.8    | Install Cypress | Runs `cypress-install` helper |
| 5.9    | Clear Cypress cache | `npx cypress cache clear` |

### 6. DOCKER PRESENTATION ENVIRONMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 6.1    | Select presentation test | Interactive selection in Docker |
| 6.2    | Post‑process videos | Runs post‑processor in Docker |
| 6.3    | Run presentation spec | Runs a specific spec headed, then post‑processes |

### 7. DOCKER TUNNEL MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 7.1    | Build tunnel | Builds tunnel service image |
| 7.2    | Build tunnel (no cache) | Builds tunnel without cache |
| 7.3    | Start tunnel | `docker compose up tunnel` |
| 7.4    | Start tunnel (detached) | `docker compose up -d tunnel` |
| 7.5    | Stop tunnel | `docker compose stop tunnel` |
| 7.6    | Show tunnel logs | `docker compose logs -f tunnel` |

### 8. DOCKER DATABASE MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 8.1    | Run migrations | `python manage.py migrate` inside web‑dev container |
| 8.2    | Reset DB | Runs `reset-db-docker.js` |
| 8.3    | Reset DB with migrations | Runs `reset-db-docker.js --migrate` |
| 8.4    | Full DB reset with test data | Runs `reset-db-docker.js --migrate --load-test-data` |

### 9. DOCKER IMAGE MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 9.1    | Build all images | Builds dev, test, tunnel, presentation profiles |
| 9.2    | Build all (no cache) | Same without build cache |
| 9.3    | Build dev images | Builds dev profile only |
| 9.4    | Build dev (no cache) | Dev profile without cache |
| 9.5    | Build Cypress image | Builds Cypress service |
| 9.6    | Build Cypress (no cache) | Cypress without cache |
| 9.7    | Build presentation images | Builds dev + presentation profiles |
| 9.8    | Build presentation (no cache) | Same without cache |

### 10. DOCKER SYSTEM MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 10.1   | Rebuild all | Down + remove images for all profiles, then build all |
| 10.2   | Rebuild dev | Rebuild dev only |
| 10.3   | Rebuild test | Rebuild test only |
| 10.4   | Rebuild presentation | Rebuild presentation only |
| 10.5   | Show service logs | `docker compose logs -f` with dev profile |
| 10.6   | Open shell in service | Exec shell in a user‑specified service |
| 10.7   | Down & remove volumes (DESTRUCTIVE) | `docker compose down -v` |
| 10.8   | Prune unused Docker resources | `docker system prune -f` |
| 10.9   | Full reset (remove all) | Down all profiles, prune |
| 10.10  | Full reset (keep images) | Down all profiles, prune old (>24h) |
| 10.11  | Show service status | `docker compose ps` |

### 11. ADVANCED CLEANUP
| Option | Action | Side Effects |
|--------|--------|--------------|
| 11.1   | Complete system prune | `docker system prune -a --volumes -f` |
| 11.2   | Deep cleanup (restart Docker Desktop) | Stops Docker Desktop, prunes, restarts |
| 11.3   | Factory reset Docker Desktop | Manual reset via UI |
| 11.4   | Clean content store | Fixes blob errors, restarts Docker Desktop |
| 11.5   | COMPLETE Docker reset | Runs `docker-desktop-reset.js` |
| 11.6   | Full reset and restart dev | Reset + rebuild everything |

### 12. BACKUP & RESTORE
| Option | Action | Side Effects |
|--------|--------|--------------|
| 12.1   | Backup all images | Saves all images to `all-images.tar` |
| 12.2   | Restore all images | Restores from `all-images.tar` |
| 12.3   | Backup individual images | Adds specific images to archive |
| 12.4   | Restore specific image | Restores a named image from archive |
| 12.5   | List backups | Lists files in `./backups` directory |
| 12.6   | List backup contents | Shows raw contents of `all-images.tar` |
| 12.7   | List backup image names | Shows human‑readable list of images in archive |
| 12.8   | Save containers to Docker Hub | Pushes running containers to Docker Hub |
| 12.9   | Backup database (dumpdata) | Creates a JSON fixture of the database |
| 12.10  | Restore database from backup | Restores a JSON fixture after confirmation |

### 13. UTILITIES
| Option | Action | Side Effects |
|--------|--------|--------------|
| 13.1   | Create SSL certs | Generates OpenSSL certificates |
| 13.2   | Create SSL certs (Admin) | Elevated version for Windows |
| 13.3   | Open shell in service | Interactive shell in a Docker service |
| 13.4   | Print project structure | Displays directory tree |
| 13.5   | Encrypt env files | Encrypts all `.env` files |
| 13.6   | Decrypt env files | Decrypts all `.env` files |
| 13.7   | Create PostIO container | Runs `createpostio.js` |
| 13.8   | Uninstall Docker | Runs uninstall script |
| 13.9   | Generate README | Generates README via `@catmeow/readme-ai` |
| 13.10  | Search keyword in Git history | Interactive search with scope selection |
| 13.11  | Generate .env from GitHub/GCP | Fetches secrets and generates `.env` file |
| 13.12  | Migrate to GitHub Environments | Moves variables to GitHub Environments |
| 13.13  | Migrate to GCP Secret Manager | Moves variables to GCP Secret Manager |
| 13.14  | Make the repository private | Changes repo visibility to private |
| 13.15  | Authenticate GitHub CLI (gh auth login) | Interactive GitHub authentication |
| 13.16  | Update GITHUB_TOKEN in all .env files | Syncs token across files |
| 13.17  | Set GITHUB_TOKEN (manual or gh auth) | Guided token setup |
| 13.18  | Display GitHub authentication status | Shows `gh auth status` |
| 13.19  | Display current GitHub token | Shows keyring token |
| 13.20  | Open GitHub PAT page in browser | Opens GitHub tokens settings |
| 13.21  | Activate local venv shell | Opens new shell with venv activated |
| 13.22  | Create/Recreate local venv | Creates or overwrites local venv |
| 13.25  | Setup/Update social media apps | Runs `python manage.py setup_social_apps` |
| 13.26  | Validate social media secrets | Runs setup + validation |
| 13.27  | List GCP secrets | Runs `gcloud secrets list` |
| 13.28  | List GitHub Environment variables | Fetches and displays GitHub variables for a chosen environment |

### 14. DOCKER COMPOSE MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 14.1   | Stop containers | `docker compose down` |
| 14.2   | Remove containers & volumes | `docker compose down -v` |
| 14.3   | Remove images | `docker compose down -v --rmi all` |
| 14.4   | System prune related objects | `docker compose down -v --rmi all` + `docker system prune -a --volumes -f` |
| 14.5   | Compile app into Linux binary | Runs `node Scripts/compile.js` |

### 15. BINARY DOCKER MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 15.1   | Build binary image | `docker compose -f docker-compose.binary.yml build` |
| 15.2   | Start binary env | `docker compose -f docker-compose.binary.yml up` |
| 15.3   | Start binary env (detached) | `docker compose -f docker-compose.binary.yml up -d` |
| 15.4   | Stop binary env | `docker compose -f docker-compose.binary.yml down` |
| 15.5   | Show binary env logs | `docker compose -f docker-compose.binary.yml logs -f` |
| 15.6   | Reset binary env (remove volumes) | `docker compose -f docker-compose.binary.yml down -v` |

### 16. STAGING CONTAINERS (start/restart)
*Note: The current menu options 16.1–16.5 still reference the old `badminton‑staging` project and are being refactored to use `humrine-staging`. 16.6 now uses a secure env export and `docker compose` for humrine_site.*

| Option | Action | Side Effects |
|--------|--------|--------------|
| 16.1   | Web (web-staging) | Recreates web-staging container (currently badminton‑staging – pending fix) |
| 16.2   | Database (db-test) | Recreates db-test container |
| 16.3   | Redis | Recreates redis container |
| 16.4   | Mail | Recreates mail-staging container |
| 16.5   | Nginx (HTTPS) | Recreates nginx-staging container |
| 16.6   | Start/Restart all staging containers | Interactive env loading, then `docker compose up -d` for humrine-staging |

### 17. PRODUCTION CONTAINERS (start/restart)
*Similar to staging; options still reference the badminton‑production project.*

| Option | Action | Side Effects |
|--------|--------|--------------|
| 17.1   | Web (web-production) | Recreates web-production container |
| 17.2   | Database (db) | Recreates db container |
| 17.3   | Redis | Recreates redis container |
| 17.4   | Mail | Recreates mail-production container |
| 17.5   | Nginx (HTTPS – future) | Not yet configured |
| 17.6   | Start/Restart all production containers | Restarts all production containers |

### 18. DELETE STAGING IMAGES (stop container & remove image)
| Option | Action | Side Effects |
|--------|--------|--------------|
| 18.1   | Web (web-staging) | Stops and removes image for web-staging |
| 18.2   | Database (db-test) | Stops and removes image for db-test |
| 18.3   | Redis | Stops and removes image for redis |
| 18.4   | Mail | Stops and removes image for mail-staging |
| 18.5   | Nginx (HTTPS) | Stops and removes image for nginx-staging |
| 18.6   | FULL CLEAN (containers, images, volumes, cache) | Full cleanup for staging |

### 19. DELETE PRODUCTION IMAGES (stop container & remove image)
| Option | Action | Side Effects |
|--------|--------|--------------|
| 19.1   | Web (web-production) | Stops and removes image for web-production |
| 19.2   | Database (db) | Stops and removes image for db |
| 19.3   | Redis | Stops and removes image for redis |
| 19.4   | Mail | Stops and removes image for mail-production |
| 19.5   | Nginx (HTTPS – future) | Not yet configured |
| 19.6   | FULL CLEAN (containers, images, volumes, cache) | Full cleanup for production |

### 20. GCP VM MANAGEMENT
| Option | Action | Side Effects |
|--------|--------|--------------|
| 20.1   | Full Docker system reset | `docker system prune -af --volumes` (⚠ DESTROYS everything) |
| 20.2   | Fix staging DB permissions | `chown -R appuser:appuser /app/data` inside `humrine-web-staging` and restarts the container |
| 20.3   | Fix production DB permissions | Same as 20.2 for `humrine-web-production` |
| 20.4   | Run staging migrations | Executes `python manage.py migrate` inside `humrine-web-staging` |
| 20.5   | Run production migrations | Executes `python manage.py migrate` inside `humrine-web-production` |

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
   - 3.x → humrine_site management menu (full index above)
   - 16.x → badminton_court staging containers
   - 17.x → badminton_court production containers
   - 20.x → humrine_site GCP VM management (subset of 3.x)
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
- Updated: 2026-06-21 (added complete humrine_site menu documentation as Menu 3.x; added new VM management options 20.2–20.5)
- Applies to: All interactive menus in the project
- Enforced by: Code review checklist (PRs that add/change menu options must update this file)

## Related Documentation
- `MEMORY.md` — central AI assistant protocol (10 Golden Rules)
- `Memory_PosteioStagingSetupWizardFix.md` — context for menu options 16.7, 17.7
- `Memory_PosteioDevSetupWizardFix.md` — context for menu option 2.9 (dev Poste.io reset)
- `Roadmap_Environments.md` — entries #62 (dev fix), #63 (staging fix)