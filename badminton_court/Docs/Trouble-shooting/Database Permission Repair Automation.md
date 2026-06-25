# Database Permission Repair Automation
## Source: Docs/Trouble-shooting/Database Permission Repair Automation.md

**Status:** Completed (June 25, 2026)

### Problem
The SQLite database volume (`db_data`) occasionally had root‑owned permissions, causing "unable to open database file" errors when the container ran as `appuser`. Restarting the container didn't fix it because the volume persisted the wrong ownership.

### Solution
- Rewrote menu options 11.1 (staging) and 14.1 (production) to:
  - Load the complete environment from local `.env.common` and `.env.production` (or `.env.staging`).
  - Stop and remove the broken container.
  - Fix ownership of the host data directory (`chown -R 1000:1000 /opt/humrine_site/data` for humrine, `/opt/badminton_court/data` for badminton).
  - Restart the container with all required environment variables using `docker compose --env-file`.
  - Delete the temporary env file from the VM immediately after.
- The script uses `spawnSync` for SSH and handles error states gracefully.

### Related Files
- `humrine_site/Scripts/options/option_11_1.js`
- `humrine_site/Scripts/options/option_14_1.js`
- `badminton_court/Scripts/options/option_11_1.js` (similar pattern)
- `badminton_court/Scripts/options/option_14_1.js` (similar pattern)