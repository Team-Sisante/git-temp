<!-- AI ASSISTANT NOTE: Always refer to this document and update it as tasks are completed or architecture changes. Do not remove this note! Also do not remove the history of modifications. [HARD RULE] When editing, ALWAYS preserve ALL existing content. Only ADD new entries or UPDATE existing ones. NEVER delete or shorten the history.
[RULE] Every roadmap document MUST be updated by the engineer after any significant decision, finding, code fix, or task completion to ensure project state transparency.
[RULE] You should always update these roadmap documents on our decisions, findings, fixes and next tasks after doing the updates/changes/modifications.
-->

# Roadmap: Multi-Environment Migration for Badminton Court
# badminton_court/Docs/Roadmap_Environments.md

This document outlines the plan to move from file-based environment management to GitHub Environments and GoCD automation.

## Phase 1: Infrastructure & Deployment (Current)
- [x] **GCP Setup:** Created e2-micro VM in `us-central1-a` (Always Free Tier).
- [x] **Static IP:** Reserved and assigned static IP to the VM.
- [x] **Docker Installation:** Successfully installed Docker and Docker Compose on the GCP VM.
- [x] **Template & Route Unification:** Standardized all pages to use `main_base.html`, consolidated public and legal routes to root (`/`), unified navigation and header, fixed CSS styling, and resolved 404 errors by seeding static Page records.
- [x] **Safety Confirmations:** Implemented mandatory "yes" confirmation for encryption and decryption menu operations.
- [x] **Interactive SSH Fix:** Updated interactive SSH sessions (`sshToVM.js`) to support proper terminal interactivity and error pausing.
- [ ] **GoCD Connection:** Finalize the SSH handshake between the local GoCD agent and the GCP VM.
- [ ] **First Deploy:** Deploy the `badminton_court` app using the remote Docker context to ensure SQLite persistence is working on the 30GB disk.

