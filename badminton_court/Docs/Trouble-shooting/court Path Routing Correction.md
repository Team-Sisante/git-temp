# /court Path Routing Correction
## Source: Docs/Trouble-shooting/court Path Routing Correction.md

**Status:** Completed (June 25, 2026)

### Problem
The badminton_court application was accessible at `humrine.com/court/`, but API requests to `/court/api/...` caused a 301 redirect loop or timeout. The double‑prefixed `/court/court/api/...` accidentally worked because of how the load balancer and the old URLconf interacted.

### Solution
- Removed the explicit `path('court/', include('court_management.urls'))` from the project URLconf (`badminton_court/urls.py`).
- Now uses `path('', include('court_management.urls'))` combined with `FORCE_SCRIPT_NAME='/court'` (set from the `DOMAIN_PREFIX` environment variable).
- `FORCE_SCRIPT_NAME` tells Django to expect the `/court` prefix and strip it internally, so the load balancer's stripped requests (arriving as `/api/...`) are correctly routed.
- The old double‑prefix workaround is no longer needed.

### Related Files
- `badminton_court/badminton_court/urls.py`
- `badminton_court/badminton_court/settings/base.py`