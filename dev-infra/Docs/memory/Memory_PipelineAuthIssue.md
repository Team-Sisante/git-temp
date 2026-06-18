# Memory Detail: GHCR Docker Push Connection Refused

## Issue Summary
Attempts to push Docker images to `ghcr.io` failed in the GoCD artifacts pipeline with connection/unauthorized errors.

## Investigation Notes
- Local `docker login` worked, but the automated `build-and-push.js` script failed inside the agent container.
- **Root Cause:** The `docker login` command in `build-and-push.js` used `echo "${TOKEN}" | ...`, which caused shell interpolation to corrupt tokens containing special characters.

## Resolution
- **Node.js stdin:** Refactored `Scripts/build-and-push.js` to use `execSync` with the `input` option, passing the `GITHUB_TOKEN` directly via `stdin` to `docker login`. This bypasses shell interpolation entirely.

## Commit Status
- The fix is committed and pushed to the `fix/smtp` branch of the `badminton_court` repository.
