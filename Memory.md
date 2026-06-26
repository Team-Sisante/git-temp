# MEMORY.md — AI Assistant Protocol & Project Index

## ⚠️ READ THIS FIRST
This repository (`git-temp`) serves as the central documentation hub for the entire project ecosystem. If you are an AI assistant (or human developer) working on this project, you must read this file completely before taking any action.

This project has suffered multiple incidents where AI assistants caused outages, corrupted configurations, or violated security protocols by "improvising" instead of following documented procedures. The rules and architectural decisions documented here exist to prevent those failures. If a documented procedure exists, it MUST be followed exactly.

---

## 🗺️ Project Architecture Overview

The project consists of multiple applications and infrastructure components managed via GoCD:

1. **badminton_court**: A Django-based application for managing badminton court bookings, inventory, and employees. Compiled into a standalone Linux binary via PyInstaller.
2. **humrine_site**: A Django-based application for an affiliate marketing/news site.
3. **gocd-server**: The GoCD Continuous Deployment server, agents, and pipeline configurations that build and deploy the applications to a GCP VM.
4. **pay-sol**: A payment solution application.
5. **solvpn**: A VPN application.

All applications are deployed to a single GCP VM (e2-small, 30GB disk, 4GB swap) using Docker Compose, behind a GCP Load Balancer with path-based routing.

---

## 📁 Documentation Map

### Central Memory Files (dev-infra/Docs/memory/)
- **Memory.md** — Index of all memory files
- **Memory_AIBehaviorSafetyProtocol.md** — Mandatory pre-action checks for AI assistants
- **Memory_AI_Deception_Incident–DeepSeek_Instant_Mode.md** — AI Deception Incedent about URL reading
- **Memory_BranchingStrategy.md** — No direct merges to master; PRs required
- **Memory_CrossPlatformCompatibility.md** — Path handling, venv activation, Docker Compose
- **Memory_DeploymentPattern.md** — Artifact promotion strategy (when to rebuild vs deploy)
- **Memory_DockerComposeEnvLoading.md** — Always use explicit --env-file flags
- **Memory_EncryptionWorkflow.md** — Never commit secrets; encrypt first
- **Memory_EnvFileConventions.md** — .env file structure and synchronization rules
- **Memory_GoCDInfrastructureSafety.md** — Never run option 1.6 (nuclear reset) unless specifically requested
- **Memory_PosteioArchitecture.md** — Poste.io uses SQLite; API is unstable
- **Memory_PosteioEmailIssues.md** — Relay settings in /data/server.ini, not database
- **Memory_PosteioDevSetupWizardFix.md** — Dev environment setup wizard fixes
- **Memory_MarkdownFormattingProtocol.md** — Use bash code blocks for sharing files
- **Memory_CodeBlockCopyProtocol.md** — Complete functions only, no shortcuts
- **Memory_UIBehaviorProtocol.md** — No new windows; display inline
- **Memory_URLs_of_git-temp_repo_files.md** — URLs of git-temp repo files

