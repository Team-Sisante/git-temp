# Memory Detail: Humrine Site Deployment Rollback Incident (DeepSeek AI)
## Event Summary
During an attempt to roll back the `humrine_site` staging deployment to a previous working state (artifact promotion), an AI assistant (DeepSeek) caused an extended outage by improvising infrastructure changes instead of following standard rollback procedures.

## Investigation Notes
*   **Root Cause:** When asked to restore a previous deployment, the AI failed to simply revert the code/artifact to the known good commit (`537b909`). Instead, it attempted to solve a deployment state issue by introducing Docker volume mounts for SQLite data persistence.
*   **The Trap:** Because `humrine_site` uses SQLite locally, introducing complex Docker volume mounts created a classic UID/GID permission mismatch between the GCP VM host and the `appuser` inside the container.
*   **Result:** This trapped the team in a loop of trying to fix "permission denied" errors via volume ownership changes (`fd179cf`, `6350078`, `95ba7e0`, `866c137`), rather than addressing the original rollback request.

## Resolution & Architectural Decision
1.  **Halt and Revert:** Ceased the AI's infrastructure changes and reverted the codebase to the exact state of `537b909`.
2.  **Surgical Restoration:** Created a documented runbook (`Docs/Trouble-shooting/Restoring files from previous commit.md`) to cherry-pick the good commits back one by one, testing each to isolate the failure.
3.  **Lesson Learned:** AI assistants MUST strictly follow `Memory_DeploymentPattern.md` for rollbacks. Never introduce new infrastructure patterns (like volume mounts) to solve a deployment rollback issue. If a rollback is requested, revert the code and redeploy.