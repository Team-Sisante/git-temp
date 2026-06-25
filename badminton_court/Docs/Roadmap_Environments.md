<!-- AI ASSISTANT NOTE: Always refer to this document and update it as tasks are completed or architecture changes. Do not remove this note! Also do not remove the history of modifications. [HARD RULE] When editing, ALWAYS preserve ALL existing content. Only ADD new entries or UPDATE existing ones. NEVER delete or shorten the history.
[RULE] Every roadmap document MUST be updated by the engineer after any significant decision, finding, code fix, or task completion to ensure project state transparency.
[RULE] You should always update these roadmap documents on our decisions, findings, fixes and next tasks after doing the updates/changes/modifications.
[RULE] This roadmap document tracks architectural plans, decisions, and high‑level progress for the **multi‑environment migration of badminton_court** only. Detailed problem/solution write‑ups belong in the corresponding `Docs/Trouble-shooting/` documents. Keep entries concise; link to the relevant trouble‑shooting file for full context.
[RULE] Unrelated information (e.g., other apps, generic infrastructure, menus) must not be added to this roadmap. Create separate roadmap documents for each application or infrastructure component as needed.
-->

# Roadmap: Multi-Environment Migration for Badminton Court
# badminton_court/Docs/Roadmap_Environments.md

> **Central AI memory & protocol:** [git-temp/Memory.md](https://github.com/Team-Sisante/git-temp/blob/master/Memory.md)  
> **Architectural Decisions:** see `Docs/Decision-Log.md`  
> **Troubleshooting guides:** `Docs/Trouble-shooting/` directory

This document tracks the plan to move from file‑based environment management to GitHub Environments and GoCD automation.  
Only architectural decisions and progress milestones are listed here.  
For detailed problem diagnoses and step‑by‑step fixes, follow the links to the troubleshooting documents.

---

## Phase 1: Infrastructure & Deployment (Current)
- [x] **GCP Setup:** e2-micro VM in `us-central1-a` (Always Free Tier).
- [x] **Static IP:** Reserved and assigned.
- [x] **Docker Installation:** Docker & Docker Compose on the VM.
- [x] **Template & Route Unification:** All pages use `main_base.html`, legal routes at root.
- [x] **Safety Confirmations:** “yes” required for encryption/decryption.
- [x] **Interactive SSH Fix:** `sshToVM.js` supports terminal interactivity.
- [ ] **GoCD Connection:** Finalize SSH handshake between agent and VM.
- [ ] **First Deploy:** Deploy with remote Docker context; ensure SQLite persistence.

## Phase 1.5: Staging Deployment Fixes (2026‑05‑27)
- [x] **Wrong Dockerfile Target (PR #6):** → `Dockerfile-Target-Fix.md`
- [x] **Stale Image Cache (PR #6):** → `Stale-Image-Cache.md`
- [x] **VM Resource Exhaustion (PR #7):** → `VM-Resource-Exhaustion.md`
- [x] **Matplotlib Font Cache Slowdown (PR #8):** → `Matplotlib-Font-Cache.md`

## Phase 2: Professionalization & Monetization
- [ ] **Enhanced Landing Page**
- [ ] **Social Authentication** (Google, Facebook, etc.)
- [ ] **Environment Segregation**
- [x] **Privacy Policy/ToS**
- [ ] **Affiliate Integration**
- [ ] **AdSense Application**

---

## Completed Milestones (high‑level)

| Date       | Milestone / Fix | Reference |
|------------|----------------|-----------|
| 2026‑05‑27 | Wrong Dockerfile target fixed | `Dockerfile-Target-Fix.md` |
| 2026‑05‑27 | Stale image cache resolved | `Stale-Image-Cache.md` |
| 2026‑05‑27 | VM resource exhaustion mitigated | `VM-Resource-Exhaustion.md` |
| 2026‑05‑27 | Matplotlib font cache pre‑built | `Matplotlib-Font-Cache.md` |
| 2026‑05‑31 | Load balancer & path‑based routing | `Load Balancer & Path‑Based Routing.md` |
| 2026‑05‑31 | Nginx placeholder bug fixed | `Nginx-Placeholder-Fix.md` |
| 2026‑06‑19 | Poste.io dev setup stabilised | `Poste.io-Dev-Setup-Wizard.md` |
| 2026‑06‑20 | Poste.io staging fully operational | `Poste.io-Staging-Setup-Wizard.md` |
| 2026‑06‑25 | Social media app menu (16.2) | `Social Media App Configuration Menu.md` |
| 2026‑06‑25 | DB permission repair automation | `Database Permission Repair Automation.md` |
| 2026‑06‑25 | Health check host headers | `Load Balancer Health Check Host Headers.md` |
| 2026‑06‑25 | Deploy script image tag reliability | `Deployment Script Image Tag Reliability.md` |
| 2026‑06‑25 | SMTP check timeout fix | `SMTP Check Timeout Fix.md` |
| 2026‑06‑25 | Cypress env variable resolution | `Cypress Environment Variable Resolution.md` |
| 2026‑06‑25 | /court path routing correction | `court Path Routing Correction.md` |
| 2026‑06‑25 | User profile completion notice | `User Profile Completion Notice.md` |
| 2026‑06‑25 | Troubleshooting documentation created | `Troubleshooting Documentation Creation.md` |

---

## Pending Improvements

| #    | Task | Reference |
|------|------|-----------|
| 81   | Cypress real‑browser demo tests for presentations | `Docs/Trouble-shooting/Cypress-Real-Browser-Demo-Tests.md` |

---

## Key Reference Files
- **Architectural decisions:** `Docs/Decision-Log.md`
- **Troubleshooting guides:** `Docs/Trouble-shooting/` directory
- **Load balancer configuration:** `gocd-server/Scripts/loadbalancer.json` + `setup-load-balancer.js`
- **Menu option index:** `Memory_MenuOptionIndex.md` (git-temp)

---
*Last Updated: 2026-06-25*