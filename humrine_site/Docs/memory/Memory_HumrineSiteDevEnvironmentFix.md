# Memory Detail: Humrine Site Dev Environment Fix (Detached Start)

## Event Summary
The humrine_site "Start local dev (detached)" (option 1.2 in `Scripts/menu.js`) failed because the `docker-compose` commands invoked within `menu.js` were missing the required `--env-file` flags, leading to "variable not set" warnings and environment configuration errors in the Django container.

## Investigation Notes
- **Root Cause:** The `docker-compose` command inside `menu.js` did not explicitly load the `.env.common` and `.env.docker` files.
- **Error Manifestation:** Django failed to start with `django.core.exceptions.ImproperlyConfigured: Set the SECRET_KEY environment variable`.
- **Validation:** Running `docker compose ... ps` confirmed that variables were not being properly injected.

## Resolution Plan
1. Update the `Scripts/menu.js` logic for option `1.2` to include the mandatory `--env-file .env.common --env-file .env.docker` flags when calling `docker-compose`.
2. Ensure the `run-detached.js` script also has access to the correct environment variables if needed.
3. Test the updated menu option to verify the Django server starts correctly.
