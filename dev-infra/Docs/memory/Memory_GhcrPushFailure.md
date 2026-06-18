# Memory Detail: GHCR Docker Push Connection Refused

## Issue Summary
Attempts to push Docker images to `ghcr.io` have failed in two contexts:
1.  **Local Development:** `docker push` failed on the local host.
2.  **Artifacts Pipeline:** The GoCD artifacts pipeline continues to fail with `connection refused` on `ghcr.io` despite successful local authentication.

## Investigation Notes (Local)
- Network connectivity (`curl -v https://ghcr.io`) was verified successful.
- The local failure was resolved by manually running `docker login ghcr.io` using the token from `.env.docker`.

## Investigation Notes (Pipeline)
- The pipeline failure (`connection refused` / `Unsupported Media Type` / `415` errors) persists.
- **Root Cause:** The GoCD Agent build environment is isolated from the local session and is likely not logged into `ghcr.io`.
- **Diagnosis:** The pipeline configuration does not currently include a `docker login` step for the agent, leading to authentication failure during the `docker push` stage.

## Resolution (Pipeline)
- The pipeline configuration needs to be updated to inject credentials and authenticate the agent with `ghcr.io` before attempting image pushes.

## Future Prevention
- Always verify Docker authentication (`docker login`) on the build agent itself.
- Ensure the `GITHUB_TOKEN` is available as a secure variable within the GoCD pipeline configuration for agent authentication.
