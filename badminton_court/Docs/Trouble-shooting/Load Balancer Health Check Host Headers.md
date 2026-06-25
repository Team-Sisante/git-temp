# Load Balancer Health Check Host Headers
## Source: Docs/Trouble-shooting/Load Balancer Health Check Host Headers.md

**Status:** Completed (June 25, 2026)

### Problem
After a fresh VM creation or load balancer rebuild, health checks sent requests without a `Host` header. Django rejected them with `DisallowedHost` (because the internal IP `10.148.0.x` wasn't in `ALLOWED_HOSTS`), causing the backend to appear UNHEALTHY and users to see 502 errors.

### Solution
- Updated `gocd-server/Scripts/setup-load-balancer.js` to automatically include the `--host` flag when creating or updating health checks.
- The script now reads each backend's `host` field from `loadbalancer.json` and applies it to the corresponding health check (e.g., `--host=staging.humrine.com` for the staging check).
- This ensures health check probes send a valid `Host` header that Django accepts.

### Related Files
- `gocd-server/Scripts/setup-load-balancer.js`
- `gocd-server/Scripts/loadbalancer.json`