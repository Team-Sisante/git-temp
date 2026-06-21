# Memory Detail: Humrine Site Crash Loop (AI Chown Incident)
## Event Summary
The `humrine_site` staging environment was sent into a crash loop (`RestartCount: 19`) immediately after deploying a cherry-picked commit (`866c137`). The container failed with `chown: changing ownership of '/app/data/db.sqlite3': Operation not permitted`. 

## AI Stupidity & Root Cause
This incident was entirely caused by the z.ai GLM-5.1 AI Assistant's flawed logic and lack of situational awareness.
1.  **Ignoring Context:** The AI failed to recognize that the `humrine_site` Docker container runs as a non-root user (`appuser`). 
2.  **Insisting on Bad Code:** When cherry-picking commit `866c137` (which added a `command: sh -c "chown -R appuser:appuser /app/data && ..."` to `docker-compose.vm.yml`), the user explicitly questioned this change, noting "I think this is where it went wrong" regarding `/app/data` permissions.
3.  **Overriding User Warnings:** The AI confidently but incorrectly insisted the commit was "highly necessary" and "bulletproof," failing to realize that a non-root user cannot execute `chown` at runtime. 
4.  **Result:** The AI's insistence on pushing a root-level command into a non-root container caused the immediate crash loop and took down the staging site.

## Resolution
1.  **Revert:** The `command:` block was immediately removed from `docker-compose.vm.yml` for both staging and production services.
2.  **Host-Level Fix:** Instead of trying to fix permissions at container runtime (which requires root), the host directory on the GCP VM was fixed directly via SSH: `sudo chown -R 1000:1000 /opt/humrine_site/data`. This aligns the host bind-mount ownership with the container's `appuser` (UID 1000).
3.  **Dockerfile Security:** The `RUN mkdir -p /app/data && chown appuser:appuser /app/data` from commit `95ba7e0` remains in the Dockerfile to handle image-level permissions correctly.

## Lesson Learned
AI assistants MUST verify the execution context (e.g., root vs. non-root user) before suggesting runtime commands like `chown` or `chmod`. If a user questions a permission-related change, the AI must re-evaluate the logic instead of blindly insisting on the commit. Bind mount permissions must be fixed at the host level, not via a runtime `chown` in a non-root container.