### Application Documentation
- **badminton_court/Docs/Roadmap_Environments.md** – Master roadmap (multi‑environment migration)
- **badminton_court/Docs/Decision-Log.md** – Architectural decisions (binary compilation, pipeline design, machine type)
- **badminton_court/Docs/Trouble-shooting/** – Troubleshooting guides (one per issue)
  - `Load Balancer & Path‑Based Routing.md`
  - `Poste.io Setup Wizard & SMTP Auth (Staging).md`
  - `Social Media App Configuration Menu.md`
  - `Database Permission Repair Automation.md`
  - `Load Balancer Health Check Host Headers.md`
  - `Deployment Script Image Tag Reliability.md`
  - `SMTP Check Timeout Fix.md`
  - `Cypress Environment Variable Resolution.md`
  - `court Path Routing Correction.md`
  - `User Profile Completion Notice.md`
  - `Troubleshooting Documentation Creation.md`
- **badminton_court/Docs/STARTTLS and SSL-SMTP ports.md** – Use port 465 (SMTPS) not 587
- **gocd-server/Docs/** – GoCD setup, deployment, and GCP hosting docs
- **humrine_site/Docs/** – Humrine site specific documentation (includes affiliate marketing roadmap)

---

## 🏆 The 11 Golden Rules

These rules are derived from incident reports and memory files. Violating them has caused outages and data loss in the past.

### 1. No Silent Defaults
Never use `|| 'default'` or `|| 'development'` for environment variables. Always validate explicitly and throw an error if missing. (Roadmap #52)

### 2. Surgical Changes Only
Never rewrite an entire file to make a small change. Modify only the specific lines that need changing. Preserve all existing comments, formatting, and coding style. (Memory_MenuRefactoringFailure.md)

### 3. Security First
Never print secrets, passwords, or tokens to the console. Always audit memory files before taking security-sensitive actions. Ask for user approval before destructive operations. (Memory_AIBehaviorSafetyProtocol.md)

### 4. Complete Code Blocks
When sharing code in chat, always provide complete functions or files. Never use `// ... rest of code` or `// ... existing code` inside code blocks. Place explanatory text outside the code block. (Memory_CodeBlockCopyProtocol.md)

### 5. No New Windows
Never open new windows, document panels, or external viewers. Display all content inline in the chat response. (Memory_UIBehaviorProtocol.md)

### 6. No Direct Merges to Master
All changes must go through a Pull Request. Never merge directly to master/main. This is enforced by GitHub Rulesets. (Memory_BranchingStrategy.md)

### 7. Explicit Environment Loading
Always use `docker compose --env-file .env.common --env-file .env.<env>` when running docker commands. Never rely on implicit loading. (Memory_DockerComposeEnvLoading.md)

### 8. Update Documentation After Changes
After any significant decision, fix, or task completion, update the roadmap documents and memory files. This is a hard rule. (Roadmap #61)

### 9. Never Run Option 1.6 (Nuclear Reset)
Menu option 1.6 runs `go.js` which executes `docker compose down -v` and `docker volume rm -f`, permanently deleting ALL pipeline history, configurations, and artifacts. Never advise running this unless specifically requested for a factory reset. (Memory_GoCDInfrastructureSafety.md)

### 10. Use Port 465 for SMTP
Poste.io's STARTTLS on port 587 is unreliable. Always use port 465 (SMTPS) with `EMAIL_USE_SSL=True`. This works out-of-the-box. (STARTTLS and SSL-SMTP ports.md)

### 11. Keep Roadmaps Concise
Roadmap documents track high‑level progress and architectural decisions. Detailed problem/solution histories belong in separate `Docs/Trouble-shooting/` files. Link to those files from the roadmap.
---

## 📦 ghcr.io (GitHub Container Registry) Management

The project uses `ghcr.io` to store built Docker images for all apps (e.g., `humrine_site-web`, `badminton_court-web`).

### Storage & Limits
- **Public images** (the default for this project) have **unlimited storage and unlimited pull bandwidth**.
- There is **no limit** on the number of tags (e.g., `sha-9bbe8e1`) you can push to a public repository.
- Old tags **never expire** and persist indefinitely unless manually deleted.

### Maintenance
- While there is no cost, it is recommended to occasionally clean up very old tags to keep the package list tidy and reduce confusion.
- Tags can be deleted via:
  - The GitHub UI: Packages → select package → click the version → Delete.
  - The GitHub API (using a `GITHUB_TOKEN` with `write:packages` scope).
- **Rule of thumb**: Keep the last 5–10 successful `sha-*` tags and any manually tagged `latest` versions. Delete older, unused builds.

### Command Example (List versions to delete)
```bash
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/user/packages/container/humrine_site-web/versions" \
  | grep -o '"id":[0-9]*' | cut -d: -f2
```
*(Be careful – deleting a tag removes that image permanently and cannot be undone.)*

## Note to AI Assistants: 
- **You need to remind the user about cleaning up the images.** 
- **Ask the user if he wants to do it now or when.**

## 🔗 Quick Reference Links

- [AI Behavior Safety Protocol](dev-infra/Docs/memory/Memory_AIBehaviorSafetyProtocol.md)
- [Branching Strategy](dev-infra/Docs/memory/Memory_BranchingStrategy.md)
- [Cross-Platform Compatibility](dev-infra/Docs/memory/Memory_CrossPlatformCompatibility.md)
- [Deployment Pattern](dev-infra/Docs/memory/Memory_DeploymentPattern.md)
- [Docker Compose Env Loading](dev-infra/Docs/memory/Memory_DockerComposeEnvLoading.md)
- [Encryption Workflow](dev-infra/Docs/memory/Memory_EncryptionWorkflow.md)
- [Env File Conventions](dev-infra/Docs/memory/Memory_EnvFileConventions.md)
- [GoCD Infrastructure Safety](dev-infra/Docs/memory/Memory_GoCDInfrastructureSafety.md)
- [Poste.io Architecture](dev-infra/Docs/memory/Memory_PosteioArchitecture.md)
- [Poste.io Email Issues](dev-infra/Docs/memory/Memory_PosteioEmailIssues.md)
- [Poste.io Dev Setup Wizard Fix](dev-infra/Docs/memory/Memory_PosteioDevSetupWizardFix.md)
- [Markdown Formatting Protocol](dev-infra/Docs/memory/Memory_MarkdownFormattingProtocol.md)
- [Code Block Copy Protocol](dev-infra/Docs/memory/Memory_CodeBlockCopyProtocol.md)
- [UI Behavior Protocol](dev-infra/Docs/memory/Memory_UIBehaviorProtocol.md)
- [Badminton Court Roadmap](badminton_court/Docs/Roadmap_Environments.md)
- [STARTTLS and SSL-SMTP Ports](badminton_court/Docs/STARTTLS%20and%20SSL-SMTP%20ports.md)
- [Badminton Court Decision Log](badminton_court/Docs/Decision-Log.md)
- [Badminton Court Trouble-shooting – Load Balancer & Path‑Based Routing](badminton_court/Docs/Trouble-shooting/Load%20Balancer%20&%20Path‑Based%20Routing.md)
- [Badminton Court Trouble-shooting – Poste.io Staging](badminton_court/Docs/Trouble-shooting/Poste.io%20Setup%20Wizard%20&%20SMTP%20Auth%20(Staging).md)
- [Badminton Court Trouble-shooting – Social Media App Config](badminton_court/Docs/Trouble-shooting/Social%20Media%20App%20Configuration%20Menu.md)
- [Badminton Court Trouble-shooting – DB Permission Repair](badminton_court/Docs/Trouble-shooting/Database%20Permission%20Repair%20Automation.md)
- [Badminton Court Trouble-shooting – LB Health Check Host Headers](badminton_court/Docs/Trouble-shooting/Load%20Balancer%20Health%20Check%20Host%20Headers.md)
- [Badminton Court Trouble-shooting – Deploy Script Image Tag](badminton_court/Docs/Trouble-shooting/Deployment%20Script%20Image%20Tag%20Reliability.md)
- [Badminton Court Trouble-shooting – SMTP Check Timeout](badminton_court/Docs/Trouble-shooting/SMTP%20Check%20Timeout%20Fix.md)
- [Badminton Court Trouble-shooting – Cypress Env Resolution](badminton_court/Docs/Trouble-shooting/Cypress%20Environment%20Variable%20Resolution.md)
- [Badminton Court Trouble-shooting – /court Routing](badminton_court/Docs/Trouble-shooting/court%20Path%20Routing%20Correction.md)
- [Badminton Court Trouble-shooting – Profile Completion Notice](badminton_court/Docs/Trouble-shooting/User%20Profile%20Completion%20Notice.md)
---

## 📝 Maintenance

This file must be updated whenever:
- A new memory file is created
- A new golden rule is established
- A new repository or major component is added
- The project architecture changes significantly