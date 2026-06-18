# Memory Detail: Humrine Site Menu & Provisioning Alignment

## Event Summary
I am migrating `humrine_site` infrastructure to align with `badminton_court` patterns (e.g., Dockerized DB, Redis, etc.). Currently, the menu script (`Scripts/menu.js`) has been updated to use the correct env-file loading pattern, but it attempts to start services (`db`, `redis`, `mail-test`) that are not yet defined in `humrine_site/docker-compose.yml`.

## Findings
- `humrine_site` is currently configured for local SQLite, but the menu script is configured to manage a complex Docker-based infrastructure.
- `Scripts/menu.js` (option 1.2) fails because it tries to call `docker compose` on non-existent services.

## Decision
- We will keep the advanced menu functionality intact but "comment out" or disable the specific service calls that are not yet ready for `humrine_site` to prevent failures.
- This allows for easy restoration when the infrastructure is ready.
- Immediate next step: Modify `Scripts/menu.js` to avoid trying to start `db`, `redis`, and `mail-test` in option 1.2 until the services are added to the Compose file.
