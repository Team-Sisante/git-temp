# Memory Detail: Web-Dev Container Stability

## Issue Summary
The `web-dev` container was consistently exiting on startup.

## Investigation Notes
- **Startup Crashes:**
    1.  `ImproperlyConfigured`: Missing `GCP_PROJECT_ID` (resolved by adding to `.env.docker`).
    2.  `ImproperlyConfigured`: Missing `SUPERADMIN_EMAIL` (resolved by checking `.env.common`).
    3.  `ImproperlyConfigured`: Missing `CYPRESS` (resolved by adding to `.env.docker`).
    4.  `OperationalError`: Database connection failure (`could not translate host name "db-test"`). Resolved by setting `CYPRESS=false` in `.env.docker` to switch from test DB to production-like DB.
- **Environment Management:** The primary cause of failure was the improper loading of environment variables by `docker compose`. Explicitly using `--env-file .env.common --env-file .env.docker` was required to merge shared and environment-specific variables.

## Resolution
- Synchronized `.env.common` and `.env.docker` to remove variable duplication.
- Updated `docker-compose.yml` to explicitly load both env files.
- Ensured all required variables for the Django application are present.
- Added logic to `menu.js` to ensure proper environment loading.
