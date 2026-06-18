# Memory Detail: Poste.io Password Consolidation & Pipeline Failure

## Issue Summary
- **Password Consolidation:** Successfully migrated `humrine_site` to use `POSTE_ADMIN_PASSWORD` as the single source of truth for Poste.io admin passwords, aligning it with the `badminton_court` pattern.
- **Pipeline Failure:** The `humrine_site` deployment pipeline is failing due to an incorrectly resolved `IMAGE_TAG` (resolving to `sha-` instead of a valid commit or `latest`), causing the web containers to fail to pull and start.
- **Service Downtime:** The site is down due to the deployment failure. The "Server Error" seen by the user is the default Nginx 502/503/504 error page.

## Action Items
1. Fix the GoCD pipeline configuration to correctly pass a valid `IMAGE_TAG` to the `docker compose` deployment command.
2. Ensure the maintenance page is successfully served as a fallback while the deployment is broken.
