# Architecture & Business Decision Log

## ADR-001: Hosting Platform Selection
- **Date:** 2026-05-09
- **Decision:** Use **GCP Compute Engine (e2-micro)** Always Free Tier.
- **Alternatives Considered:** Cloud Run, AWS Free Tier, Oracle Cloud.
- **Reasoning:** 
    1. GCP e2-micro is "Free Forever" (unlike AWS 12-month limit).
    2. Provides a **Static IP** for free (unlike Oracle's complex setup).
    3. Essential for **AdSense** compatibility and professional domain pointing.

## ADR-002: Database Strategy (SQLite)
- **Date:** 2026-05-09
- **Decision:** Stick with **SQLite** on VM Persistent Disk.
- **Alternatives Considered:** Cloud SQL (Postgres/MySQL), MongoDB Atlas.
- **Reasoning:**
    1. Zero cost (Cloud SQL is expensive and outside free tier).
    2. Simplifies GoCD pipelines (no complex external DB connection).
    3. Performance is sufficient for the Badminton system's expected traffic.
    4. Data safety is ensured via VM persistent disk + manual GCS backups.

## ADR-003: Deployment Orchestration
- **Date:** 2026-05-10
- **Decision:** Use **Local GoCD Server** with **Remote Docker Context**.
- **Alternatives Considered:** GitHub Actions, Cloud Build, Moving GoCD to the cloud.
- **Reasoning:**
    1. Leverages existing GoCD infrastructure and expertise.
    2. Keeps the "Brain" (GoCD Server) local to save cloud RAM/CPU.
    3. "Docker Context" allows for the simplest transition from local container to cloud container.

## ADR-004: Monetization Strategy
- **Date:** 2026-05-10
- **Decision:** **Managed Hosting Fee** + **Affiliate Links** + **Google AdSense**.
- **Reasoning:**
    1. Managed fee provides immediate "cash flow" for the developer.
    2. Affiliate links provide passive income without client overhead.
    3. AdSense provides scalability as traffic grows.
    4. Aligns with Philippine business registration paths (DTI/BIR).

## ADR-005: Business Identity (Philippines)
- **Date:** 2026-05-10
- **Decision:** Start as **Individual**, transition to **Sole Proprietor**.
- **Reasoning:**
    1. Minimizes upfront costs while in development.
    2. Allows for legal monetization via personal TIN.
    3. IPOPHL copyright protection can be filed as an individual.

## ADR-008: Persistent Disk Expansion
- **Date:** 2026-05-26
- **Decision:** Increase persistent disk size from current capacity to 100GB to alleviate storage pressure.
- **Reasoning:**
    1. Current disk usage is at critical capacity (99%), threatening OS stability.
    2. Standard Persistent Disk expansion is cost-effective (~$4/month for 100GB).
    3. Provides operational headroom for growth without needing frequent file cleanup.

## ADR-006: Unified Environment-Driven Configuration
- **Date:** 2026-05-29
- **Decision:** Remove all environment-specific Django settings modules (`dev.py`, `prod.py`) and move to a **unified settings architecture**.
- **Reasoning:** 
    1. Removes configuration "split-brain" where settings were scattered between code and environment variables.
    2. Enforces strict environment variable enforcement via `get_env_variable` in `base.py`.
    3. Simplifies Docker Compose files by relying purely on `.env` file injection, eliminating redundant environment declarations.

## ADR-007: Binary Artifact Deployment Strategy
- **Date:** 2026-05-28
- **Decision:** Standardized on a **Binary Deployment Architecture** using PyInstaller-built binaries inside hardened Docker images.
- **Reasoning:**
    1. Ensures immutable, portable artifacts that are identical across staging and production.
    2. Drastically reduces the attack surface of the production VM by removing the need for Python compilers and build-time dependencies.
    3. Increases boot speed and runtime reliability.

## ADR-009: VM Stability & Swap Enforcement
- **Date:** 2026-05-28
- **Decision:** Provisioning of 4GB persistent swap space for all e2-micro deployment VMs.
- **Reasoning:**
    1. Essential to prevent OOM (Out of Memory) kills during high-load container operations (e.g., mail server or Django app startup).
    2. Provides a safety buffer for the 1GB RAM limit.
