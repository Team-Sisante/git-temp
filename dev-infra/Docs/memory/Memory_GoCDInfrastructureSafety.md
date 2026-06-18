# Memory Detail: GoCD Management & Infrastructure Safeguards

## Critical Infrastructure Warnings
- **Destructive Menu Operations:** 
  - In `gocd-server/Scripts/menu.js`, **Option 1.6** calls `Scripts/go.js`, which executes a "Nuclear Cleanup" (`nuclearCleanup()` function).
  - This function runs `docker compose down -v` and `docker volume rm -f`, which **permanently deletes all pipeline history, configurations, and artifacts**.
  - **NEVER advise running Option 1.6** unless specifically requested for a factory reset.

## Data Persistence Mechanism
- **GoCD Server:** Uses named volumes (`gocd_data`, `gocd_home`) defined in `gocd-server/docker-compose.yml`.
  - These volumes are NOT bind-mounted to the host project folder.
  - They persist even if containers are destroyed/recreated, provided the volumes themselves are not manually removed.
- **Safe Restart Pattern:** Use `docker-compose restart gocd-server` or **Option 1.1** (non-destructive build/up) to apply configuration changes without wiping data.

## Deployment Strategy
- **Artifact Promotion:** The project uses an Artifact Promotion pattern. Build pipelines tag images with `:latest` AND `:sha-<short-sha>`.
- **Image Injection:** Deployment pipelines pass `${IMAGE_TAG}` to `deploy.js`, which uses it to pull specific tagged images, enabling reliable restores by triggering pipelines with historical material revisions (commit SHAs).
