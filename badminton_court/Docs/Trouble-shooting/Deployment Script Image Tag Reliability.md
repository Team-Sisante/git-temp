# Deployment Script Image Tag Reliability
## Source: Docs/Trouble-shooting/Deployment Script Image Tag Reliability.md

**Status:** Completed (June 25, 2026)

### Problem
The production container sometimes ran an old image even after a new artifacts build succeeded. The deploy script used the `latest` tag, which wasn't updated automatically by the artifacts pipeline, or it reused the `IMAGE_TAG` environment variable that wasn't set correctly in manual menu deployments.

### Solution
- Added automatic SHA tag discovery in `deploy.js`: if `IMAGE_TAG` is missing or set to `latest`, the script queries the GitHub Container Registry for the newest `sha-*` tag of the web image.
- Added a pre‑deploy step that explicitly stops and removes the old web container before `docker compose up`. This guarantees a fresh container starts with the pulled image.
- These changes apply to both `badminton_court` and `humrine_site` deployments (the deploy script is shared).

### Related Files
- `gocd-server/Scripts/deploy.js`