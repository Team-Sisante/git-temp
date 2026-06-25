# VM Resource Exhaustion & Machine Type Upgrade
## Source: Docs/Trouble-shooting/VM-Resource-Exhaustion.md

**Status:** Resolved (May 2026)

### Problem
The `e2-micro` instance (1 GB RAM) suffered frequent OOM (Out Of Memory) crashes during deployments and while running the Poste.io mail server. Docker commands hung, SSH connections dropped, and the system became unresponsive under load.

### Root Cause
Insufficient RAM for the combined workload (PostgreSQL, Redis, Poste.io, web app). Additional stress came from high I/O wait due to swapping on the small instance.

### Solution
- **Upgraded VM machine type** from `e2-micro` to `e2-small` (2 GB RAM).  
  This was done manually via the GCP Console.
- Added `mem_limit` to all Docker Compose services to prevent any single container from consuming all available memory.
- Created a 4 GB swap file as additional safety (see `VM-Stability.md`).

### Result
No further OOM events. Deployments and mail server operation are stable.

### Related
- `VM-Stability.md` (swap and disk resizing)
- `docker-compose.vm.yml` (memory limits)