# Memory Detail: Menu Option Index

## Purpose
To provide a quick reference for AI assistants regarding the available menu options in each application's `Scripts/menu.js` file. This prevents the AI from asking the user to paste menu code repeatedly.

## Menus Overview

### 1. gocd-server Menu (`gocd-server/Scripts/menu.js`)
Focuses on GoCD infrastructure, GCP VM management, and pipeline control.
- **1.1 - 1.13:** Container Management (build, restart, reset GoCD server/agents)
- **2.1 - 2.4:** Pipeline Management (trigger, view history, unlock, cancel)
- **3.1 - 3.3:** Agent Management (view, enable, disable)
- **4.1 - 4.12:** System Utilities (encrypt/decrypt envs, open UI, resources, generate certs)
- **5.1 - 5.5:** Trouble-shoot Containers (rebuild specific containers)
- **6.1 - 6.37:** GCP VM Setup (create VM, firewall, SSH keys, load balancers, SSL certs, diagnostics)

### 2. badminton_court Menu (`badminton_court/Scripts/menu.js`)
Focuses on local development, testing, and environment management for the Django app.
- **1.1 - 1.5:** Local Development (start dev server, load test data, start tunnel)
- **2.1 - 2.4:** Cypress Testing (run tests headed/headless, open Cypress UI)
- **3.1 - 3.5:** Social Media Setup (configure Google/FB/Twitter apps)
- **4.1 - 4.12:** Django Management (create superuser, reset DB, compile binary)
- **5.1 - 5.5:** Docker Management (start/stop dev containers, rebuild)
- **6.1 - 6.5:** Remote Staging/Prod (start/stop remote containers, delete images)
- **7.1 - 7.5:** GCP VM (create, delete, export config - overlaps with gocd-server)
- **8.1 - 8.5:** GoCD Integration (trigger pipelines, view history - overlaps)
- **9.1 - 9.5:** Github Utilities (sync branches, PRs)
- **10.1 - 10.5:** Nuclear Reset Options (full dev environment wipes)
- **11.1 - 11.5:** Test Data Setup (load fixtures)
- **12.1 - 12.5:** Maintenance (clear cache, update site domain)
- **13.1 - 13.20:** Environment File Automation (generate, encrypt, migrate, validate)
- **14.1 - 14.5:** Git Utilities (commit, push, status)
- **15.1 - 15.5:** VM Diagnostics (SSH, check disk, view logs)

### 3. humrine_site Menu (`humrine_site/Scripts/menu.js`)
Similar structure to badminton_court, but tailored to the Humrine site. Includes specific options for affiliate marketing and link generation.
- **1.1 - 1.5:** Local Development
- **2.1 - 2.4:** Cypress Testing
- **3.1 - 3.5:** Social Media Setup
- **4.1 - 4.12:** Django Management
- **5.1 - 5.5:** Docker Management
- **6.1 - 6.5:** Remote Staging/Prod
- **7.1 - 7.5:** GCP VM
- **8.1 - 8.5:** GoCD Integration
- **9.1 - 9.5:** Github Utilities
- **10.1 - 10.5:** Nuclear Reset Options
- **11.1 - 11.5:** Test Data Setup
- **12.1 - 12.5:** Maintenance
- **13.1 - 13.20:** Environment File Automation (includes migrate to GCP/Github)
- **14.1 - 14.5:** Git Utilities
- **15.1 - 15.5:** VM Diagnostics
- **16.1 - 16.5:** Affiliate Marketing (generate deep links, manage involves)

### 4. dev-infra Menu (`dev-infra/Scripts/menu.js`)
This is a top-level "Workspace Launcher" that serves as a single entry point to launch any workspace menu in the repository.
- **1 - 7:** Select Workspace (gocd-server, badminton_court, pay-sol, pay-sol-tools, SolVPN, humrine_site, pearl-hello-world)
- **E:** Select/Change Target Environment (Staging, Production, Local Development, Docker)
- **0:** Exit

It automatically detects and activates Python virtual environments (`venv/Scripts/activate`) for the selected workspace before launching its specific `menu.js` script.

## Migration Scripts Note
The `generate-env.js` migration scripts (in `humrine_site` and `badminton_court`) are used to generate `.env.<env>` files from templates. They fetch `<?var?>` from GitHub Environments and `<?secret?>` from GCP Secret Manager.
- **Why it's not in gocd-server:** The `gocd-server` uses a manually maintained `.env.docker` file and does not use the template generation pipeline. Therefore, it does not need `generate-env.js`.
- **Use case:** When you add a new variable to an application's `.env.staging.template`, you must run the migration script (menu option 13.x in the app menus) to fetch the value from GitHub/GCP and generate the actual `.env.staging` file.

## Status
- Established: 2026-06-19
- Applies to: AI assistants needing to know what menu options exist without asking the user to paste code.