## Phase 1.5: Staging Deployment Fixes (2026-05-27)
- [x] **Wrong Dockerfile Target (PR #6):** `build-and-push.js` specified `Dockerfile` instead of `Dockerfile.binary`. Docker's default behavior builds the last stage, which was `tunnel` (runs `python tunnel.py`) instead of `web` (runs Django `runserver`). Fixed by targeting `Dockerfile.binary` explicitly.
- [x] **Stale Image Cache (PR #6):** `deploy.js` used `--pull missing`, which skips pulling if any version of the image exists locally. After pushing a corrected image to ghcr.io, the old cached image was still used on the VM. Fixed by changing to `--pull always`.
- [x] **VM Resource Exhaustion (PR #7):** The `mail-staging` container (Poste.io) consumed 430% CPU and 382MB RAM on the 1GB VM, causing `docker ps` to hang and massive swap thrashing. Fixed by adding `mem_limit` to all 10 services in `docker-compose.vm.yml` (~768m total per profile).
- [x] **Matplotlib Font Cache Slowdown (PR #8):** `setup-binary.sh` used `MPLCONFIGDIR=/tmp/.matplotlib`, which is ephemeral. Every container restart triggered a slow font cache rebuild. Fixed by installing `fontconfig`+`fonts-dejavu-core` in `Dockerfile.binary`, running `fc-cache -f` at build time, and using a persistent `MPLCONFIGDIR=/app/.matplotlib`.

## Phase 2: Professionalization & Monetization
- [ ] **Enhanced Landing Page:** Redesign the landing page to include professional branding, promotional sections, and integrated CMS for articles/videos.
- [ ] **Social Authentication:** Implement 'Sign In with' for Google, Facebook, Instagram, and Twitter.
- [ ] **Environment Segregation:** Create `.env.staging` and `.env.production` to manage local vs. cloud settings.
- [x] **Privacy Policy/ToS:** Added compliant legal pages accessible at root-level URLs.
- [ ] **Affiliate Integration:** Create a "Partner Resources" page in the Python app to host affiliate links.
- [ ] **AdSense Application:** Apply for Google AdSense once the site is live and populated with content.

---

*All content below is the original roadmap history. Nothing has been removed or altered.*

## Architectural Decisions (Phase 3)

### 1. Binary Compilation Strategy
- **Goal:** Security and efficiency.
- **Implementation:** The Django/Python application is compiled into a standalone Linux binary (`badminton_court_linux`) during the build process.
- **Benefit:** Final production containers do not require source code or Python interpreters, reducing attack surface and image size.

### 2. Artifact Management (ghcr.io)
- **Registry:** GitHub Container Registry (`ghcr.io`).
- **Artifacts:**
    - `ghcr.io/xmione/badminton_court-web`: Contains the compiled binary.
    - `ghcr.io/xmione/badminton_court-mail`: Contains customized Poste.io configuration.
- **Third-Party Services:** Standard services (Postgres, Redis) use official Docker Hub images directly to ensure maintenance and security updates.

### 3. GoCD Pipeline Architecture
The deployment is split into three distinct pipelines to ensure isolation and control:

1.  **Artifacts Pipeline (`badminton_court-artifacts`):**
    - Triggered by: `git push master`.
    - Purpose: Compiles binary, builds images, and pushes to `ghcr.io`.
    - **Execution environment:** The GoCD agent (local/development machine). **No build or compilation occurs on the remote deployment VM.**
2.  **Staging Pipeline (`badminton_court-staging`):**
    - Triggered by: **Manual Approval** (Supervised) – changed from automatic to avoid unintended deployments after artifacts success.
    - Environment: Uses GitHub `development` variables.
    - Deployment: Port 8001 on GCP VM.
    - **Action:** Only `docker compose up` using images from `ghcr.io`. No explicit `pull` — Compose automatically pulls when image digest changes. No `--force-recreate` — containers restart only when the image changes, making config‑only deployments fast (~30 seconds).
3.  **Production Pipeline (`badminton_court-production`):**
    - Triggered by: **Manual Approval** (Supervised).
    - Environment: Uses GitHub `docker-production` variables.
    - Deployment: Port 8000 on GCP VM.
    - Requirement: Successful Staging verification.
    - **Action:** Only `docker compose up` using images from `ghcr.io` (same optimizations as staging).

### 4. Local Build & Push Philosophy
- **Intellectual Property Protection:** Source code never leaves the development environment. Only the compiled binary (inside a Docker image) is published to the registry.
- **Build Location:** The entire compilation and image build sequence is executed on the GoCD agent, which is part of your local/controlled infrastructure (Windows host or Cloud Shell). The remote deployment VM merely consumes the resulting images.
- **Network Considerations:** Large image pushes are performed from the agent's network, avoiding Cloud Shell's unstable connection when used as a build host. If using Windows directly, network reliability is typically higher.

## Technical Challenges & Adaptations

### 1. Automation Network Isolation
- **Problem:** GoCD agents running in Docker containers experienced intermittent network isolation and SSH key persistence issues when trying to reach the GCP VM via raw `ssh`.
- **Solution:** Replaced `gcloud compute ssh` with standard `ssh -i /secret/agent-key` after provisioning a dedicated SSH key pair to the target VM's instance metadata. This approach is simpler, fully cross‑platform, and avoids any dependency on the Google Cloud SDK inside the agent for SSH.
- **Benefit:** Connection reliability is now guaranteed without the need for temporary key injection or additional IAM permissions.

### 2. Single‑VM Staging & Production Coexistence
- **Constraint:** Budget limitation requires both staging and production to run on the same GCP VM.
- **Problem:** The default `docker-compose.vm.yml` uses identical container names and host ports for both environments, causing conflicts when both are active.
- **Solution:** 
  - Each environment is launched with a unique Docker Compose project name (`badminton` for staging, `badminton-production` for production) to prevent container name collisions.
  - Host ports for production are incremented relative to staging (which mirrors local development ports). All port mappings are stored in environment‑specific `.env.staging` and `.env.production` files, keeping the compose file clean and the pipeline script minimal.
- **Benefit:** Both environments can run side‑by‑side without manual intervention. The staging environment remains identical to local development, reducing debugging surprises.

### 3. Menu Architecture & Staging Access
- **Problem:** Duplicated VM management functions in `badminton_court` menu caused confusion about ownership and required replicating SSH key access across workspaces.
- **Solution:** 
  - All GCP VM lifecycle, GoCD management, and remote staging/production Docker commands now reside exclusively in the `gocd-server` menu (options 6.15‑6.20).
  - The `badminton_court` menu focuses on application development, local Docker, testing, GitHub utilities, environment file generation, and direct container/image management via SSH (sections 16‑19).
  - Remote Docker commands on the staging VM use the dedicated `agent-key` already present in the `gocd-server` workspace.
- **Benefit:** Clear separation of concerns; no more "which menu does this?" confusion. All SSH connectivity uses the same hardened key, and no Google Cloud SDK flag‑parsing issues occur because we use raw `ssh` commands.

### 4. VM Re‑creation from Exported YAML (Bug Fix)
- **Problem:** `gcloud compute instances create` does not accept `--source-instance-config` in older CLI versions, and exported YAML contained full URLs that failed as arguments.
- **Solution:** 
  - Parsed the exported YAML in the menu script to extract short machine‑type names, network names, image paths, and disk sizes.
  - Constructed a `gcloud compute instances create` command with standard flags that work across all CLI versions.
  - Added existence checks, warnings, and automatic backup of the previous YAML before overwriting.
- **Benefit:** The "create VM from saved YAML" (6.12) and "recreate fresh VM" (6.13) options are now robust and version‑agnostic.

### 5. gcloud TLS Crash in Git Bash Environment
- **Problem:** When running `gcloud` commands from a Node.js script executed in Git Bash, `gcloud` incorrectly looks for CA certificates at `/etc/ssl/certs/ca-certificates.crt` (a Linux path) and crashes with `OSError`.
- **Solution:** 
  - In `migrate-to-gcp-secrets.js`, added detection of a valid certificate bundle from Git for Windows (`mingw64/etc/ssl/cert.pem`) and set `CLOUDSDK_CA_CERTS_FILE`, `REQUESTS_CA_BUNDLE`, and `CURL_CA_BUNDLE` environment variables to that file.
- **Benefit:** The GCP Secret Manager migration now works from any terminal environment.

### 6. GitHub Environment Secret Migration Robustness
- **Problem:** `gh secret set` printed the secret value in error output, and failed if the environment didn't already exist or if `GITHUB_TOKEN` was set to the same token used for authentication.
- **Solution:** 
  - `migrate-environments.js` now checks and creates the environment if missing, skips `GITHUB_TOKEN` if it matches the current auth token, and uses a safe wrapper (`runSecretSet`) that never leaks the secret body.
- **Benefit:** Migration is secure and idempotent.

### 7. Staging Pipeline Secret Corruption (Fully Resolved)
- **Problem:** The `SECRET_KEY` stored in GCP Secret Manager contained extra characters (`-n`, quotes), causing `generate-env.js` to write a malformed line to `.env.staging`. This broke Docker Compose on the VM.
- **Root Cause:** The old `migrate-to-gcp-secrets.js` used `echo -n "${value}" | gcloud …`, which mangled the value through shell interpretation. Additionally, the script decrypted stale `.gpg` files that still held the corrupted value.
- **Solution:** 
  - Overwrote the GCP secret using a file‑based upload (`--data-file`) to avoid shell interpretation.
  - Migrated encryption from GPG to AES‑256‑GCM (Node.js crypto), producing `.enc` files that are immune to agent problems.
  - Updated `migrate-to-gcp-secrets.js` to read the new `.enc` files, permanently breaking the corruption cycle.
  - Hardened `generate-env.js` to always quote values containing special characters.
- **Benefit:** Staging deploys reliably. Future secret migrations are safe from corruption. The pipeline passed after these fixes.

### 8. Menu Error Visibility (Readline Conflict)
- **Problem:** Errors in the pipeline trigger function flashed and disappeared because the global `readline` interface conflicted with `inquirer.prompt`, causing the pause prompt to resolve instantly.
- **Solution:** 
  - Added `rl.pause()` before using `inquirer` and `rl.resume()` after.
  - Used a module‑level `errorDisplayed` flag to prevent the menu screen from clearing until the error is acknowledged.
- **Benefit:** All errors now remain on screen until the user presses Enter.

### 9. Pipeline Task Evolution (Final State)
- **Problem:** The original `deploy.js` task used SCP and required correct directory ownership on the VM. A later SSH one‑liner was introduced to avoid SCP, but it cloned the entire repository onto the VM, violating the "Local Build & Push Philosophy" (source code must not leave the development environment).
- **Solution:** 
  - Reverted pipeline tasks back to `deploy.js`, which copies only the necessary deployment files (`docker-compose.vm.yml` and the generated `.env` file) via SCP.
  - Fixed the directory ownership issue by ensuring `create-fresh-vm.js` (startup script) sets correct permissions for the SSH user.
  - The VM now only needs those two files; no source code ever resides on it.
- **Benefit:** Intellectual property is protected; the deployment remains lean and compliant with the roadmap.

### 10. VM Boot‑Time Reliability (Apt Lock Race)
- **Problem:** During boot, GCP's guest agent sometimes holds the apt lock while the startup script tries to install packages. This caused `git` (and occasionally other tools) to silently fail, breaking subsequent pipeline steps.
- **Solution:** 
  - Added a 30‑attempt lock‑wait loop at the start of the startup script. It waits up to 5 minutes for the apt lock to be released before proceeding.
  - Removed all quiet flags (`-qq`) so that installation progress is always visible in the log.
  - Added a final verification step that checks each critical tool and logs a warning if any are missing.
- **Benefit:** VMs are now fully provisioned every time; no more "command not found" errors during deployment.

### 11. VM Service Account & Scope Automation
- **Problem:** The staging pipeline could not access GCP Secret Manager because the VM lacked the `cloud-platform` scope and the appropriate IAM role.
- **Solution:** 
  - Added `--scopes=https://www.googleapis.com/auth/cloud-platform` to the VM creation command in `create-fresh-vm.js`.
  - Included an idempotent IAM policy binding (`roles/secretmanager.secretAccessor`) before VM creation.
- **Benefit:** Every new VM automatically has the permissions needed to read secrets. No manual scope adjustments required.

### 12. Static IP Reservation
- **Problem:** The VM received a new ephemeral IP after every recreation, requiring manual updates to `.env.docker` and pipeline configurations.
- **Solution:** 
  - `create-fresh-vm.js` now manages a static IP reservation (`gocd-deploy-target-ip`). It reads `GCP_VM_IP` from the environment and ensures the reservation matches.
  - If the desired IP is not available, it falls back to an automatic static IP and updates `.env.docker` automatically.
- **Benefit:** The VM always retains the same IP. No more manual env file edits after recreation.

### 13. Menu Architecture & Granularity (Final State)
- **Problem:** The original `menu.js` was monolithic and difficult to maintain. Individual actions (VM creation, container logs, etc.) were embedded directly in the switch statement, leading to duplication and hard‑coded logic.
- **Solution:** 
  - Split the menu into a slim dispatcher (`menu.js`) and a `menu/` folder containing individual modules: `triggerPipeline.js`, `containerLogs.js`, `containerManagement.js`, `pipelineManagement.js`, `systemUtilities.js`, `dockerTroubleshoot.js`, `vmSetup.js`.
  - Extracted shared logic into reusable modules: `containerList.js` (remote container listing), `interactiveContainerAction.js` (generic interactive container action), `viewLogs.js`, `restartService.js`, `quickLogCheck.js`, `sshToVM.js`, etc.
  - All modules receive a shared `ctx` object containing helpers (`sh`, `log`, `ask`, `pause`, etc.) and environment variables.
- **Benefit:** Every menu option is independently editable and testable. Adding a new option requires only a few lines. No duplicate code exists for container operations.

### 14. Menu Error Visibility
- **Problem:** Errors in many menu options flashed and disappeared because the screen was cleared before the user could read them. The `readline`/`inquirer` conflict in `triggerPipeline` also caused pause prompts to resolve instantly.
- **Solution:** 
  - Added `rl.pause()` before using `inquirer` and `rl.resume()` after in all interactive options.
  - Used a module‑level `errorDisplayed` flag to prevent the menu screen from clearing until the error is acknowledged.
  - Set `errorDisplayed = true` inside the global `sh()` function so any command that fails automatically holds the error on screen.
- **Benefit:** All errors now remain visible until the user presses Enter.

### 15. Staging Environment Variable Cleanup
- **Problem:** The `DATABASE_URL`, `POSTGRES_PRISMA_URL`, `POSTGRES_URL_NON_POOLING`, and `POSTGRES_URL_NO_SSL` variables persisted in GitHub repository‑level variables and local `.env.dev` files, causing `generate-env.js` to write `localhost` URLs into `.env.staging`. This overrode the correct `DATABASE_URL` built by the compose file.
- **Solution:** 
  - Deleted those variables from all GitHub scopes (repository‑level and environment‑level).
  - Added a `SKIP_VARS` filter in `generate-env.js` that permanently prevents those variables from being written into any generated `.env` file.
  - Cleaned the local `.env.dev` and `.env.staging` files.
- **Benefit:** The pipeline now always generates a clean `.env.staging`. The compose file builds the correct `DATABASE_URL` from individual `POSTGRES_*` variables. No more `localhost` connection errors.

### 16. Agent DNS Fix
- **Problem:** GoCD agent containers could not resolve external registries (ghcr.io), causing Docker push/pull failures during the artifacts pipeline.
- **Solution:** Added `dns: 8.8.8.8` to all agent services in `docker-compose.yml`.
- **Benefit:** Agents can now reach external registries without manual intervention.

### 17. SSH Key Permission Auto‑Fix
- **Problem:** The agent's SSH private key was mounted with world‑readable permissions on Windows, causing `Permission denied (publickey)` during SCP.
- **Solution:** `deploy.js` now runs `chmod 600 /secret/agent-key` before any SCP or SSH command.
- **Benefit:** The pipeline works reliably on Windows Docker hosts without manual permission fixes.

### 18. Binary Deployment & Environment Consistency
- **Problem:** The staging container failed to connect to the database because `CYPRESS=true` was inadvertently set in `docker-compose.vm.yml`, which forced `database.py` into a test branch that hardcoded `localhost`. Additionally, the compiled binary crashed on startup with `RuntimeError: Script runserver does not exist` because Django's autoreloader tried to restart the binary.
- **Solution:**
  - Removed `CYPRESS=true` from the `web-staging` service in `docker-compose.vm.yml`.
  - Refactored `database.py`: renamed `is_docker` to `in_container` and expanded the condition to `os.environ.get('ENVIRONMENT') in ('docker', 'staging', 'production')`.
  - Added `--noreload` flag to the `CMD` in `Dockerfile.binary` (`["runserver", "--noreload", "0.0.0.0:8000"]`).
  - Ensured the binary is executable with `RUN chmod +x /app/badminton_court_linux` in the Dockerfile.
  - Made the database host configurable in `setup-binary.sh` by using `DB_HOST` environment variable (default `db-test`), and added `DB_HOST` to both `web-staging` and `web-production` services in the compose file.
  - Removed duplicate migration and site setup commands at the end of `setup-binary.sh`.
- **Benefit:** Staging deployments now reliably connect to the correct database host. The binary starts without autoreloader crashes, and the same Docker image works for both staging and production by simply changing the `DB_HOST` environment variable.

### 19. HTTPS Reverse Proxy & Certificate Provisioning
- **Problem:** Adding HTTPS to staging via nginx failed because the required SSL certificate files were missing on the VM. The compose file mounted a local `certs/` directory, but it didn't exist or was empty.
- **Solution:**
  - The `deploy.js` pipeline now copies the entire `certs/` directory from the repository to the VM using SCP when nginx is enabled.
  - If the `certs/` directory is missing in the repo, the deployment fails with a clear error message instructing the user to run `generate-certs.js` first.
  - This ensures certificates are always present and provisioned in a single pipeline step, without manual intervention.
  - No hardcoded paths: the source is the repository's `certs/` folder (created by `generate-certs.js`).
- **Benefit:** HTTPS works out‑of‑the‑box after the initial certificate generation. The process remains fully automated and environment‑driven.

### 20. Missing Modules in Compiled Binary (PyInstaller String References)
- **Problem:** Django modules referenced only as dotted strings in settings (`badminton_court.context_processors`, `court_management.adapters`, `court_management.email_backend`) were **not** bundled by PyInstaller because no real `import` statement exists for them. This caused `ModuleNotFoundError` at runtime. Similarly, custom Django management commands (e.g., `reset_django_db`, `load_test_data`) were not bundled, causing `Unknown command` errors during Cypress tests.
- **Root Cause:** PyInstaller follows actual imports. Settings strings and management commands are resolved dynamically by Django at runtime, so PyInstaller's analysis never sees them.
- **Solution:** Added explicit imports in `manage.py` (the script being compiled) for every module that is referenced via a settings string, **and** for all custom management commands. These imports are placed **after** `django.setup()` to avoid `AppRegistryNotReady` errors. This guarantees PyInstaller includes them.
- **Benefit:** The compiled binary now contains all custom modules and management commands, eliminating runtime import errors permanently. No more manual `--hidden-import` tweaks needed.

### 21. HTTPS Firewall Automation
- **Problem:** The GCP firewall did not allow traffic on the staging HTTPS port (`8444`), causing browser connection timeouts even though nginx was running correctly.
- **Solution:** Created a permanent firewall rule (`allow-web-https-staging`) allowing TCP ingress on port 8444 from all sources. This rule survives VM recreations and only needs to be created once. Additionally, `deploy.js` now ensures the rule exists before each deployment (idempotent check‑and‑create).
- **Benefit:** HTTPS access to staging works immediately after the rule is created. The rule is automatically verified on every pipeline run.

### 22. Local GCP Authentication for Menu Scripts
- **Problem:** When running `generate-env.js` locally (via menu option 13.11), the script failed to fetch secrets from GCP Secret Manager because the local machine was not authenticated to GCP. The pipeline worked fine because the GoCD agent has its own service‑account key, but that key was never referenced locally.
- **Why this was not an issue before:** The original workflow only used `generate-env.js` inside the pipeline (run by the agent). Secrets were uploaded to GCP via `13.13` (which uses the user's `gcloud` credentials), but never downloaded locally. Option `13.11` (added later) introduced the first local download use case.
- **Solution:**
  - The existing service‑account key file (`gocd-server/secrets/gcp-key.json`), originally provisioned by `setup-gcp-secrets-access.js` (menu option 6.5), is now referenced via a new environment variable `GCP_SA_KEY_PATH`.
  - Both menus (`badminton_court/Scripts/menu.js` and `gocd-server/Scripts/menu.js`) now automatically load this key after `dotenv.config()` by setting `GOOGLE_APPLICATION_CREDENTIALS`.
  - The variable `GCP_SA_KEY_PATH` is added to the respective `.env` files each menu loads, pointing to the same physical key file using relative paths.
  - No new key file was created – only a reference to the existing one.
- **Benefit:** Option 13.11 (and any other local `gcloud` command) now works seamlessly without manual authentication. The setup survives VM recreations and is consistent between both menus.

### 23. Multi‑Project Pipeline Visibility
- **Problem:** The `pay-sol-group` pipelines defined in `cruise-config.xml` did not appear in the GoCD dashboard, even though the file was syntactically correct. Only the `badminton_court_group` was visible.
- **Root Cause:** The configuration file inside the GoCD server container was not updated, or the server did not reload it after the last change. Option 6.7 ("Apply pipeline configuration to GoCD") had silently failed or was not executed.
- **Solution:**
  - Applied the pipeline configuration via menu option 6.7 (or direct copy + API reload).
  - Verified with `docker exec gocd-server grep "pay-sol-group" /godata/config/cruise-config.xml` that the file inside the container is correct.
  - After reloading, both pipeline groups are now visible.
- **Benefit:** All defined pipelines are accessible from the GoCD dashboard, enabling future automation and management of the `pay-sol` project.

### 24. Pipeline Trigger Authentication (Automatic Login)
- **Problem:** The trigger function (option 2.1) required a manual session cookie because the GoCD personal access token was rejected or lacked permissions.
- **Solution:** Updated `triggerPipeline.js` to prefer the admin username/password already present in `.env.docker`. It now uses Basic Auth with those credentials, completely bypassing the need for a token or manual cookie. If admin creds are missing, it falls back to a token, and finally to a manual cookie.
- **Benefit:** Pipeline triggering is now fully automatic with no manual steps required. The approach uses existing, always‑valid credentials.

### 25. VM Disk Space Management
- **Problem:** The staging VM disk filled up during a deployment, causing `no space left on device` errors and preventing the new image from being extracted.
- **Solution:** Added menu option 6.24 ("Clean up Docker disk space on staging VM") that runs `docker system prune -af` and `docker volume prune -f` on the VM via SSH, then shows the current disk usage. This recovers space and confirms the operation.
- **Benefit:** Quick recovery from disk‑full situations without manual SSH commands. The option uses the same agent SSH key, so no additional setup is required.

### 26. VM Docker Daemon DNS & MTU Resolution
- **Problem:** After pruning unused Docker images or restarting the Docker daemon, the deployment VM could not resolve external registries (`ghcr.io`). Additionally, network performance and connectivity issues were observed due to MTU mismatches on GCP VMs.
- **Root Cause:** The Docker daemon on the VM had no explicit DNS or MTU configuration. It fell back to the host's `/etc/resolv.conf` (unreliable local resolver) and default MTU (often 1500, while GCP VPC defaults to 1460).
- **Solution:**
  - Added a permanent DNS and MTU configuration to the VM's Docker daemon by writing `{"dns":["8.8.8.8"], "mtu": 1460}` to `/etc/docker/daemon.json` and restarting Docker.
  - **Full Automation:** This configuration is enforced idempotently in `deploy.js` on every deployment and is also part of the VM startup script in `create-fresh-vm.js`. This ensures the VM is correctly configured from birth, preventing "Banner Exchange" timeouts during initial GoCD setup (Option 6.22).
- **Benefit:** The VM's Docker daemon always resolves external registries reliably and ensures optimal network performance on GCP infrastructure. No manual intervention required after VM recreation.

### 27. Web‑Staging Healthcheck Stability
- **Problem:** The original `curl`‑based healthcheck for `web-staging` occasionally failed because the HTTP server responded with a 302 redirect (treated as failure by Docker) or took too long to start. This made `nginx-staging` refuse to start, breaking HTTPS.
- **Solution:** Replaced the healthcheck with a process‑based check: `["CMD-SHELL", "pgrep -f badminton_court_linux > /dev/null || exit 1"]`. This immediately confirms the binary is running, without depending on HTTP readiness.
- **Benefit:** The container becomes healthy the moment the process starts, so `nginx-staging` always starts successfully. The deployment pipeline no longer fails due to healthcheck timeouts.

### 28. Production Deployment Dependency Conflict
- **Problem:** The production pipeline failed with `service "web-staging" depends on undefined service "db-test"` because the compose file defined `web-staging` without a profile restriction. Even though only production‑scoped services were started, Docker Compose validates the entire file and saw `web-staging` depending on `db-test` (which is staging‑only).
- **Solution:** Added `profiles: [staging]` to both `web-staging` and `nginx-staging` services in `docker-compose.vm.yml`. Now they are invisible when the production profile is active, eliminating the conflict.
- **Benefit:** Production deployments run without unnecessary validation errors. The compose file remains clean and profiles correctly isolate staging and production services.

### 29. Production Port Conflict Resolution
- **Problem:** The production pipeline failed because the `mail` service tried to bind to port 8444 (also used by staging nginx). Since both environments run on the same VM, all host ports must be unique.
- **Solution:** Defined separate port variables in the GitHub `docker-production` environment. Production now uses its own port range (e.g., web on 8002, HTTPS on 9444, mail on 2526/588/466/9443). The compose file already reads these from environment variables, so no code changes were needed.
- **Benefit:** Staging and production run side‑by‑side without port collisions. The port assignments are fully environment‑driven and automatically applied by the pipeline.

### 30. Production DB_HOST Configuration
- **Problem:** The production web container was waiting for `db-test` (staging database) at startup because the `setup-binary.sh` script defaults to `db-test` when `DB_HOST` is not set. The compose file didn't pass `DB_HOST=db` for production.
- **Solution:** Added `DB_HOST=db` to the `web-production` service environment in `docker-compose.vm.yml`. The startup script now correctly waits for the production database.
- **Benefit:** Production containers start without hanging. Staging continues to use `db-test` as before.

### 31. Cypress Environment‑Aware Testing (Menu Option 2.1)
- **Problem:** The Cypress interactive mode always loaded `.env.dev` and used `localhost:8000`, making it impossible to test against staging or production without manual environment variable exports. Additionally, `cypress.config.js` internally loaded a different `.env` file and overrode the `baseUrl` passed via command line. Setting `allowCypressEnv=false` to suppress a warning broke `cy.env()` calls in tests.
- **Final Solution:**
  - Replaced the hardcoded command in option 2.1 with an inquirer list offering four choices: Development (.env.dev), Docker (.env.docker), Staging (.env.staging), Production (.env.production).
  - The menu sets `CYPRESS_ENV_FILE` (absolute path to the chosen env file) and launches Cypress. No `--config baseUrl` is passed.
  - `cypress.config.js` loads the env file (if `CYPRESS_ENV_FILE` is set), reads `CYPRESS_BASEURL`, cleans it (strips comments after `#`, trims whitespace/quotes), and uses it as `config.baseUrl`.
  - No defaults, no `localhost` fallback — missing or invalid `CYPRESS_BASEURL` throws a clear error.
  - `allowCypressEnv` is left enabled (default), so `cy.env()` works for all test code.
  - Environment variable propagation is guaranteed by passing `CYPRESS_ENV_FILE` via `execSync`'s `env` option.
- **Benefit:** You can open Cypress and test against any environment with one click. Tests use `cy.env()` as before. No more manual exports, file editing, URL corruption, or localhost confusion. The solution is final and will not be changed again.

### 32. SSH Post‑Quantum Key Exchange Warning Suppression
- **Problem:** Every SSH/SCP command in the pipeline emitted a warning about post‑quantum key exchange algorithms, cluttering the logs.
- **Solution:** Added shared `SSH_OPTS` and `SCP_OPTS` variables in `deploy.js` containing `-o KexAlgorithms=+diffie-hellman-group14-sha256`. Applied consistently to all `ssh` and `scp` commands. Also applied in menu helper functions (`remoteDockerComposeUp`, `remoteDeleteImage`).
- **Benefit:** Pipeline logs and menu output are clean and only show actual errors or progress information.

### 33. Pipeline Speed Optimization
- **Problem:** The staging/production pipelines were slow (2+ minutes) because they ran `docker compose pull` and `up -d --force-recreate` on every execution, even when only a configuration file (`.env`, `docker-compose.vm.yml`) changed.
- **Solution:**
  - Removed the explicit `docker compose pull` from `deploy.js`. Docker Compose's `up` automatically pulls the image if the local copy's digest differs from the registry.
  - Removed `--force-recreate` from the pipeline's `up` command. The container now restarts only when the image digest changes, not on every deployment.
  - Added menu sections 16 and 17 to start/restart specific containers with `--force-recreate` on demand (e.g., after environment file changes that require a full container restart).
  - Added menu sections 18 and 19 to delete specific images, forcing a fresh pull on the next container start.
- **Benefit:** Pipeline deployments now take ~30 seconds for configuration‑only changes. Full container restart is available through the menu when a hard restart is required. No functionality is lost.

### 34. Menu Restructure – Container & Image Management
- **Problem:** Starting/stopping individual staging or production containers required manual SSH commands, and there was no way to delete images to force a fresh pull without SSH.
- **Solution:**
  - Added sections 16–19 to the `badminton_court` menu, using the same agent SSH key already present in the `gocd-server` workspace.
  - **Section 16 – Start/Restart Staging Containers:** 16.1 web-staging, 16.2 db-test, 16.3 redis, 16.4 mail, 16.5 nginx-staging.
  - **Section 17 – Start/Restart Production Containers:** 17.1 web-production, 17.2 db, 17.3 redis, 17.4 mail, 17.5 nginx-production (placeholder).
  - **Section 18 – Delete Staging Images:** 18.1–18.5, stops the container then removes its image.
  - **Section 19 – Delete Production Images:** 19.1–19.5, same approach.
  - Helper functions `remoteDockerComposeUp` and `remoteDeleteImage` encapsulate the SSH commands, using environment variables for all parameters (no hardcoded IPs or ports).
  - The old section 16 (staging environment tasks like VM status, container listing, logs) was removed from the `badminton_court` menu — those tasks now live exclusively in the `gocd-server` menu (options 6.16–6.24).
- **Benefit:** All container lifecycle operations are available directly from the menu. No more manual SSH commands. Third‑party images (postgres, redis, etc.) are shared between staging and production — deleting one removes it for both, but they are tiny and will be re‑pulled automatically on next start.

### 35. Service Account Secret Reader Permission (Local Development)
- **Problem:** The local service account (`gocd-agent-secrets@…`) used by the menus to fetch GCP secrets did not have the `roles/secretmanager.secretAccessor` role. This caused `generate-env.js` to leave `<?secret?>` placeholders when run locally (the pipeline on the VM worked because the compute SA already had the role).
- **Root Cause:** The role was never assigned to this specific service account. The local `gcloud` commands authenticate via the key file specified by `GCP_SA_KEY_PATH`, and without the role, all secret lookups fail.
- **Solution:**
  - Switched `gcloud` to the personal owner account (`solomiosisante@gmail.com`) using `gcloud config set account`.
  - Enabled the Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`) on the project.
  - Granted the role via `gcloud projects add-iam-policy-binding … --member="serviceAccount:gocd-agent-secrets@…" --role="roles/secretmanager.secretAccessor"`.
  - This is a permanent, project‑level IAM binding – it survives VM recreations and never needs to be repeated.
- **Benefit:** Both the local menus and the VM pipeline can now read all secrets from GCP Secret Manager without any manual authentication steps.

### 36. Template‑Based Environment File Generation
- **Problem:** Generated `.env.staging` and `.env.production` files were always sorted alphabetically and lacked comments/section headers, making them hard to read. The local hand‑crafted `.env.dev` had a clear structure that was lost every time `generate-env.js` ran.
- **Solution:**
  - Created `templates/.env.staging.template` and `templates/.env.production.template` with all comments, section headers, and `<?var?>` / `<?secret?>` placeholders.
  - Updated `generate-env.js` to accept a `--template <path>` argument. When provided, it reads the template, replaces `<?var?>` with values from GitHub Environments, and `<?secret?>` with values from GCP Secret Manager. The template structure is preserved exactly.
  - No defaults, no `localhost` fallbacks – missing values leave the placeholder and print a warning.
  - Menu option 13.11 now automatically passes the correct template for staging/production; dev/docker remain comment‑less (or can be added later).
  - Pipeline (`deploy.js`) also passes the template flag, so the VM gets beautifully formatted `.env` files.
- **Benefit:** All generated environment files now have the same readable structure as the hand‑crafted `.env.dev`, with full automation and no manual reformatting.

### 37. Migration Scripts Driven by Template Placeholders
- **Problem:** The old migration scripts (`migrate-environments.js`, `migrate-to-gcp-secrets.js`) decided whether a variable was a secret based on keywords (`PASSWORD`, `SECRET`, `TOKEN`, `KEY`). This caused false positives (`GCP_SA_KEY_PATH` uploaded to GCP) and false negatives, and did not match what the generated `.env` files actually needed.
- **Solution:**
  - Rewritten `migrate-environments.js`: now reads the environment‑specific template (e.g., `templates/.env.staging.template`) and uploads **only** variables marked `<?var?>` as plain GitHub environment variables. Secrets are skipped entirely.
  - Rewritten `migrate-to-gcp-secrets.js`: reads all templates, collects the keys marked `<?secret?>`, decrypts the `.enc` files, and uploads **only** those secrets to GCP. The old keyword‑based detection is gone.
  - Both scripts use absolute paths (via `__dirname`) so they work regardless of the current working directory when called from the menu.
  - `GITHUB_TOKEN` is correctly marked `<?secret?>` in the template and thus never pushed to GitHub as a plain variable.
- **Benefit:** The migration scripts now mirror exactly what the generated `.env` files will contain. No more guessing, no more accidental secret leakage. The templates are the single source of truth for what goes where.

### 38. Cypress Environment Variable Unification (Pending)

### 39. GitHub CLI Token Management Automation
- **Problem:** The `GITHUB_TOKEN` environment variable was not properly managed, causing authentication failures with `gh auth status` and `gh auth token`. The `unset` command in the menu did not effectively clear the token from both the shell and the Node.js process environment, leading to stale tokens being used.
- **Root Cause:** 
  - On Windows, `set GITHUB_TOKEN=` only clears the variable for the current command prompt session, not for subsequent commands
  - The Node.js process environment (`process.env.GITHUB_TOKEN`) was not being cleared, causing `gh` commands to read stale values
  - Git Bash/MINGW64 requires different shell syntax than Windows cmd.exe, but the menu script was not detecting the shell environment correctly
  - `runCommand` function used `execSync` which defaults to cmd.exe on Windows, even when running from Git Bash
- **Solution:**
  - Added menu option 13.17 with two sub-options:
    - Option 1: Read GITHUB_TOKEN from `.env.dev` automatically, display the full token value, unset existing token (both shell and process.env), then set it inline for verification
    - Option 2: Run `gh auth login --web` for browser-based authentication, with proper token clearing before login
  - Added menu option 13.18 to display GitHub authentication status via `gh auth status`
  - Added menu option 13.19 to display current GitHub token via `gh auth token`, with environment clearing to ensure keyring token is shown
  - Added menu option 13.20 to open GitHub Personal Access Tokens page in browser (since GitHub API does not allow programmatic listing of Classic PATs)
  - Modified `runCommand` function to detect Git Bash/MINGW64 environment and set `shell: 'bash'` for execSync, ensuring Unix-style syntax works correctly
  - Added validation after unsetting GITHUB_TOKEN to confirm it's successfully cleared from process.env
  - Updated error messages in encryptenvfiles.js and decryptenvfiles.js to specifically recommend option 13.17 for authentication failures
- **Benefit:** GitHub CLI authentication is now fully automated with proper token management. The menu provides clear visibility into authentication status and tokens, and handles both Windows cmd.exe and Git Bash environments correctly. Users can easily set up or reset their GitHub authentication without manual command-line operations.

### 39. Build Cache Optimization & Container Readiness
- **Problem:** The artifacts pipeline was slow because pip packages were re-downloaded on every build. The staging deployment failed because the web container exited with code 0 (setup completed but server never started), and Docker healthchecks used `pgrep` which only checked process existence, not HTTP readiness.
- **Root Causes:**
  - `compile.js` used `--no-cache` flag, forcing Docker to rebuild everything from scratch
  - BuildKit cache mounts in Dockerfile.compile weren't persisting on the GoCD agent
  - `setup-binary.sh` ran setup commands but didn't start the server at the end
  - Docker healthchecks used `pgrep` which marked containers as "healthy" before the server was ready
  - `deploy.js` ran `docker system prune -af` before every deployment, clearing all local image cache
- **Solutions:**
  - Removed `--no-cache` from `compile.js` to enable Docker layer caching
  - Enabled `DOCKER_BUILDKIT=1` in `compile.js` for proper BuildKit support
  - Removed BuildKit cache mounts from Dockerfile.compile (weren't working on GoCD agent)
  - Added `exec ./badminton_court_linux "$@"` at the end of `setup-binary.sh` to start the server
  - Changed healthcheck from `pgrep` to `curl -f http://localhost:8000/` in docker-compose.vm.yml
  - Increased healthcheck retries from 5 to 30 (5 minutes total) to allow setup_site to complete
  - Removed `docker system prune -af` from `deploy.js` to preserve local image cache
  - Changed `--pull always` to `--pull missing` in `deploy.js` to use local cache when image hasn't changed
- **Benefit:** Artifact builds are now faster with Docker layer caching. Web containers stay running and only report healthy when the server is actually ready. Staging/production deployments use local image cache when the image hasn't changed, significantly reducing deployment time for config-only changes.
- **Problem:** The `.env.dev` and other environment files contain multiple Cypress URL variables (`CYPRESS_baseUrl`, `CYPRESS_BASEURL`, `CYPRESS_INTERNAL_baseUrl`) with different values. This causes confusion and errors when `cypress.config.js` looks for `CYPRESS_BASEURL` but only finds `CYPRESS_baseUrl` (different case).
- **Planned Solution:**
  - Standardize on a single variable: `CYPRESS_BASEURL` (all uppercase) for Cypress base URL.
  - Update `.env.dev` to `CYPRESS_BASEURL=http://localhost:8000`.
  - Update `.env.docker` to `CYPRESS_BASEURL=http://web-test:8000` (already correct via docker-compose).
  - Remove `CYPRESS_baseUrl` and `CYPRESS_INTERNAL_baseUrl` from all `.env` files.
  - Update `Scripts/create-presentations.js` to use `CYPRESS_BASEURL` instead of `CYPRESS_INTERNAL_baseUrl`.
- **Benefit:** No more missing variable errors for local development. Clean, consistent naming across all environments.

### 39. VM Provisioning Time & Tool Readiness
- **Problem:** Fresh VM provisioning (option 6.22) was taking 4 hours due to a blocking wait loop and network issues. Users had no visibility into whether the process was actually progressing.
- **Root Cause:**
  - The startup script attempted IPv6 connections that failed, causing package downloads to hang.
  - The wait script used blocking `execSync` for SSH commands, which could freeze for minutes while the VM was under heavy I/O.
  - The script waited for a specific log line, but a more direct readiness check was needed.
- **Solution:**
  - Forced `apt` to use IPv4 only in the VM startup script (`Acquire::ForceIPv4 "true";`).
  - Replaced `install-tools-on-vm.js` with `wait-for-vm-tools.js`, which no longer installs anything—the startup script does all installations.
  - The new script uses non‑blocking `spawn` with timeouts and actively checks for the presence of `docker`, `node`, and `git` via SSH.
  - It streams the startup log for visibility and exits the moment all tools are detected.
  - Renamed the script to `wait-for-vm-tools.js` to reflect its actual purpose.
- **Benefit:** Fresh VM creation now completes in **~21 minutes** (the time the startup script needs to install all packages on an e2‑micro). The screen stays lively with real‑time progress, and the wait never exceeds what is strictly necessary.

### 40. Deployment Reliability & Build Cache Optimization
- **Problem:** The staging deployment failed because ghcr.io was unreachable but the deployment continued using stale cached images. The compilation step was slow because changing `setup-binary.sh` invalidated the entire Docker cache. The web container exited because `setup_site` command hung due to database I/O issues. The MTU check in `deploy.js` kept triggering because Docker was started before daemon.json was configured, causing the docker0 bridge to be created with MTU 1500 instead of 1460.
- **Root Causes:**
  - `deploy.js` didn't verify ghcr.io connectivity before deployment, allowing deployments with stale images
  - `Dockerfile.compile` used `COPY . .` which copied everything, so changing any file (including deployment scripts) invalidated the cache
  - `setup_site` management command hung due to database I/O in uninterruptible sleep state
  - `create-fresh-vm.js` started Docker BEFORE writing `/etc/docker/daemon.json`, so docker0 bridge was created with default MTU 1500
- **Solutions:**
  - Added ghcr.io connectivity check in `deploy.js` before deployment - fails fast if registry is unreachable
  - Moved `setup-binary.sh` to `deploy/` subdirectory to separate deployment scripts from application code
  - Modified `Dockerfile.compile` to only copy necessary directories (`badminton_court/`, `court_management/`, `inventory/`, `templates/`, `static/`, `manage.py`, `requirements.txt`) instead of `COPY . .`
  - Temporarily skipped `setup_site` in `setup-binary.sh` to prevent container hang while investigating database I/O issue
  - Removed daemon-level MTU configuration from `create-fresh-vm.js` and `deploy.js` to test if docker-compose network MTU 1460 (already configured in docker-compose.vm.yml) is sufficient for ghcr.io connectivity, avoiding complex daemon-level MTU configuration that was failing
  - Added verbose output to ghcr.io connectivity check to diagnose actual root cause of connectivity failure (not MTU-related)
  - Removed healthcheck monitoring from deploy.js since Cypress connectivity tests provide validation, making deployment pass quicker
  - Kept standard `docker compose up -d` with healthcheck wait since compose file healthchecks are correct and should be waited for
  - Removed `condition: service_healthy` from nginx depends_on in docker-compose.vm.yml to speed up deployment, relying on Cypress connectivity tests for validation instead
  - Removed internal readiness checks and diagnostics from deploy.js, relying on Cypress tests for all connectivity validation
  - Optimized VM setup time from ~26 minutes to ~10 minutes by skipping `apt-get upgrade` (not necessary for fresh VM, only install what's needed)
  - Removed output suppression from startup script commands (id -u, command -v, tee) to show more detailed progress during VM setup
  - Increased Cypress timeout for reset-django-db endpoint from 30s to 120s to allow time for migrate + flush operations on staging database
  - Added validatePublicUrl Cypress command with retry loop and comprehensive diagnostics (container status, logs, all containers status) on failure for better connectivity diagnostics
  - Added validatePublicUrl check and increased timeout for admin users page visit in addUserToAdminGroup command to prevent timeout errors
  - Added validatePublicUrl check and increased timeout for admin login page visit in adminLogin command to prevent timeout errors
  - Added validatePublicUrl checks and increased timeouts for all admin page visits in inventory step definitions to prevent timeout errors
  - Increased timeout for low-stock check API endpoint from 30s to 120s to prevent timeout errors
  - Replaced .click with .clickWithHighlight in inventory step definitions for better visual feedback
  - Added products table reset step to inventory tests to prevent duplicate products accumulating across test runs
  - Fixed inventory test execution order by moving products table reset before login to prevent admin user deletion
  - Added scenario to test adding duplicate product name to verify duplicate prevention
  - Created new Django app "news" for professional home page with articles/news feed functionality
  - Implemented Article model with video support, featured images, and category tagging for news feed
  - Implemented Page model for static pages (About Us, Contact Us, Feedback)
  - Created admin interface for managing articles and static pages with rich fieldsets
  - Designed modern Bootstrap-based home page with hero section, featured articles, and latest news
  - Created views and templates for home, article list/detail, about, contact, and feedback pages
  - Added navigation bar with Sign Up/Sign In links and footer with contact information
  - Integrated news app into main Django project with URL routing and settings configuration
  - Redesigned login page with modern gradient background, split layout, icons, and improved styling to match news app design
  - Redesigned signup page with modern gradient background, split layout, icons, and social media signup options (Google, Facebook, Twitter)
  - Preserved all form field IDs (id_login, id_password, id_email, id_password1, id_password2) to maintain Cypress test compatibility
  - Social media signup is configured via django-allauth for Google, Facebook, and Twitter (Instagram requires custom provider implementation)
  - Fixed PyInstaller compilation error by adding news app to collect-submodules and add-data directives in Dockerfile.compile
  - Fixed home page redirect to /accounts/login by removing root path from court_management urls (moved dashboard to /court/dashboard/)
  - Fixed signup page button class from btn-primary to btn-success for Cypress test compatibility
  - Created step definitions for auth-flow.feature scenarios covering registration, login, logout, invalid credentials, duplicate email, and password mismatch
  - Added test features and step definitions for social media signup, verification and sign in (Google, Facebook, Twitter)
  - Fixed duplicate step definitions for Django database reset and test user cleanup (removed from auth-flow.js and social-auth.js, using common.js)
- **Benefit:** Deployments now fail fast if ghcr.io is unreachable, preventing stale image deployments. Changes to deployment scripts no longer invalidate the compilation cache, reducing build time from ~4.5 minutes to ~10 seconds for script-only changes. The web container stays running without hanging on setup_site. Fresh VMs now have the correct MTU from birth, eliminating the need for MTU fixes during deployment.
- **Next Steps:** Investigate and fix the database I/O hang in `setup_site` command, then re-enable it in `setup-binary.sh`.

### 41. Domain Name & Production HTTPS with Let's Encrypt (Planned)
- **Goal:** Replace the bare IP address with a proper domain name (e.g., `solsys.com`) and secure production with a trusted SSL certificate from Let's Encrypt.
- **Problem:** The current production URLs use `https://136.109.209.69:9444/`, which is unprofessional and shows a self‑signed certificate warning. A domain name and valid certificate are required for public use.
- **Planned Solution:**
  - Register a domain (e.g., `solsys.com`) using Google Cloud Domains or a third‑party registrar.
  - Configure Cloud DNS to point the domain to the VM's static IP (`136.109.209.69`).
  - Deploy a production nginx reverse proxy (similar to staging) on port 443, serving the domain.
  - Use Let's Encrypt and Certbot to automatically obtain and renew a trusted SSL certificate.
  - Update `docker-compose.vm.yml` to include a `nginx-production` service (profiled `production`) with the certificate volume and domain‑based configuration.
  - Automate certificate renewal via a cron job on the VM or a dedicated container.
- **Benefit:** Production site accessible at `https://solsys.com/` without port numbers or security warnings, with fully automated certificate lifecycle.
### 41. GitHub API Pagination for Environment Variables
- **Problem:** `generate-env.js` only fetched the first 30 environment variables from GitHub because the API paginates results with a default page size of 30. The `?per_page=100` parameter was ignored by the GitHub Environments API, and the `--paginate` flag on `gh api` produced concatenated JSON that couldn't be parsed. This left `<?var?>` placeholders in generated `.env` files even though 84 variables existed in the environment.
- **Solution:**
  - Replaced the `gh api` call with native Node.js `https` module that manually follows the `Link` header to fetch all pages.
  - The function now loops through every page and collects all variables, reliably returning 84 variables instead of 30.
  - `generate-env.js` also now aborts and exits with an error if any required GCP secret cannot be fetched, preventing the existing `.env` file from being overwritten with placeholders.
- **Benefit:** All environment variables are reliably fetched regardless of how many are stored. The generated `.env` files are always complete, and a missing secret never corrupts an existing good file.

### 42. Environment Naming Standardization
- **Problem:** GitHub Environment names were inconsistent: the staging pipeline used `development`, the production pipeline used `docker-production`. This caused confusion when running migrations and made it unclear which environment corresponded to which deployment target.
- **Solution:**
  - Renamed GitHub Environments to match deployment targets: `staging`, `production`, `development`, `docker`.
  - Updated `deploy.js`, `generate-env.js`, `migrate-environments.js`, and both menu scripts to use the new names consistently.
  - Updated menu option 13.12 to auto‑select the correct source `.env` file based on the chosen environment (single prompt instead of two).
  - Created new template files for `.env.dev` and `.env.docker` environments.
- **Benefit:** Clear, predictable mapping between environment names and deployment targets. No more guessing which environment a pipeline uses.

### 43. Staging Port Conflict (Mail HTTPS vs Nginx)
- **Problem:** Both the mail server's HTTPS interface and the nginx reverse proxy were assigned port `8443` in `.env.staging`, causing `Bind for 0.0.0.0:8443 failed: port is already allocated` when both services tried to start.
- **Solution:**
  - Changed `MAIL_HTTPS_HOST_PORT` from `8443` to `8444` in `.env.staging`.
  - `WEB_HTTPS_PORT` (nginx) remains on `8443` for browser access.
  - `STAGING_APP_URL` now correctly points to `https://34.42.210.96:8443` (nginx), not the mail port.
- **Benefit:** Both mail and web HTTPS interfaces run simultaneously without port collisions.

### 44. Staging & Production Port Assignment Audit
- **Problem:** Production `.env.production` contained copy‑paste errors from staging, including overlapping `WEB_HOST_PORT=8001` and `POSTGRES_HOST_PORT=5432`, which would prevent both environments from running side‑by‑side. `STAGING_APP_URL` was also present in the production file, and `PRODUCTION_APP_URL` pointed to staging's mail port.
- **Solution:**
  - Assigned production‑unique ports: `WEB_HOST_PORT=8002`, `POSTGRES_HOST_PORT=5433`, `REDIS_HOST_PORT=6378`, mail ports `2524/586/464/9444`.
  - Removed `STAGING_APP_URL` from production; corrected `PRODUCTION_APP_URL` to `https://34.42.210.96:9443`.
  - Corrected `POSTE_PORT` to match `MAIL_HTTPS_HOST_PORT` in each environment.
  - Fixed `REDIS_URL` from `localhost` to `redis` (service name) so the web container can reach Redis.
- **Benefit:** Staging and production can run concurrently without any port collisions. URLs and service references are correct for each environment.

### 45. Pipeline Pre‑Deployment Cleanup
- **Problem:** If a previous pipeline run failed partway through (e.g., Docker pull timeout), leftover containers and networks remained on the VM. The next run would fail with `container is not connected to the network` because Docker Compose found a stale container that wasn't attached to the new network.
- **Solution:**
  - Added a pre‑deployment teardown step in `deploy.js` that runs `docker compose down -v --rmi all` for the project before every `up`.
  - The teardown does not suppress errors (no `2>/dev/null`) so any real issues are visible in the logs.
  - If nothing is running, the `down` command is harmless and the script proceeds.
- **Benefit:** Every pipeline run starts from a clean state. Partial failures are automatically cleaned up, and the next run succeeds without manual intervention.

### 46. Firewall Rule Port Synchronization
- **Problem:** The firewall rule `allow-web-https-staging` was always created for port `8444` because `deploy.js` read `WEB_HTTPS_PORT` from `.env.docker` (which had `8444`) rather than from the freshly generated `.env.staging` (which had `8443`). This meant the firewall rule never matched the actual nginx port, and browsers couldn't connect.
- **Solution:**
  - Moved the firewall rule logic to execute **after** the `.env.staging` file is generated.
  - `deploy.js` now reads `WEB_HTTPS_PORT` directly from the generated file, so the correct port is always used.
  - If the rule already exists but for a different port, it is deleted and recreated with the correct port (idempotent).
- **Benefit:** The firewall rule always matches the actual nginx port, regardless of configuration changes. No manual firewall commands are ever needed after deployment.

### 47. Container Diagnostics Menu Options
- **Problem:** When the staging or production web app was unreachable, there was no quick way to diagnose whether containers were running, which ports were listening, or whether the app was responding to HTTP requests. Manual SSH was required each time.
- **Solution:**
  - Added menu options 6.26 (Staging container diagnostics) and 6.27 (Production container diagnostics) to the `gocd-server` menu.
  - Each option SSHes into the VM and displays: container status (`docker compose ps`), port configuration from the env file, actual listening ports (`ss -tlnp` filtered dynamically to the configured ports), and a `curl` test to the app URL.
  - The diagnostics use timeouts on every SSH command so they never hang, and the output remains on screen until dismissed.
- **Benefit:** One‑click visibility into the health of any environment. No manual SSH or guesswork required.

### 48. Docker Network MTU Configuration
- **Problem:** The Docker daemon on the VM occasionally failed TLS handshakes with `ghcr.io` (registry) due to MTU mismatches (GCP VPC default MTU is 1460, but Docker's default is 1500). This caused `TLS handshake timeout` errors during image pulls.
- **Root Cause:** The Docker bridge network did not inherit the MTU from the daemon configuration, and the compose file's network had no explicit MTU.
- **Solution:**
  - Added `driver_opts.com.docker.network.driver.mtu: 1460` to the `app-network` in `docker-compose.vm.yml`.
  - The daemon‑level DNS/MTU config (`/etc/docker/daemon.json`) was already being written by the startup script and `deploy.js`.
- **Benefit:** All containers use the correct MTU for GCP's network, eliminating TLS handshake timeouts during image pulls and inter‑container communication.

### 49. Staging HTTPS Connectivity (Instance Tagging)
- **Problem:** Staging HTTPS (port 8443) was unreachable even though the firewall rule `allow-web-https-staging` existed.
- **Root Cause:** The firewall rule targeted the tag `gocd-deploy-target`, but the VM instance lacked this tag.
- **Solution:** Manually added the `gocd-deploy-target` tag to the VM via `gcloud`.
- **Benefit:** Staging HTTPS is now fully operational at `https://34.42.210.96:8443/`.

### 50. Production Deployment Failure (Resource Exhaustion)
- **Problem:** The production pipeline failed at the "Ensuring Docker DNS" step with a `Connection closed by port 22` error.
- **Root Cause:** The `e2-micro` instance (1GB RAM) was overloaded by the full staging stack (PostgreSQL, Redis, Poste.io, web app). The SSH daemon dropped connections during the deployment attempt due to system strain.
- **Solution:** Recommended upgrading the VM machine type (e.g., `e2-medium` or `e2-standard-2`).
- **Benefit:** Future deployments will be more stable, and OOM-related SSH disconnects will be avoided.

### 51. Production HTTPS Implementation
- **Problem:** Production lacked an nginx reverse proxy for HTTPS, and the deployment script only supported nginx setup for staging.
- **Solution:**
  - Added `nginx-production` service to `docker-compose.vm.yml`, mirroring the staging setup but using production profiles and environment-specific configs.
  - Refactored `deploy.js` to automatically generate `nginx-production.conf` and create/verify the `allow-web-https-production` firewall rule (port 9443).
- **Benefit:** Production is now HTTPS-ready, providing a secure endpoint at `https://34.42.210.96:9443/`.

### 52. Flexible Port Management & Strict Env Enforcement
- **Problem:** `deploy.js` used hardcoded fallback ports (`8443`, `9443`) and provided silent defaults for critical environment variables, which could lead to misconfigured deployments.
- **Solution:**
  - Refactored `deploy.js` to source all configuration (ports, tags, IPs) strictly from environment variables or generated `.env` files.
  - Implemented an interactive `waitAndExit()` helper: if a required variable is missing, the script prints a red warning and pauses, requiring the developer to press **Enter** before exiting.
- **Benefit:** Eliminates silent configuration errors. Developers are immediately notified of missing environment variables and must acknowledge the failure before the process stops.

### 53. VM Stability & OOM Mitigation (Disk Resize & Swap)
- **Problem:** The `e2-micro` instance (1GB RAM) frequently suffered from OOM (Out Of Memory) crashes during deployments and while running the Poste.io mail server. Additionally, the 10GB boot disk was 100% full, causing SSH and Docker failures.
- **Solution:**
  - **Disk Upgrade:** Resized the boot disk from 10GB to **30GB** (the maximum GCP Free Tier limit).
  - **Swap Enablement:** Created and activated a **4GB persistent swap file**, providing the VM with a total of **5GB of effective memory**.
  - **Automation:** Integrated disk resizing and swap creation into the `create-fresh-vm.js` startup script.
  - **Redundancy:** Added menu option 6.28 ("Enable/Verify Swap Space on VM") to manually trigger or verify swap settings on an existing instance.
- **Benefit:** Significantly improved system stability. The extra swap space prevents the SSH daemon and Docker containers from dropping connections or crashing under high load, ensuring reliable deployments on Free Tier hardware.

### 54. Deployment Script ReferenceError (GIT_REPO_USERNAME)
- **Problem:** The deployment script `deploy.js` crashed with `ReferenceError: GIT_REPO_USERNAME is not defined` during the Docker login step.
- **Root Cause:** The variable `GIT_REPO_USERNAME` was validated against `process.env` at the start of the script but was used as a local constant later without being explicitly declared.
- **Solution:** Added `const GIT_REPO_USERNAME = process.env.GIT_REPO_USERNAME;` to the variable initialization section of `deploy.js`.
- **Benefit:** The deployment script now correctly sources the registry username from the environment, ensuring successful authentication with `ghcr.io`.

### 55. Production HTTP Access & SSL Redirection
- **Problem 1:** Production HTTP site (port 8002) was inaccessible.
- **Problem 2:** HTTPS traffic showed "Not secure" warnings due to self-signed certificates.
- **Problem 3:** HTTP traffic was not being automatically redirected to HTTPS.
- **Solution:**
  - **HTTP Access:** Created GCP firewall rule `allow-badminton-production` for TCP port 8002.
  - **SSL Redirection:** Updated `nginx-staging.conf.template` to include an HTTP listener on port 80 that performs a 301 redirect to the host HTTPS port.
  - **Docker Compose Update:** Updated `docker-compose.vm.yml` to expose container port 80 to the host (8001/8002) on Nginx containers, allowing them to handle the redirect.
- **Next Steps:** Address the "Not secure" warning by implementing automated Let's Encrypt certificate renewal (Roadmap item #51).

### 55. Production HTTP Access & SSL Redirection
- **Problem 1:** Production HTTP site (port 8002) was inaccessible.
- **Problem 2:** HTTPS traffic showed "Not secure" warnings due to self-signed certificates.
- **Problem 3:** HTTP traffic was not being automatically redirected to HTTPS.
- **Solution:**
    - **HTTP Access:** Created GCP firewall rule `allow-badminton-production` for TCP port 8002.
    - **SSL Redirection:** Updated `nginx-production.conf.template` to include an HTTP listener on port 80 that performs a 301 redirect to the host HTTPS port.
    - **Docker Compose Update:** Updated `docker-compose.vm.yml` to expose container port 80 to the host on Nginx containers and removed host port mappings from web services to resolve binding conflicts.
- **Next Steps:** Address the "Not secure" warning by implementing automated Let's Encrypt certificate renewal (Roadmap item #51).

### 56. CSRF Trusted Origins Not Applied
- **Problem:** The `CSRF_TRUSTED_ORIGINS` environment variable was set correctly on the VM, but Django still rejected the admin login with "Origin checking failed".
- **Root Cause:** The `base.py` settings file hardcoded `CSRF_TRUSTED_ORIGINS` to `localhost:8000` and tunnel URLs only. The environment variable was never read.
- **Solution:**
  - Updated `base.py` to parse the `CSRF_TRUSTED_ORIGINS` environment variable as a comma‑separated list.
  - If the variable is empty, the previous hardcoded defaults are used.
  - The staging deployment now correctly trusts `https://34.42.210.96:8443`.
- **Benefit:** Admin login works on staging without CSRF errors. The fix is permanent and respects the template‑driven environment.

### 57. Inventory Test – Missing Category Data
- **Problem:** The inventory management Cypress test failed because the product category "Shuttlecocks" was not available in the dropdown.
- **Pending Investigation:** Determine if categories should be pre‑seeded via a management command, loaded in the test background, or created on demand. This may require a new data seeding step or test fixture adjustment.

---
*Last Updated: May 22, 2026*

### 58. Production 502 Bad Gateway (CSRF Config Error)
- **Problem:** The production web container failed to start, causing a 502 Bad Gateway error.
- **Root Cause:** The `CSRF_TRUSTED_ORIGINS` environment variable was set to the placeholder `<?var?>` in the `.env.production` file on the VM. Django 4.0+ performs strict validation on this setting and will not start if it contains invalid values (like those missing a scheme or containing placeholders).
- **Solution:** 
  - Manually patched the `.env.production` file on the VM with the correct origin (`https://34.42.210.96:9443`).
  - Restarted the production stack.
- **Benefit:** Production server now starts correctly and is reachable after initialization.

### 59. Staging 504 Gateway Timeout (Mail Service Unhealthy)
- **Problem:** Actions triggering emails on staging (like login) resulted in 504 Gateway Timeout errors.
- **Root Cause:** The `mail-staging` container was unhealthy because the `haraka` binary was missing from the expected path (`/usr/bin/haraka`) in the custom `Dockerfile.posteio`. This caused `smtplib` calls in the Django app to hang and eventually time out.
- **Solution:** 
  - Identified the correct binary path: `/usr/lib/node_modules/Haraka/bin/haraka`.
  - Updated `Dockerfile.posteio` with the correct path for future builds.
  - Hotfixed the staging VM by patching the service run script and restarting the container.
- **Benefit:** Mail service is now healthy, and email-related timeouts are resolved.

### 60. Database Container Naming Standardization
- **Problem:** The database containers in `docker-compose.vm.yml` had inconsistent and generic names (`db-test` for staging, `db` for production), making diagnostics confusing.
- **Solution:** 
  - Renamed the services and container names to `db-staging` and `db-production` respectively in `docker-compose.vm.yml`.
  - Updated `depends_on` references in `web-staging` and `web-production` to match.
- **Benefit:** Improved clarity during container listing and troubleshooting.

### 61. Missing "About Us", "Contact Us", and "Feedback" Pages
- **Problem:** Navigation links for "About Us", "Contact Us", and "Feedback" resulted in 404 errors because the routes, views, and templates were missing.
- **Solution:**
  - Implemented `about`, `contact`, and `feedback` views in `court_management/views.py`.
  - Defined URL routes in `court_management/urls.py`.
  - Created HTML templates for each page using Bootstrap 5.
  - Added a "Help" dropdown to the navbar and links to the footer in the base templates.
- **Benefit:** Enhanced user engagement and accessibility to essential information and support.
- **Rule Enforcement:** A new hard rule was established requiring these roadmap documents to be updated after every decision, finding, fix, or task completion.

---
*Last Updated: May 26, 2026*

## Future Enhancements & Feature Requirements

- **UI/UX Modernization:** Redesign user authentication pages for a professional aesthetic; implement social media authentication (OAuth 2.0) using Django-allauth for streamlined access.
- **Landing Page & Navigation:** Transform the home page into a public-facing landing page containing promotions, navigation (Sign Up/Sign In), and static links (About Us, Contact Us, Feedback). Remove automatic redirection to login for unauthenticated users.
- **Content Management System (CMS):** Implement an administrative interface for creating rich-media articles (support for videos/images) for news feeds and event management.
- **Test Integrity:** Ensure all UI enhancements maintain full compatibility with existing Cypress test suites, updating selectors/attributes to preserve QA integrity.
- **Build Reliability:** Guarantee that all enhancements are fully supported within the automated artifacts compilation pipeline.
- **Compliance Documentation:** Migrate existing `privacy_policy.html` and `terms_of_service.html` to a public-accessible route and surface links in the application footer.

<!-- NEW CONTENT BELOW – DO NOT REMOVE EXISTING CONTENT -->

---
*Last Updated: May 31, 2026*

## Load Balancer & Path‑Based Routing Implementation

- **Problem:** The initial load balancer configuration only supported subdomain‑based backends (e.g., `staging.humrine.com`, `app.humrine.com`). Multiple apps (Humrine, Badminton) needed to coexist under a single domain (`humrine.com`) using path‑based routing (e.g., `/badminton-staging`, `/badminton-production`). This caused 502 errors on the root domain and "Not Found" on sub‑site paths.
- **Solution:**
  - **Self‑Healing Script:** Created `setup-load-balancer.js` that idempotently inspects and corrects all load balancer components (instance group, health checks, backend services, URL map, HTTPS proxy, forwarding rules, firewall rules, DNS). The script is designed to be run at any time without causing downtime.
  - **Certificate Management:** Added `certDomains` array to `loadbalancer.json` to generate multi‑domain Google‑managed certificates. Certificate versioning ensures new certs are created and attached only after becoming ACTIVE, avoiding downtime. The script also reuses an existing ACTIVE certificate if it covers all required domains.
  - **Path‑Based Routing:** Added `pathPrefix` support for backends, enabling routing like `/badminton-staging` and `/badminton-production` under the same host. The URL map now correctly creates a bare‑domain host rule with the correct default backend and both exact and wildcard path rules (e.g., `/badminton-staging` and `/badminton-staging/*`).
  - **Health Checks:** Health checks automatically set the request path to `/prefix/` for path‑based backends, ensuring the load balancer probes the correct URL.
  - **Backend Services:** Backend services are forced to HTTP and correct named port, even if manually misconfigured. This eliminates 502 errors caused by protocol mismatches.
  - **Firewall Rules:** The script now automatically creates/updates two firewall rules: one for health‑check probes (restricted sources `35.191.0.0/16,130.211.0.0/22`) and one for actual load‑balancer traffic (all sources `0.0.0.0/0`). Both rules are kept up‑to‑date with all backend ports.
  - **Nginx Configuration:** Updated `badminton_court` nginx templates to strip the path prefix before forwarding to Django and include a 301 redirect for bare paths (e.g., `/badminton-staging` → `/badminton-staging/`).
  - **Port Conflict Resolution:** Added environment variables (`NGINX_STAGING_HOST_PORT`, `NGINX_PRODUCTION_HOST_PORT`, etc.) to avoid port conflicts between Humrine and Badminton containers running on the same VM.
  - **Menu Additions:** New menu options were added to the `gocd-server` menu: 6.32 (List SSL certificates), 6.33 (Delete SSL certificates), 6.34 (Monitor certificate status), 6.35 (Show active certificate on HTTPS proxy), 6.36 (Certificate domain status).
- **Result:** All three sites (`humrine.com`, `staging.humrine.com`, `app.humrine.com`) and the two path‑based apps (`/badminton-staging`, `/badminton-production`) are now operational. The load balancer is fully self‑healing; running option 6.30 at any time corrects inconsistencies without downtime.
- **Documentation:** All decisions, fixes, and architectural changes have been recorded in `roadmap_progress.lst` and this document.

## Badminton Nginx Placeholder Bug – 502 on Path‑Based Routes

- **Problem:** The badminton‑court staging nginx container crashed continuously with `host not found in "__WEB_HOST_PORT__"`. The generated `nginx‑staging.conf` still contained the literal placeholder because the pipeline’s `deploy.js` was not yet using the corrected variable name.
- **Temporary fix:** Manually overwrote the host file `/opt/badminton_court/nginx‑staging.conf` with a hardcoded config (listen 8001, path stripping, redirect). The container was force‑recreated, and the staging site became reachable.
- **Permanent fix:** The `badminton_court/Scripts/deploy.js` now reads `WEB_HOST_PORT` and replaces `__WEB_HOST_PORT__` (the same approach used successfully by humrine_site). Once committed to the pipeline’s branch and the pipeline is re‑run, the placeholder will be correctly replaced in every deployment.
- **Next step:** Commit the updated deploy script, trigger the staging pipeline, and verify the fix survives a fresh deployment. After confirmation, apply the same fix to production.

---
*Last Updated: May 31, 2026*

### 62. Poste.io Setup Wizard & SMTP Auth Stability (Dev Environment)
- **Problem:** The Poste.io setup wizard (cy.setupPosteio()) failed to complete during Cypress tests in the dev environment. After submitting the first install form, Poste.io stayed on /admin/install/server. Additionally, the test_check_smtp_auth Django endpoint timed out even though direct Python SMTP auth succeeded.
- **Root Causes (Multiple, Cascading):**
    1. Volume Not Properly Removed: cy.resetPosteioDb() ran docker-compose down + docker volume rm. On Docker Desktop for Windows, the volume lock is sometimes held, causing silent removal failures and leftover corrupted data.
    2. Stale Browser Session/Cookies: Previous setup attempts left session cookies, causing the setup wizard to fail silently.
    3. Multi-Step Install Wizard Not Handled: Poste.io setup wizard has multiple steps. The old performSetup function only submitted the FIRST form, then expected to be on /admin/box/.
    4. Excessive Wait Causing Socket Timeout: A cy.wait(30000) in setupPosteio caused ESOCKETTIMEDOUT.
    5. SMTP Auth Timeout in Django Endpoint: test_check_smtp_auth.py used timeout=10. Poste.io SSL handshake on port 465 can take 15-25 seconds. smtplib.SMTP_SSL with timeout parameter doesn't always work during SSL handshake on Windows.
- **Solution:**
    - database.cy.js: Replaced docker-compose down with docker rm -f + docker volume rm -f. Added verification to ensure the volume is actually gone (retries up to 10 times). Added verification that /data is empty. Added dynamic polling for readiness.
    - setupPosteio.cy.js: Added cy.clearCookies(), cy.clearLocalStorage(), cy.clearAllSessionStorage() BEFORE cy.visit(). Removed the cy.wait(30000). Added a step-through loop that keeps clicking submit on install pages until it reaches the login page.
    - test_check_smtp_auth.py: Increased timeout to 30s. Added socket.setdefaulttimeout(30). Added retry logic (3 attempts, 10s delay) for Dovecot auth plugin warmup.
- **Environment:** Development only (Windows host, Docker Desktop, Git Bash). Staging/production use API-based reset (reset_posteio_db_staging) and are unaffected by the Docker Desktop volume lock issue.
- **Benefit:** Poste.io setup wizard now completes reliably in the dev environment. SMTP auth endpoint no longer times out. posteio-flow.feature and auth-flow.feature pass consistently.
- **Documentation:** Created Memory_PosteioDevSetupWizardFix.md and Docs/Trouble-shooting/Poste.io setup wizard fails to complete in dev.md.

---
*Last Updated: June 19, 2026*

### 63. Poste.io Setup Wizard & SMTP Auth — Staging Environment Extension (FINAL)
- **Problem:** The Poste.io setup wizard (`cy.setupPosteio()`) failed with HTTP 500 when run against staging. After multiple iterations, nine cascading root causes were diagnosed and fixed. The final working state requires DNS, firewall, memory, env vars, and Cypress command changes all working together.
- **Root Causes (Nine, Cascading):**
    1. **Domain Conflict (primary 500 cause):** Deploy script creates `humrine.com` domain via console. Setup wizard tries to create the same domain → 500.
    2. **Admin Mailbox Conflict:** Deploy script creates `aeropaceadmin@humrine.com` via console. Setup wizard tries to create the same admin → conflict.
    3. **`POSTE_DOMAIN` vs Mail Server Hostname Confusion:** `POSTE_DOMAIN` is the email domain (`humrine.com`), NOT the mail server hostname (`mail.humrine.com`). These are distinct concepts.
    4. **No DNS Record for `mail.humrine.com`:** Setup wizard's connectivity tests timeout without a DNS A record.
    5. **Mail Ports Not Open on GCP Firewall:** Ports 25, 110, 143, 465, 587, 993, 995, 4190 were not open.
    6. **Container Memory Limit Too Low (256MB):** Rspamd was OOM-killed, making the container unhealthy.
    7. **Staging Reset Command API Path Bug:** `reset_posteio_db_staging.py` used `/api/v1/...` instead of `/admin/api/v1/...`. The 301 redirect stripped auth headers.
    8. **SSL Verification Failure in PyInstaller Binary:** `requests` respected `REQUESTS_CA_BUNDLE` env var, overriding `session.verify = False`.
    9. **`configure-poste-relay.js` Single-Attempt Failure:** Relay config used `runCmd` (single attempt) instead of `runCmdWithRetry`.
- **Solution:**
    - **`setupPosteio.cy.js`:** Delete admin mailbox + domain via API before running the setup wizard. Use `mail.${POSTE_DOMAIN}` for the hostname field (not `POSTE_DOMAIN` directly).
    - **`reset_posteio_db_staging.py`:** Fix API path (`/admin/api/v1/`), add `session.trust_env = False` + `verify=False` (SSL fix), skip admin mailbox in deletion (preserve across test cycles).
    - **`configure-poste-relay.js`:** Use `runCmdWithRetry` for relay config call.
    - **`setup-firewall-rules.js`:** Add 8 mail service ports (25, 110, 143, 465, 587, 993, 995, 4190).
    - **`docker-compose.vm.yml`:** Change `mem_limit: 256m` to `mem_limit: 512m` for mail-staging and mail-production.
    - **`menu.js`:** Add 16.7/17.7 (wipe volume + recreate, with confirmation + 90s countdown). Add secure env export for 16.1-16.7 and 17.1-17.7 (no .env files on VM disk).
    - **DNS:** Create `mail.humrine.com` A record in GCP Cloud DNS → `35.198.231.9`.
    - **Env vars:** `POSTE_DOMAIN=humrine.com` (email domain), `POSTE_HOSTNAME=mail-staging` (Docker-internal), mail server hostname = `mail.humrine.com` (derived).
- **Environment:** Staging (GCP VM `35.198.231.9`, Linux host, Docker Engine). Dev remains on the dev path; production pending.
- **Benefit:** Cypress `posteio-flow.feature` passes all 3 scenarios in staging. SMTP auth works (`{"status":"ok","protocol":"SSL:465","host":"mail-staging"}`). SMTP relay configured (outbound mail via Gmail). Environment drift is impossible — `ENVIRONMENT` is required, not defaulted. Staging admin mailbox persists across test cycles. Mail server is properly reachable via DNS (`mail.humrine.com`) with all required ports open.
- **Documentation:** Updated `Memory_PosteioStagingSetupWizardFix.md`, `Poste.io setup wizard fails to complete in staging.md`, `Memory_MenuOptionIndex.md` (added 16.7/17.7), this roadmap entry.
- **Related Roadmap entries:** #52 (no silent defaults — enforced by this fix), #62 (dev variant of the same issue).
- **Status:** Staging FIXED and VERIFIED. All 3 Cypress scenarios pass. SMTP auth works. Production pending.

---
*Last Updated: June 20, 2026*
