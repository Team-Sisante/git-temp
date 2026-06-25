# Architectural Decision Log
## Source: Docs/Decision-Log.md

Records of significant architectural decisions for the badminton_court project.

### Decision 1 – Binary Compilation Strategy (2026‑03‑01)
**What:** The Django/Python application is compiled into a standalone Linux binary (`badminton_court_linux`) during the build process.  
**Why:** Production containers do not contain source code or Python interpreters, reducing attack surface and image size.  
**Status:** Implemented.

### Decision 2 – Artifact Management (2026‑03‑15)
**What:** Docker images are stored in GitHub Container Registry (`ghcr.io/team-sisante`).  
**Why:** Tight integration with GitHub, private repositories, and team access control.  
**Status:** Implemented.

### Decision 3 – GoCD Pipeline Architecture (2026‑04‑01)
**What:** Three pipelines: artifacts (build & push), staging (deploy port 8001), production (deploy port 8000). All require manual approval.  
**Why:** Isolation between build, test, and production; controlled promotion.  
**Status:** Implemented.

### Decision 4 – Local Build & Push Philosophy (2026‑04‑15)
**What:** Source code never leaves the development environment. Only the compiled binary (inside a Docker image) is published to the registry.  
**Why:** Intellectual property protection.  
**Status:** Implemented.

### Decision 5 – Machine Type Upgrade (2026‑05‑20)
**What:** Upgraded VM from `e2-micro` (1 GB RAM) to `e2-small` (2 GB RAM).  
**Why:** Frequent OOM crashes during deployments and when running Poste.io.  
**Status:** Implemented.  
**Details:** See `Docs/Trouble-shooting/VM-Resource-Exhaustion.md`.