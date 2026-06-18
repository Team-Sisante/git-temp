# Memory Detail: CI/CD Deployment & Artifact Pattern

## Artifact Promotion Strategy
The project follows an **Artifact Promotion pattern**:
- **Application Code Changes:** If application code, `settings.py`, or any file bundled into the Docker image changes, the `artifacts` pipeline **must be triggered** to rebuild the image and tag it with a new SHA before deployment.
- **Infrastructure-Only Changes:** If changes are limited to runtime configuration (e.g., `nginx.conf.template`, `docker-compose.yml`, static HTML maintenance pages), these are applied at deployment time via volume mapping or configuration injection. **No artifact rebuild is required.**

## Operational Protocol
- Always distinguish between code changes (requires `artifacts` -> `production` pipeline) and infrastructure-only changes (only requires `production` pipeline).
