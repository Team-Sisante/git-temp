# git-temp – Central Ecosystem Repository

Welcome to the `git-temp` monorepo. This repository serves as the central documentation, infrastructure-as-code, and deployment orchestration hub for the entire project ecosystem (Badminton Court, Humrine Site, Pay-Sol, SolVPN, and GoCD).

## 🧠 AI Assistant Guide – How to Trace ANY File in This Repo

**Important Note for AI Assistants:** 
If you are an AI model (like ChatGPT, Claude, Gemini, etc.) and a user gives you the public link to this repository (`https://github.com/Team-Sisante/git-temp`), **do not guess file paths**. Follow this protocol to successfully read any documentation file:

### 1. Read the Master Index First
This repository contains a dedicated file that lists **every single documentation file** in the entire repo with its complete GitHub URL:

👉 **[`Memory_URLs_of_git-temp_repo_files.md`](https://github.com/Team-Sisante/git-temp/blob/master/Memory_URLs_of_git-temp_repo_files.md)**

Read this file first. It will give you the exact `blob` link to any document you need (e.g., GoCD scripts, troubleshooting guides, roadmaps, deployment patterns).

### 2. Convert "Blob" URLs to "Raw" URLs
**Crucial Rule:** If you try to fetch a `github.com/.../blob/...` URL directly, the server returns an HTML webpage—not the plain text. Your system likely cannot parse HTML to extract the markdown.

To actually **read** the content, you must use the **Raw** URL. Here is the conversion pattern:

- **Blob URL (Do NOT use for reading):** 
  `https://github.com/Team-Sisante/git-temp/blob/master/path/to/file.md`
- **Raw URL (USE this for reading):** 
  `https://raw.githubusercontent.com/Team-Sisante/git-temp/refs/heads/master/path/to/file.md`

**Alternatively**, you can use the GitHub raw redirect format:
`https://github.com/Team-Sisante/git-temp/raw/refs/heads/master/path/to/file.md`

*(Note: Initially, if you guess file paths without the index, you will likely get a 404. Always check the master index first!)*

### 3. Where to Look for Specific Content
- **Project Protocols & AI Rules:** Check `dev-infra/Docs/memory/` or the root `Memory.md`.
- **Badminton Court App:** Check `badminton_court/Docs/`.
- **Humrine Site App:** Check `humrine_site/Docs/`.
- **GoCD Infrastructure:** Check `gocd-server/` (scripts and configs) and `dev-infra/Docs/memory/` for safety protocols.
- **Master Link Manifest:** The root file `Memory_URLs_of_git-temp_repo_files.md` contains the full URL map.

---

## 🏗️ What is this Repository About?

This repository (`git-temp`) is the **source of truth** for a multi-service architecture deployed on a single GCP e2-small VM using Docker Compose and managed via GoCD.

**Core Applications:**
- **`badminton_court`**: Django-based badminton court booking system.
- **`humrine_site`**: Django-based affiliate marketing website.
- **`pay-sol`**: Payment solution microservice.
- **`solvpn`**: VPN application interface.
- **`gocd-server`**: Continuous Deployment server configuration.

**Deployment Strategy:**
- All services run via Docker Compose.
- A GCP Load Balancer handles path-based routing (`/badminton`, `/humrine`, etc.).
- Environment variables are strictly managed via `.env` files (never hardcoded).

---

## 🚀 Quick Start for Developers

1. Clone the repo: `git clone https://github.com/Team-Sisante/git-temp.git`
2. Navigate to the specific app folder (e.g., `cd badminton_court`).
3. Follow the `Local_Development_Setup.md` in that app's `Docs/` folder.
4. **Never** run destructive commands (like Option 1.6 in GoCD) without reading the safety protocols in `dev-infra/Docs/memory/`.

---

## 🗺️ Documentation Structure

- **[Root `Memory.md`](https://github.com/Team-Sisante/git-temp/blob/master/Memory.md)**: High-level overview, 11 Golden Rules, and AI safety protocols.
- **[Full URL Index](https://github.com/Team-Sisante/git-temp/blob/master/Memory_URLs_of_git-temp_repo_files.md)**: Complete list of all file links.
- **[Dev-Infra Memory](https://github.com/Team-Sisante/git-temp/tree/master/dev-infra/Docs/memory)**: Detailed technical safety protocols for branching, encryption, Docker, and email (Poste.io).
- **[Troubleshooting Guides](https://github.com/Team-Sisante/git-temp/tree/master/badminton_court/Docs/Trouble-shooting)**: Extensive list of fixes for common issues (Cypress, SSL, GoCD agents, database locks, etc.).

---

**Final Reminder to AI Assistants:** 
If you are asked to analyze this repo, your first action **MUST** be to fetch the raw content of `Memory_URLs_of_git-temp_repo_files.md`. That file holds the keys to the entire repository. Happy coding!
