# Load Balancer & Path‑Based Routing Implementation
## Source: Docs/Trouble-shooting/Load Balancer & Path‑Based Routing.md

**Status:** Completed (May 31, 2026)

### Problem
Multiple apps (Humrine Site and Badminton Court) needed to coexist under a single domain (`humrine.com`) using both sub‑domains and path‑based routing. The original load‑balancer setup only supported subdomain backends, causing 502 errors on the root domain and “Not Found” on sub‑site paths.

### Root Cause
The load balancer’s URL map lacked host rules for path‑based routing, and health checks did not include the necessary `Host` header.

### Solution
- Created a self‑healing `setup-load-balancer.js` script that idempotently inspects and corrects all load balancer components.
- Added a `certDomains` array to `loadbalancer.json` for multi‑domain Google‑managed certificates with versioning.
- Implemented path‑based routing via `pathPrefix` support, enabling `/court‑staging` and `/court` under the same host.
- Health checks now automatically set the correct `--host` header and request path.
- Backend services are forced to HTTP and correct named port.
- Firewall rules are created/updated for both health‑check probes (restricted sources) and traffic (all sources).
- Nginx templates were updated to strip the path prefix and include 301 redirects for bare paths.
- Port conflicts between Humrine and Badminton containers were resolved with environment variables.

### Result
All sites (`humrine.com`, `staging.humrine.com`, `app.humrine.com`) and path‑based apps (`/court‑staging`, `/court`) are operational. The load balancer is self‑healing via menu option 6.30.

### Related Files
- `gocd-server/Scripts/setup-load-balancer.js`
- `gocd-server/Scripts/loadbalancer.json`
- `badminton_court/docker-compose.vm.yml`