# Memory Detail: Artifacts Pipeline GHCR Connection Refused

## Current Status
- **Status:** ACTIVE TASK
- **Priority:** High
- **Issue:** `connection refused` on `ghcr.io:443` during `docker push` in the `badminton_court` artifacts pipeline.
- **Error Trace:** `failed to do request: Head "https://ghcr.io/v2/xmione/badminton_court-web/blobs/sha256:...": dial tcp 20.27.177.117:443: connect: connection refused`

## Investigation Plan
1.  **Verify Branch & Code:** Confirm the pipeline is running the code containing the `docker login` fix (stdin refactor in `Scripts/build-and-push.js`).
2.  **Network Connectivity Check:** Execute `curl -v https://ghcr.io` from within the GoCD agent environment to rule out persistent network blocks.
3.  **Credential Validation:** Ensure the `GITHUB_TOKEN` being passed to the agent is valid and has `packages:write` permissions.
4.  **MTU/Networking issues:** Investigate if the agent's Docker-in-Docker network has MTU mismatches that could cause larger requests (like push headers) to fail while small ones (like pings) succeed.
5.  **Intermittent vs. Persistent:** Determine if the "connection refused" is a rate limit or a hard block.

## Investigation Notes
- **Code Branch Mismatch:** Discovered that the `badminton_court-artifacts` pipeline in GoCD is configured to use the `master` branch.
- **Missing Fix:** The `master` branch was missing the `docker login` stdin fix (it was still using the bugged `echo "${TOKEN}" | ...` method).
- **Merge Action:** Merged `fix/smtp` (which contains the fix) into `master`.

## Step-by-Step Resolution Strategy
1.  [x] Inspect `badminton_court` repository to check if the `fix/smtp` changes were merged to the branch used by the pipeline.
2.  [x] Merge `fix/smtp` into `master` to ensure the pipeline uses the correct `docker login` logic.
3.  [ ] Push merged `master` to remote `origin` (Requires user confirmation/credentials).
4.  [ ] Verify the `GITHUB_TOKEN` secret in GoCD.
5.  [ ] Re-run the `badminton_court-artifacts` pipeline.
6.  [ ] If network is blocked, check firewall rules for the GCP VM hosting the GoCD Agent.
